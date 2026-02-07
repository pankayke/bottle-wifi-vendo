import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  /// Private constructor to prevent instantiation
  AppConstants._();

  /// Base URL for the Laravel API
  /// TODO: Replace with your actual API URL
  static const String baseUrl = 'http://localhost:8000/api/v1';

  /// API Endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String logoutEndpoint = '/logout';
  static const String reportBottleEndpoint = '/bottles/report';
  static const String bottleHistoryEndpoint = '/bottles/history';
  static const String bottleStatisticsEndpoint = '/bottles/statistics';
  static const String requestInternetEndpoint = '/credits/request-internet';
  static const String viewCreditsEndpoint = '/credits';
  static const String activeSessionEndpoint = '/credits/active-session';
  static const String machineStatusEndpoint = '/machines/status';
  static const String machineHeartbeatEndpoint = '/machines/heartbeat';
  static const String userProfileEndpoint = '/profile';

  /// Storage Keys
  static const String tokenKey = 'auth_token';
  static const String tokenExpiryKey = 'token_expiry';
  static const String userKey = 'user_data';

  /// Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Token Refresh
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  static const String refreshTokenEndpoint = '/refresh-token';

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
