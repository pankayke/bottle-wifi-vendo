import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/api_exception.dart';

/// Authentication state provider
class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService,
       _storageService = storageService;

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize authentication state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAuth = await _storageService.isAuthenticated();
      if (isAuth) {
        _user = await _storageService.getUser();
        _isAuthenticated = _user != null;

        // Refresh user profile
        if (_isAuthenticated) {
          await refreshUserProfile();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user
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

      _user = response.data;
      _isAuthenticated = true;
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

  /// Login user
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

  /// Login with token (used after guest registration)
  Future<void> loginWithToken(
    String token,
    Map<String, dynamic> userData,
  ) async {
    try {
      // Save token to storage
      await _storageService.saveToken(token);

      // Create user object from data
      _user = User.fromJson(userData);
      await _storageService.saveUser(_user!);

      _isAuthenticated = true;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to save authentication data';
      debugPrint('Login with token error: $e');
      notifyListeners();
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
      debugPrint('Logout API error: $e');
    } finally {
      // Always clear local storage to prevent stale auth state
      await _storageService.clearAll();
      _user = null;
      _isAuthenticated = false;
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
}
