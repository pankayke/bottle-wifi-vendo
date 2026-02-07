import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/api_response.dart';
import '../models/bottle_log.dart';
import '../models/internet_credit.dart';
import '../models/machine.dart';
import '../models/user.dart';
import '../models/wifi_session.dart';
import '../utils/api_exception.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

/// Enhanced API service with Dio, interceptors, and token refresh
class EnhancedApiService {
  final StorageService _storageService;
  late final Dio _dio;
  final Connectivity _connectivity = Connectivity();

  EnhancedApiService({required StorageService storageService, String? baseUrl})
    : _storageService = storageService {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  /// Setup Dio interceptors for token refresh and error handling
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Check network connectivity
          final connectivityResult = await _connectivity.checkConnectivity();
          if (connectivityResult.contains(ConnectivityResult.none)) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: ApiException.networkError(),
                type: DioExceptionType.connectionError,
              ),
            );
          }

          // Add auth token
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Check if token needs refresh
          final isExpired = await _storageService.isTokenExpired();
          if (isExpired && token != null) {
            try {
              await _refreshToken();
              final newToken = await _storageService.getToken();
              if (newToken != null) {
                options.headers['Authorization'] = 'Bearer $newToken';
              }
            } catch (e) {
              // Token refresh failed, continue with existing token
              // Let the request fail and handle in error interceptor
            }
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Try to refresh token
            try {
              await _refreshToken();
              final newToken = await _storageService.getToken();
              if (newToken != null) {
                // Retry the request with new token
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            } catch (e) {
              // Token refresh failed, clear storage and reject
              await _storageService.clearAll();
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  error: ApiException.unauthorized(),
                  type: DioExceptionType.badResponse,
                ),
              );
            }
          }

          // Handle other errors
          return handler.next(_handleDioError(error));
        },
      ),
    );

    // Logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => print('[API] $obj'),
      ),
    );
  }

  /// Refresh authentication token
  Future<void> _refreshToken() async {
    try {
      final response = await _dio.post(
        AppConstants.refreshTokenEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await _storageService.getToken()}',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final newToken = data['data']['token'] as String;

      // Calculate expiry if provided
      DateTime? expiresAt;
      if (data['data']['expires_in'] != null) {
        final expiresIn = data['data']['expires_in'] as int;
        expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      }

      await _storageService.saveToken(newToken, expiresAt: expiresAt);
    } catch (e) {
      throw ApiException(message: 'Token refresh failed', statusCode: 401);
    }
  }

  /// Handle Dio errors and convert to ApiException
  DioException _handleDioError(DioException error) {
    ApiException apiException;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        apiException = ApiException.timeout();
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        String message = 'An error occurred';
        if (data is Map<String, dynamic> && data['message'] != null) {
          message = data['message'] as String;
        }

        switch (statusCode) {
          case 401:
            apiException = ApiException.unauthorized();
            break;
          case 422:
            apiException = ApiException.validationError(message);
            break;
          case 500:
            apiException = ApiException.serverError();
            break;
          default:
            apiException = ApiException(
              message: message,
              statusCode: statusCode,
              data: data,
            );
        }
        break;
      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          apiException = ApiException.networkError();
        } else {
          apiException = ApiException(
            message: 'Connection error: ${error.message}',
            statusCode: null,
          );
        }
        break;
      default:
        apiException = ApiException(
          message: error.message ?? 'Unexpected error occurred',
          statusCode: null,
        );
    }

    return DioException(
      requestOptions: error.requestOptions,
      error: apiException,
      type: error.type,
      response: error.response,
    );
  }

  /// Execute request with error handling
  Future<T> _executeRequest<T>(
    Future<Response> Function() requestFunction,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final response = await requestFunction();
      final data = response.data as Map<String, dynamic>;
      return parser(data);
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(
        message: e.message ?? 'Request failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ==================== Authentication Endpoints ====================

  Future<ApiResponse<User>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    return _executeRequest(
      () => _dio.post(
        AppConstants.registerEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      ),
      (responseData) {
        final data = responseData['data'] as Map<String, dynamic>;

        // Save token with expiry
        if (data['token'] != null) {
          DateTime? expiresAt;
          if (data['expires_in'] != null) {
            final expiresIn = data['expires_in'] as int;
            expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
          }
          _storageService.saveToken(
            data['token'] as String,
            expiresAt: expiresAt,
          );
        }

        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        _storageService.saveUser(user);

        return ApiResponse<User>(
          success: true,
          message: responseData['message'] as String?,
          data: user,
        );
      },
    );
  }

  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    return _executeRequest(
      () => _dio.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      ),
      (responseData) {
        final data = responseData['data'] as Map<String, dynamic>;

        // Save token with expiry
        if (data['token'] != null) {
          DateTime? expiresAt;
          if (data['expires_in'] != null) {
            final expiresIn = data['expires_in'] as int;
            expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
          }
          _storageService.saveToken(
            data['token'] as String,
            expiresAt: expiresAt,
          );
        }

        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        _storageService.saveUser(user);

        return ApiResponse<User>(
          success: true,
          message: responseData['message'] as String?,
          data: user,
        );
      },
    );
  }

  Future<ApiResponse<void>> logout() async {
    try {
      await _dio.post(AppConstants.logoutEndpoint);
    } catch (e) {
      // Continue with logout even if API call fails
    }
    await _storageService.clearAll();
    return ApiResponse<void>(success: true, message: 'Logged out successfully');
  }

  // ==================== Bottle Endpoints ====================

  Future<ApiResponse<BottleLog>> reportBottle({
    required int machineId,
    String? imageBase64,
  }) async {
    return _executeRequest(
      () => _dio.post(
        AppConstants.reportBottleEndpoint,
        data: {
          'machine_id': machineId,
          if (imageBase64 != null) 'image': imageBase64,
        },
      ),
      (responseData) {
        final data = responseData['data'] as Map<String, dynamic>;
        final bottleLog = BottleLog.fromJson(
          data['bottle_log'] as Map<String, dynamic>,
        );
        return ApiResponse<BottleLog>(
          success: true,
          message: responseData['message'] as String?,
          data: bottleLog,
        );
      },
    );
  }

  Future<ApiResponse<List<BottleLog>>> getBottleHistory({
    int page = 1,
    int perPage = 20,
  }) async {
    return _executeRequest(
      () => _dio.get(
        AppConstants.bottleHistoryEndpoint,
        queryParameters: {'page': page, 'per_page': perPage},
      ),
      (responseData) {
        final data = responseData['data'] as Map<String, dynamic>;
        final bottleLogs = (data['bottles'] as List)
            .map((json) => BottleLog.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<BottleLog>>(
          success: true,
          message: responseData['message'] as String?,
          data: bottleLogs,
          meta: data,
        );
      },
    );
  }

  Future<ApiResponse<BottleStatistics>> getBottleStatistics() async {
    return _executeRequest(
      () => _dio.get(AppConstants.bottleStatisticsEndpoint),
      (responseData) {
        final data = responseData['data'] as Map<String, dynamic>;
        final statistics = BottleStatistics.fromJson(
          data['statistics'] as Map<String, dynamic>,
        );
        return ApiResponse<BottleStatistics>(success: true, data: statistics);
      },
    );
  }

  // ==================== Internet Endpoints ====================

  Future<ApiResponse<WifiSession>> requestInternet({
    required int machineId,
    required int minutes,
  }) async {
    return _executeRequest(
      () => _dio.post(
        AppConstants.requestInternetEndpoint,
        data: {'machine_id': machineId, 'minutes': minutes},
      ),
      (responseData) {
        final data = responseData['data'] as Map<String, dynamic>;
        final session = WifiSession.fromJson(
          data['session'] as Map<String, dynamic>,
        );
        return ApiResponse<WifiSession>(
          success: true,
          message: responseData['message'] as String?,
          data: session,
        );
      },
    );
  }

  Future<ApiResponse<InternetCredit>> viewCredits() async {
    return _executeRequest(() => _dio.get(AppConstants.viewCreditsEndpoint), (
      responseData,
    ) {
      final data = responseData['data'] as Map<String, dynamic>;
      final credits = InternetCredit.fromJson(
        data['credits'] as Map<String, dynamic>,
      );
      return ApiResponse<InternetCredit>(success: true, data: credits);
    });
  }

  Future<ApiResponse<WifiSession?>> getActiveSession() async {
    return _executeRequest(() => _dio.get(AppConstants.activeSessionEndpoint), (
      responseData,
    ) {
      final data = responseData['data'] as Map<String, dynamic>;
      final sessionData = data['session'];
      final session = sessionData != null
          ? WifiSession.fromJson(sessionData as Map<String, dynamic>)
          : null;
      return ApiResponse<WifiSession?>(success: true, data: session);
    });
  }

  // ==================== Machine Endpoints ====================

  Future<ApiResponse<List<Machine>>> getMachineStatus() async {
    return _executeRequest(() => _dio.get(AppConstants.machineStatusEndpoint), (
      responseData,
    ) {
      final data = responseData['data'] as Map<String, dynamic>;
      final machines = (data['machines'] as List)
          .map((json) => Machine.fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiResponse<List<Machine>>(success: true, data: machines);
    });
  }

  Future<ApiResponse<Machine>> sendMachineHeartbeat({
    required int machineId,
  }) async {
    return _executeRequest(
      () => _dio.post(
        AppConstants.machineHeartbeatEndpoint,
        data: {
          'machine_id': machineId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
      (responseData) {
        final data = responseData['data'] as Map<String, dynamic>;
        final machine = Machine.fromJson(
          data['machine'] as Map<String, dynamic>,
        );
        return ApiResponse<Machine>(success: true, data: machine);
      },
    );
  }

  // ==================== User Endpoints ====================

  Future<ApiResponse<User>> getUserProfile() async {
    return _executeRequest(() => _dio.get(AppConstants.userProfileEndpoint), (
      responseData,
    ) {
      final data = responseData['data'] as Map<String, dynamic>;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      _storageService.saveUser(user);
      return ApiResponse<User>(success: true, data: user);
    });
  }
}
