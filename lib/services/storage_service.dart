import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user.dart';
import '../utils/constants.dart';

/// Secure storage service for sensitive data
class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Save authentication token with expiry
  Future<void> saveToken(String token, {DateTime? expiresAt}) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
    if (expiresAt != null) {
      await _storage.write(
        key: AppConstants.tokenExpiryKey,
        value: expiresAt.toIso8601String(),
      );
    }
  }

  /// Get authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  /// Get token expiry date
  Future<DateTime?> getTokenExpiry() async {
    final expiryStr = await _storage.read(key: AppConstants.tokenExpiryKey);
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
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.tokenExpiryKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Save user data
  Future<void> saveUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: AppConstants.userKey, value: userJson);
  }

  /// Get user data
  Future<User?> getUser() async {
    final userJson = await _storage.read(key: AppConstants.userKey);
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
    await _storage.delete(key: AppConstants.userKey);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
