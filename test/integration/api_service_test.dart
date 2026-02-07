/// Integration Tests for Enhanced API Service
///
/// Tests the EnhancedApiService with mock HTTP responses

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bottle_wifi/services/enhanced_api_service.dart';
import 'package:bottle_wifi/services/storage_service.dart';
import 'package:bottle_wifi/utils/api_exception.dart';
import 'package:bottle_wifi/utils/api_response.dart';
import 'package:bottle_wifi/utils/constants.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_classes.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late MockStorageService mockStorageService;
  late EnhancedApiService apiService;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
    dioAdapter = DioAdapter(dio: dio);
    mockStorageService = MockStorageService();

    // Setup default mock behaviors
    when(
      () => mockStorageService.getToken(),
    ).thenAnswer((_) async => TestData.testToken);
    when(
      () => mockStorageService.isTokenExpired(),
    ).thenAnswer((_) async => false);

    apiService = EnhancedApiService(
      storageService: mockStorageService,
      dio: dio,
    );
  });

  group('Authentication API Tests', () {
    test('login returns user data and token on success', () async {
      final mockResponse = TestData.mockAuthResponse(token: TestData.testToken);

      dioAdapter.onPost(
        '/login',
        (server) => server.reply(200, mockResponse),
        data: {'email': TestData.testEmail, 'password': TestData.testPassword},
      );

      when(
        () => mockStorageService.saveToken(
          TestData.testToken,
          expiresAt: any(named: 'expiresAt'),
        ),
      ).thenAnswer((_) async {});

      final result = await apiService.login(
        email: TestData.testEmail,
        password: TestData.testPassword,
      );

      expect(result.success, true);
      expect(result.data, isNotNull);
      expect(result.data!['token'], TestData.testToken);

      verify(
        () => mockStorageService.saveToken(
          TestData.testToken,
          expiresAt: any(named: 'expiresAt'),
        ),
      ).called(1);
    });

    test('login throws ApiException on invalid credentials', () async {
      dioAdapter.onPost(
        '/login',
        (server) => server.reply(
          401,
          TestData.mockErrorResponse(
            message: 'Invalid credentials',
            statusCode: 401,
          ),
        ),
      );

      expect(
        () => apiService.login(
          email: TestData.testEmail,
          password: 'wrong_password',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('register creates new user account', () async {
      final mockResponse = TestData.mockAuthResponse(token: TestData.testToken);

      dioAdapter.onPost(
        '/register',
        (server) => server.reply(201, mockResponse),
        data: {
          'name': TestData.testUsername,
          'email': TestData.testEmail,
          'password': TestData.testPassword,
          'password_confirmation': TestData.testPassword,
        },
      );

      when(
        () => mockStorageService.saveToken(
          TestData.testToken,
          expiresAt: any(named: 'expiresAt'),
        ),
      ).thenAnswer((_) async {});

      final result = await apiService.register(
        name: TestData.testUsername,
        email: TestData.testEmail,
        password: TestData.testPassword,
        passwordConfirmation: TestData.testPassword,
      );

      expect(result.success, true);
      expect(result.data, isNotNull);
    });

    test('logout clears token', () async {
      dioAdapter.onPost(
        '/logout',
        (server) => server.reply(200, {'success': true}),
      );

      when(() => mockStorageService.deleteToken()).thenAnswer((_) async {});

      final result = await apiService.logout();

      expect(result.success, true);
      verify(() => mockStorageService.deleteToken()).called(1);
    });

    test('getUserProfile fetches current user data', () async {
      final mockUser = TestData.mockUser();

      dioAdapter.onGet(
        '/user/profile',
        (server) => server.reply(200, {'success': true, 'data': mockUser}),
      );

      final result = await apiService.getUserProfile();

      expect(result.success, true);
      expect(result.data, isNotNull);
      expect(result.data!['email'], TestData.testEmail);
    });
  });

  group('Bottle API Tests', () {
    test('reportBottle submits bottle successfully', () async {
      final mockBottle = TestData.mockBottleLog(id: 1);

      dioAdapter.onPost(
        '/bottles/report',
        (server) => server.reply(201, {'success': true, 'data': mockBottle}),
        data: {'machine_id': 1, 'image': 'base64_encoded_image'},
      );

      final result = await apiService.reportBottle(
        machineId: 1,
        imageBase64: 'base64_encoded_image',
      );

      expect(result.success, true);
      expect(result.data, isNotNull);
      expect(result.data!['id'], 1);
    });

    test('getBottleHistory returns paginated list', () async {
      final mockBottles = List.generate(
        20,
        (i) => TestData.mockBottleLog(id: i + 1),
      );

      final mockResponse = TestData.mockPaginatedResponse(
        data: mockBottles,
        currentPage: 1,
        lastPage: 5,
        total: 100,
      );

      dioAdapter.onGet(
        '/bottles/history',
        (server) => server.reply(200, mockResponse),
        queryParameters: {'page': 1, 'per_page': 20},
      );

      final result = await apiService.getBottleHistory(page: 1, perPage: 20);

      expect(result.success, true);
      expect(result.data, isNotNull);
      expect(result.data!.length, 20);
      expect(result.meta?['total'], 100);
    });

    test('getBottleStatistics returns stats', () async {
      dioAdapter.onGet(
        '/bottles/statistics',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'total_bottles': 150,
            'total_credits': 750,
            'verified_bottles': 140,
            'pending_bottles': 10,
          },
        }),
      );

      final result = await apiService.getBottleStatistics();

      expect(result.success, true);
      expect(result.data, isNotNull);
      expect(result.data!['total_bottles'], 150);
    });
  });

  group('Internet Purchase API Tests', () {
    test('purchaseInternet creates new purchase', () async {
      dioAdapter.onPost(
        '/internet/purchase',
        (server) => server.reply(201, {
          'success': true,
          'data': {
            'id': 1,
            'voucher_code': 'VOUCHER123',
            'duration_hours': 24,
            'cost_credits': 10,
          },
        }),
        data: {'package_id': 1, 'machine_id': 1},
      );

      final result = await apiService.purchaseInternet(
        packageId: 1,
        machineId: 1,
      );

      expect(result.success, true);
      expect(result.data, isNotNull);
      expect(result.data!['voucher_code'], 'VOUCHER123');
    });

    test('getInternetPackages returns available packages', () async {
      dioAdapter.onGet(
        '/internet/packages',
        (server) => server.reply(200, {
          'success': true,
          'data': [
            {'id': 1, 'name': '1 Hour', 'duration_hours': 1, 'cost_credits': 2},
            {
              'id': 2,
              'name': '24 Hours',
              'duration_hours': 24,
              'cost_credits': 10,
            },
          ],
        }),
      );

      final result = await apiService.getInternetPackages();

      expect(result.success, true);
      expect(result.data, isNotNull);
      expect(result.data!.length, 2);
    });
  });

  group('Error Handling Tests', () {
    test('handles 401 unauthorized error', () async {
      dioAdapter.onGet(
        '/user/profile',
        (server) =>
            server.reply(401, {'success': false, 'message': 'Unauthorized'}),
      );

      expect(
        () => apiService.getUserProfile(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Unauthorized'),
          ),
        ),
      );
    });

    test('handles 404 not found error', () async {
      dioAdapter.onGet(
        '/bottles/999',
        (server) => server.reply(404, {
          'success': false,
          'message': 'Bottle not found',
        }),
      );

      expect(
        () => apiService.getBottleById(999),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('not found'),
          ),
        ),
      );
    });

    test('handles 500 server error', () async {
      dioAdapter.onGet(
        '/user/profile',
        (server) => server.reply(500, {
          'success': false,
          'message': 'Internal server error',
        }),
      );

      expect(
        () => apiService.getUserProfile(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('server error'),
          ),
        ),
      );
    });

    test('handles network timeout', () async {
      dioAdapter.onGet(
        '/user/profile',
        (server) => server.throws(
          408,
          DioException(
            requestOptions: RequestOptions(path: '/user/profile'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
      );

      expect(() => apiService.getUserProfile(), throwsA(isA<ApiException>()));
    });

    test('handles connection error', () async {
      dioAdapter.onGet(
        '/user/profile',
        (server) => server.throws(
          0,
          DioException(
            requestOptions: RequestOptions(path: '/user/profile'),
            type: DioExceptionType.connectionError,
          ),
        ),
      );

      expect(() => apiService.getUserProfile(), throwsA(isA<ApiException>()));
    });
  });

  group('Token Refresh Tests', () {
    test('automatically refreshes expired token', () async {
      // Mock expired token
      when(
        () => mockStorageService.isTokenExpired(),
      ).thenAnswer((_) async => true);

      // Mock refresh token response
      final newToken = 'new_token_12345';
      dioAdapter.onPost(
        '/refresh-token',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'token': newToken,
            'expires_in': 3600,
            'user': TestData.mockUser(),
          },
        }),
      );

      when(
        () => mockStorageService.saveToken(
          newToken,
          expiresAt: any(named: 'expiresAt'),
        ),
      ).thenAnswer((_) async {});

      // Mock the actual API call
      dioAdapter.onGet(
        '/user/profile',
        (server) =>
            server.reply(200, {'success': true, 'data': TestData.mockUser()}),
      );

      when(
        () => mockStorageService.getToken(),
      ).thenAnswer((_) async => newToken);

      final result = await apiService.getUserProfile();

      expect(result.success, true);
      verify(
        () => mockStorageService.saveToken(
          newToken,
          expiresAt: any(named: 'expiresAt'),
        ),
      ).called(1);
    });
  });

  group('Request Headers Tests', () {
    test('includes authorization header when token exists', () async {
      dioAdapter.onGet('/user/profile', (server) {
        // Verify Authorization header is present
        return server.reply(200, {
          'success': true,
          'data': TestData.mockUser(),
        });
      }, headers: {'Authorization': 'Bearer ${TestData.testToken}'});

      final result = await apiService.getUserProfile();
      expect(result.success, true);
    });
  });
}
