import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/bottle_log.dart';
import '../models/internet_credit.dart';
import '../models/machine.dart';
import '../models/user.dart';
import '../models/wifi_session.dart';
import '../utils/api_exception.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

/// API service for all HTTP communications with Laravel backend
class ApiService {
  final StorageService _storageService;
  final String baseUrl;

  ApiService({required StorageService storageService, String? baseUrl})
    : _storageService = storageService,
      baseUrl = baseUrl ?? AppConstants.baseUrl;

  /// Get authorization headers
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _storageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Handle error responses
    Map<String, dynamic>? errorBody;
    try {
      errorBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      // Response body is not JSON
    }

    switch (response.statusCode) {
      case 401:
        throw ApiException.unauthorized();
      case 422:
        final message = errorBody?['message'] as String? ?? 'Validation failed';
        throw ApiException.validationError(message);
      case 500:
        throw ApiException.serverError();
      default:
        final message = errorBody?['message'] as String? ?? 'An error occurred';
        throw ApiException(
          message: message,
          statusCode: response.statusCode,
          data: errorBody,
        );
    }
  }

  /// Execute HTTP request with error handling
  Future<Map<String, dynamic>> _executeRequest(
    Future<http.Response> Function() requestFunction,
  ) async {
    try {
      final response = await requestFunction().timeout(
        AppConstants.connectionTimeout,
        onTimeout: () => throw ApiException.timeout(),
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException.networkError();
    } on TimeoutException {
      throw ApiException.timeout();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Unexpected error: ${e.toString()}',
        statusCode: null,
      );
    }
  }

  // ==================== Authentication Endpoints ====================

  /// Register a new user
  Future<ApiResponse<User>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });

    final responseData = await _executeRequest(
      () async => http.post(
        Uri.parse('$baseUrl${AppConstants.registerEndpoint}'),
        headers: await _getHeaders(includeAuth: false),
        body: body,
      ),
    );

    // Extract data from Laravel response format
    final data = responseData['data'] as Map<String, dynamic>;

    // Save token and user
    if (data['token'] != null) {
      await _storageService.saveToken(data['token'] as String);
    }

    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _storageService.saveUser(user);

    return ApiResponse<User>(
      success: true,
      message: responseData['message'] as String?,
      data: user,
    );
  }

  /// Login user
  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    final body = jsonEncode({'email': email, 'password': password});

    final responseData = await _executeRequest(
      () async => http.post(
        Uri.parse('$baseUrl${AppConstants.loginEndpoint}'),
        headers: await _getHeaders(includeAuth: false),
        body: body,
      ),
    );

    // Extract data from Laravel response format
    final data = responseData['data'] as Map<String, dynamic>;

    // Save token and user
    if (data['token'] != null) {
      await _storageService.saveToken(data['token'] as String);
    }

    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _storageService.saveUser(user);

    return ApiResponse<User>(
      success: true,
      message: responseData['message'] as String?,
      data: user,
    );
  }

  /// Logout user
  Future<ApiResponse<void>> logout() async {
    final responseData = await _executeRequest(
      () async => http.post(
        Uri.parse('$baseUrl${AppConstants.logoutEndpoint}'),
        headers: await _getHeaders(),
      ),
    );

    // Clear local storage
    await _storageService.clearAll();

    return ApiResponse<void>(
      success: true,
      message: responseData['message'] as String?,
    );
  }

  // ==================== Bottle Endpoints ====================

  /// Report a bottle
  Future<ApiResponse<BottleLog>> reportBottle({
    required int machineId,
    String? imageBase64,
  }) async {
    final body = jsonEncode({
      'machine_id': machineId,
      if (imageBase64 != null) 'image': imageBase64,
    });

    final responseData = await _executeRequest(
      () async => http.post(
        Uri.parse('$baseUrl${AppConstants.reportBottleEndpoint}'),
        headers: await _getHeaders(),
        body: body,
      ),
    );

    final data = responseData['data'] as Map<String, dynamic>;
    final bottleLog = BottleLog.fromJson(
      data['bottle_log'] as Map<String, dynamic>,
    );

    return ApiResponse<BottleLog>(
      success: true,
      message: responseData['message'] as String?,
      data: bottleLog,
    );
  }

  /// Get bottle history
  Future<ApiResponse<List<BottleLog>>> getBottleHistory({
    int page = 1,
    int perPage = 20,
  }) async {
    final uri = Uri.parse(
      '$baseUrl${AppConstants.bottleHistoryEndpoint}?page=$page&per_page=$perPage',
    );

    final responseData = await _executeRequest(
      () async => http.get(uri, headers: await _getHeaders()),
    );

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
  }

  /// Get bottle statistics
  Future<ApiResponse<BottleStatistics>> getBottleStatistics() async {
    final responseData = await _executeRequest(
      () async => http.get(
        Uri.parse('$baseUrl${AppConstants.bottleStatisticsEndpoint}'),
        headers: await _getHeaders(),
      ),
    );

    final data = responseData['data'] as Map<String, dynamic>;
    final statistics = BottleStatistics.fromJson(
      data['statistics'] as Map<String, dynamic>,
    );

    return ApiResponse<BottleStatistics>(success: true, data: statistics);
  }

  // ==================== Internet Endpoints ====================

  /// Request internet access
  Future<ApiResponse<WifiSession>> requestInternet({
    required int machineId,
    required int minutes,
  }) async {
    final body = jsonEncode({'machine_id': machineId, 'minutes': minutes});

    final responseData = await _executeRequest(
      () async => http.post(
        Uri.parse('$baseUrl${AppConstants.requestInternetEndpoint}'),
        headers: await _getHeaders(),
        body: body,
      ),
    );

    final data = responseData['data'] as Map<String, dynamic>;
    final session = WifiSession.fromJson(
      data['session'] as Map<String, dynamic>,
    );

    return ApiResponse<WifiSession>(
      success: true,
      message: responseData['message'] as String?,
      data: session,
    );
  }

  /// View user credits
  Future<ApiResponse<InternetCredit>> viewCredits() async {
    final responseData = await _executeRequest(
      () async => http.get(
        Uri.parse('$baseUrl${AppConstants.viewCreditsEndpoint}'),
        headers: await _getHeaders(),
      ),
    );

    final data = responseData['data'] as Map<String, dynamic>;
    final credits = InternetCredit.fromJson(
      data['credits'] as Map<String, dynamic>,
    );

    return ApiResponse<InternetCredit>(success: true, data: credits);
  }

  /// Get active session
  Future<ApiResponse<WifiSession?>> getActiveSession() async {
    final responseData = await _executeRequest(
      () async => http.get(
        Uri.parse('$baseUrl${AppConstants.activeSessionEndpoint}'),
        headers: await _getHeaders(),
      ),
    );

    final data = responseData['data'] as Map<String, dynamic>;
    final sessionData = data['session'];
    final session = sessionData != null
        ? WifiSession.fromJson(sessionData as Map<String, dynamic>)
        : null;

    return ApiResponse<WifiSession?>(success: true, data: session);
  }

  // ==================== Machine Endpoints ====================

  /// Get machine status
  Future<ApiResponse<List<Machine>>> getMachineStatus() async {
    final responseData = await _executeRequest(
      () async => http.get(
        Uri.parse('$baseUrl${AppConstants.machineStatusEndpoint}'),
        headers: await _getHeaders(includeAuth: false),
      ),
    );

    final data = responseData['data'] as Map<String, dynamic>;
    final machines = (data['machines'] as List)
        .map((json) => Machine.fromJson(json as Map<String, dynamic>))
        .toList();

    return ApiResponse<List<Machine>>(success: true, data: machines);
  }

  /// Send machine heartbeat
  Future<ApiResponse<Machine>> sendMachineHeartbeat({
    required int machineId,
  }) async {
    final body = jsonEncode({
      'machine_id': machineId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    final responseData = await _executeRequest(
      () async => http.post(
        Uri.parse('$baseUrl${AppConstants.machineHeartbeatEndpoint}'),
        headers: await _getHeaders(),
        body: body,
      ),
    );

    final data = responseData['data'] as Map<String, dynamic>;
    final machine = Machine.fromJson(data['machine'] as Map<String, dynamic>);

    return ApiResponse<Machine>(success: true, data: machine);
  }

  // ==================== User Endpoints ====================

  /// Get user profile
  Future<ApiResponse<User>> getUserProfile() async {
    final responseData = await _executeRequest(
      () async => http.get(
        Uri.parse('$baseUrl${AppConstants.userProfileEndpoint}'),
        headers: await _getHeaders(),
      ),
    );

    final data = responseData['data'] as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _storageService.saveUser(user);

    return ApiResponse<User>(success: true, data: user);
  }
}
