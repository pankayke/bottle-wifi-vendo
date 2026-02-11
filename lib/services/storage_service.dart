import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../utils/constants.dart';

/// Storage service that persists data across sessions.
/// Uses SharedPreferences which works reliably on Web, Android, and iOS.
class StorageService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save authentication token with expiry
  Future<void> saveToken(String token, {DateTime? expiresAt}) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.tokenKey, token);
    if (expiresAt != null) {
      await prefs.setString(
        AppConstants.tokenExpiryKey,
        expiresAt.toIso8601String(),
      );
    }
  }

  /// Get authentication token
  Future<String?> getToken() async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.tokenKey);
  }

  /// Get token expiry date
  Future<DateTime?> getTokenExpiry() async {
    final prefs = await _preferences;
    final expiryStr = prefs.getString(AppConstants.tokenExpiryKey);
    if (expiryStr == null) return null;
    try {
      return DateTime.parse(expiryStr);
    } catch (e) {
      return null;
    }
  }

  /// Check if token is expired or near expiry
  Future<bool> isTokenExpired({
    Duration buffer = const Duration(minutes: 5),
  }) async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return false;
    return DateTime.now().add(buffer).isAfter(expiry);
  }

  /// Delete authentication token
  Future<void> deleteToken() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.tokenExpiryKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Save user data
  Future<void> saveUser(User user) async {
    final prefs = await _preferences;
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(AppConstants.userKey, userJson);
  }

  /// Get user data
  Future<User?> getUser() async {
    final prefs = await _preferences;
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  /// Delete user data
  Future<void> deleteUser() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.userKey);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.tokenExpiryKey);
    await prefs.remove(AppConstants.userKey);
  }
}
