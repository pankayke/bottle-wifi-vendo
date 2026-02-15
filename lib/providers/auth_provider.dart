import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/guest_service.dart';
import '../services/storage_service.dart';
import '../utils/api_exception.dart';

/// Unified authentication state provider.
/// Supports admin login, user login, user registration, and guest conversion.
class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;
  final GuestService _guestService;

  /// Expose API service for unauthenticated operations (e.g. forgot password).
  ApiService get apiService => _apiService;

  User? _user;
  bool _isAuthenticated = false;
  bool _isGuest = true;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({
    required ApiService apiService,
    required StorageService storageService,
    required GuestService guestService,
  }) : _apiService = apiService,
       _storageService = storageService,
       _guestService = guestService;

  // ==================== Getters ====================

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== Initialisation ====================

  /// Restore auth state from persisted storage.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAuth = await _storageService.isAuthenticated();
      if (isAuth) {
        _user = await _storageService.getUser();
        _isAuthenticated = _user != null;
        _isGuest = _user == null;

        if (_isAuthenticated) {
          await refreshUserProfile();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      _isGuest = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Admin Login ====================

  /// Login as admin — no role restriction on the API call itself,
  /// but the caller (admin login screen) checks `user.isAdmin`.
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      _user = response.data;
      _isAuthenticated = true;
      _isGuest = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== User Login ====================

  /// Login as a regular user — blocks admin accounts.
  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.loginUser(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        _user = response.data;
        _isAuthenticated = true;
        _isGuest = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response.message ?? 'Login failed';
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Registration ====================

  /// Register a new user account.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response.success && response.data != null) {
        _user = response.data;
        _isAuthenticated = true;
        _isGuest = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response.message ?? 'Registration failed';
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Guest Conversion ====================

  /// Convert guest to registered user, transferring accumulated credits.
  Future<bool> convertGuestToUser({
    required String deviceFingerprint,
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _guestService.convertToRegisteredUser(
        deviceFingerprint: deviceFingerprint,
        name: name,
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final userMap = data['user'] as Map<String, dynamic>;

        await _storageService.saveToken(token);
        _user = User.fromJson(userMap);
        await _storageService.saveUser(_user!);
        _isAuthenticated = true;
        _isGuest = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['error'] as String? ?? 'Conversion failed';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Logout ====================

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('Logout API error: $e');
    } finally {
      await _storageService.clearAll();
      _user = null;
      _isAuthenticated = false;
      _isGuest = true;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user profile
  Future<void> refreshUserProfile() async {
    try {
      final response = await _apiService.getUserProfile();
      _user = response.data;
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Token expired, logout user
        await logout();
      }
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }

  /// Update user credits locally
  void updateUserCredits(int credits) {
    if (_user != null) {
      _user = _user!.copyWith(credits: credits);
      _storageService.saveUser(_user!);
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Change user password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to change password';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile (name, email, phone)
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
      );
      _user = response.data;
      await _storageService.saveUser(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
