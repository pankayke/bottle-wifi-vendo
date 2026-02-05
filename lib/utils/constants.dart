import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  /// Private constructor to prevent instantiation
  AppConstants._();

  /// Base URL for the Laravel API
  /// TODO: Replace with your actual API URL
  static const String baseUrl = 'https://your-laravel-api.com/api';

  /// API Endpoints
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String logoutEndpoint = '/logout';
  static const String reportBottleEndpoint = '/bottle/report';
  static const String bottleHistoryEndpoint = '/bottle/history';
  static const String bottleStatisticsEndpoint = '/bottle/statistics';
  static const String requestInternetEndpoint = '/internet/request';
  static const String viewCreditsEndpoint = '/internet/credits';
  static const String activeSessionEndpoint = '/internet/session';
  static const String machineStatusEndpoint = '/machines/status';
  static const String machineHeartbeatEndpoint = '/machines/heartbeat';
  static const String userProfileEndpoint = '/user/profile';

  /// Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  /// Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

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

  static const primaryColor = Color(0xFF2196F3);
  static const primaryDark = Color(0xFF1976D2);
  static const primaryLight = Color(0xFFBBDEFB);
  static const accentColor = Color(0xFF4CAF50);
  static const errorColor = Color(0xFFF44336);
  static const warningColor = Color(0xFFFF9800);
  static const successColor = Color(0xFF4CAF50);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const dividerColor = Color(0xFFBDBDBD);
  static const backgroundColor = Color(0xFFF5F5F5);
  static const cardBackground = Color(0xFFFFFFFF);
}
