/// Integration Tests for Authentication Flow
///
/// Tests the complete authentication flow including login, register, and logout

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bottle_wifi/providers/auth_provider.dart';
import 'package:bottle_wifi/services/api_service.dart';
import 'package:bottle_wifi/services/storage_service.dart';
import 'package:bottle_wifi/models/user.dart';
import 'package:bottle_wifi/utils/api_response.dart';
import 'package:bottle_wifi/utils/api_exception.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_classes.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late AuthProvider authProvider;
  late MockApiService mockApiService;
  late MockStorageService mockStorageService;

  setUp(() {
    registerMocktailFallbacks();
    mockApiService = MockApiService();
    mockStorageService = MockStorageService();

    authProvider = AuthProvider(
      apiService: mockApiService,
      storageService: mockStorageService,
    );
  });

  group('AuthProvider Login Tests', () {
    test('successful login updates state correctly', () async {
      final mockUser = User.fromJson(TestData.mockUser());
      final mockResponse = ApiResponse<User>(success: true, data: mockUser);

      when(
        () => mockApiService.login(
          email: TestData.testEmail,
          password: TestData.testPassword,
        ),
      ).thenAnswer((_) async => mockResponse);

      final result = await authProvider.login(
        email: TestData.testEmail,
        password: TestData.testPassword,
      );

      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, isNotNull);
      expect(authProvider.user!.email, TestData.testEmail);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, isNull);
    });

    test('failed login handles error correctly', () async {
      when(
        () => mockApiService.login(
          email: TestData.testEmail,
          password: 'wrong_password',
        ),
      ).thenThrow(ApiException('Invalid credentials'));

      final result = await authProvider.login(
        email: TestData.testEmail,
        password: 'wrong_password',
      );

      expect(result, false);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, isNull);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, 'Invalid credentials');
    });

    test('login sets loading state during request', () async {
      final mockUser = User.fromJson(TestData.mockUser());
      final mockResponse = ApiResponse<User>(success: true, data: mockUser);

      when(
        () => mockApiService.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return mockResponse;
      });

      // Start login without awaiting
      final loginFuture = authProvider.login(
        email: TestData.testEmail,
        password: TestData.testPassword,
      );

      // Check loading state
      await Future.delayed(const Duration(milliseconds: 10));
      expect(authProvider.isLoading, true);

      // Complete login
      await loginFuture;
      expect(authProvider.isLoading, false);
    });

    test('login notifies listeners on state change', () async {
      final mockUser = User.fromJson(TestData.mockUser());
      final mockResponse = ApiResponse<User>(success: true, data: mockUser);

      when(
        () => mockApiService.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => mockResponse);

      var notifyCount = 0;
      authProvider.addListener(() {
        notifyCount++;
      });

      await authProvider.login(
        email: TestData.testEmail,
        password: TestData.testPassword,
      );

      expect(notifyCount, greaterThan(0));
    });
  });

  group('AuthProvider Register Tests', () {
    test('successful registration creates user account', () async {
      final mockUser = User.fromJson(TestData.mockUser());
      final mockResponse = ApiResponse<User>(success: true, data: mockUser);

      when(
        () => mockApiService.register(
          name: TestData.testUsername,
          email: TestData.testEmail,
          password: TestData.testPassword,
          passwordConfirmation: TestData.testPassword,
        ),
      ).thenAnswer((_) async => mockResponse);

      final result = await authProvider.register(
        name: TestData.testUsername,
        email: TestData.testEmail,
        password: TestData.testPassword,
        passwordConfirmation: TestData.testPassword,
      );

      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, isNotNull);
      expect(authProvider.user!.name, TestData.testUsername);
    });

    test('registration fails with mismatched passwords', () async {
      when(
        () => mockApiService.register(
          name: TestData.testUsername,
          email: TestData.testEmail,
          password: TestData.testPassword,
          passwordConfirmation: 'different_password',
        ),
      ).thenThrow(ApiException('Passwords do not match'));

      final result = await authProvider.register(
        name: TestData.testUsername,
        email: TestData.testEmail,
        password: TestData.testPassword,
        passwordConfirmation: 'different_password',
      );

      expect(result, false);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.errorMessage, 'Passwords do not match');
    });

    test('registration fails with existing email', () async {
      when(
        () => mockApiService.register(
          name: any(named: 'name'),
          email: TestData.testEmail,
          password: any(named: 'password'),
          passwordConfirmation: any(named: 'passwordConfirmation'),
        ),
      ).thenThrow(ApiException('Email already exists'));

      final result = await authProvider.register(
        name: TestData.testUsername,
        email: TestData.testEmail,
        password: TestData.testPassword,
        passwordConfirmation: TestData.testPassword,
      );

      expect(result, false);
      expect(authProvider.errorMessage, 'Email already exists');
    });
  });

  group('AuthProvider Logout Tests', () {
    test('logout clears user state', () async {
      // Setup authenticated state
      final mockUser = User.fromJson(TestData.mockUser());
      final loginResponse = ApiResponse<User>(success: true, data: mockUser);

      when(
        () => mockApiService.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => loginResponse);

      await authProvider.login(
        email: TestData.testEmail,
        password: TestData.testPassword,
      );

      expect(authProvider.isAuthenticated, true);

      // Now logout
      when(
        () => mockApiService.logout(),
      ).thenAnswer((_) async => ApiResponse<void>(success: true));

      final result = await authProvider.logout();

      expect(result, true);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, isNull);
    });

    test('logout handles API errors gracefully', () async {
      when(
        () => mockApiService.logout(),
      ).thenThrow(ApiException('Logout failed'));

      final result = await authProvider.logout();

      expect(result, false);
      expect(authProvider.errorMessage, isNotNull);
    });
  });

  group('AuthProvider Initialize Tests', () {
    test('initialize restores authenticated state', () async {
      final mockUser = User.fromJson(TestData.mockUser());

      when(
        () => mockStorageService.isAuthenticated(),
      ).thenAnswer((_) async => true);
      when(
        () => mockStorageService.getUser(),
      ).thenAnswer((_) async => mockUser);
      when(() => mockApiService.getUserProfile()).thenAnswer(
        (_) async => ApiResponse<User>(success: true, data: mockUser),
      );

      await authProvider.initialize();

      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, isNotNull);
    });

    test('initialize handles unauthenticated state', () async {
      when(
        () => mockStorageService.isAuthenticated(),
      ).thenAnswer((_) async => false);

      await authProvider.initialize();

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, isNull);
    });

    test('initialize handles storage errors', () async {
      when(
        () => mockStorageService.isAuthenticated(),
      ).thenThrow(Exception('Storage error'));

      await authProvider.initialize();

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.errorMessage, isNotNull);
    });
  });

  group('AuthProvider Refresh Profile Tests', () {
    test('refreshUserProfile updates user data', () async {
      // Setup authenticated state first
      final originalUser = User.fromJson(TestData.mockUser());
      final loginResponse = ApiResponse<User>(
        success: true,
        data: originalUser,
      );

      when(
        () => mockApiService.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => loginResponse);

      await authProvider.login(
        email: TestData.testEmail,
        password: TestData.testPassword,
      );

      // Now refresh with updated data
      final updatedUser = User.fromJson(
        TestData.mockUser(name: 'Updated Name'),
      );

      when(() => mockApiService.getUserProfile()).thenAnswer(
        (_) async => ApiResponse<User>(success: true, data: updatedUser),
      );

      await authProvider.refreshUserProfile();

      expect(authProvider.user!.name, 'Updated Name');
    });

    test('refreshUserProfile handles errors', () async {
      when(
        () => mockApiService.getUserProfile(),
      ).thenThrow(ApiException('Failed to fetch profile'));

      await authProvider.refreshUserProfile();

      expect(authProvider.errorMessage, isNotNull);
    });
  });

  group('Edge Cases', () {
    test('handles multiple simultaneous login attempts', () async {
      final mockUser = User.fromJson(TestData.mockUser());
      final mockResponse = ApiResponse<User>(success: true, data: mockUser);

      when(
        () => mockApiService.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return mockResponse;
      });

      // Start multiple login attempts
      final future1 = authProvider.login(
        email: TestData.testEmail,
        password: TestData.testPassword,
      );
      final future2 = authProvider.login(
        email: TestData.testEmail,
        password: TestData.testPassword,
      );

      await Future.wait([future1, future2]);

      expect(authProvider.isAuthenticated, true);
    });

    test('clears error message on new login attempt', () async {
      // First failed attempt
      when(
        () => mockApiService.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(ApiException('Invalid credentials'));

      await authProvider.login(
        email: TestData.testEmail,
        password: 'wrong_password',
      );

      expect(authProvider.errorMessage, 'Invalid credentials');

      // Second successful attempt
      final mockUser = User.fromJson(TestData.mockUser());
      when(
        () => mockApiService.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse<User>(success: true, data: mockUser),
      );

      await authProvider.login(
        email: TestData.testEmail,
        password: TestData.testPassword,
      );

      expect(authProvider.errorMessage, isNull);
    });
  });
}
