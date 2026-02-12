import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  /// Private constructor to prevent instantiation
  AppConstants._();

  // All data is stored locally on the device — no backend server needed.

  /// Storage Keys
  static const String tokenKey = 'auth_token';
  static const String tokenExpiryKey = 'token_expiry';
  static const String userKey = 'user_data';

  /// Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;

  /// UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;
}

/// Application color scheme
class AppColors {
  AppColors._();

  static const primaryColor = Color(0xFF1565C0); // Blue
  static const primaryDark = Color(0xFF0D47A1);
  static const primaryLight = Color(0xFF42A5F5);
  static const accentColor = Color(0xFF1976D2);
  static const errorColor = Color(0xFFF44336);
  static const warningColor = Color(0xFFFF9800);
  static const successColor = Color(0xFF48BB78); // Green for success
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
  static const dividerColor = Color(0xFFE2E8F0);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const cardBackground = Color(0xFFFFFFFF);
}
