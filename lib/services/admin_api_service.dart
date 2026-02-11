import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/bottle_log.dart';
import '../models/machine.dart';
import '../models/user.dart';
import '../models/voucher.dart';
import '../utils/api_exception.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';

/// Admin-specific API service for admin panel operations
class AdminApiService {
  final StorageService _storageService;
  final String baseUrl;

  AdminApiService({required StorageService storageService, String? baseUrl})
    : _storageService = storageService,
      baseUrl = baseUrl ?? AppConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await _storageService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {'success': true};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    Map<String, dynamic>? errorBody;
    try {
      errorBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    switch (response.statusCode) {
      case 401:
        throw ApiException.unauthorized();
      case 403:
        throw ApiException(
          message: 'Access denied. Admin privileges required.',
          statusCode: 403,
        );
      case 422:
        final message = errorBody?['message'] as String? ?? 'Validation failed';
        throw ApiException.validationError(message);
      case 500:
        throw ApiException.serverError();
      default:
        final message = errorBody?['message'] as String? ?? 'An error occurred';
        throw ApiException(message: message, statusCode: response.statusCode);
    }
  }

  Future<Map<String, dynamic>> _execute(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(
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
      throw ApiException(message: 'Unexpected error: $e', statusCode: null);
    }
  }

  // ==================== Dashboard ====================

  /// Get admin dashboard statistics
  Future<AdminDashboardStats> getDashboardStats() async {
    try {
      final response = await _execute(
        () async => http.get(
          Uri.parse('$baseUrl/admin/dashboard'),
          headers: await _getHeaders(),
        ),
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;
      return AdminDashboardStats.fromJson(data);
    } on ApiException {
      // Return mock data if endpoint doesn't exist yet
      return AdminDashboardStats.empty();
    }
  }

  // ==================== Machine Management ====================

  /// Get all machines (admin)
  Future<List<Machine>> getAllMachines() async {
    final response = await _execute(
      () async => http.get(
        Uri.parse('$baseUrl/admin/machines'),
        headers: await _getHeaders(),
      ),
    );

    final data = response['data'] as Map<String, dynamic>?;
    final machinesList =
        data?['machines'] as List? ?? response['machines'] as List? ?? [];

    return machinesList
        .map((json) => Machine.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new machine
  Future<Machine> createMachine({
    required String name,
    required String location,
    String? macAddress,
    String? ipAddress,
  }) async {
    final body = jsonEncode({
      'name': name,
      'location': location,
      if (macAddress != null) 'mac_address': macAddress,
      if (ipAddress != null) 'ip_address': ipAddress,
    });

    final response = await _execute(
      () async => http.post(
        Uri.parse('$baseUrl/admin/machines'),
        headers: await _getHeaders(),
        body: body,
      ),
    );

    final data = response['data'] as Map<String, dynamic>? ?? response;
    final machineData = data['machine'] as Map<String, dynamic>? ?? data;
    return Machine.fromJson(machineData);
  }

  /// Update machine status
  Future<void> updateMachineStatus(int machineId, String status) async {
    await _execute(
      () async => http.put(
        Uri.parse('$baseUrl/admin/machines/$machineId/status'),
        headers: await _getHeaders(),
        body: jsonEncode({'status': status}),
      ),
    );
  }

  /// Get offline machines
  Future<List<Machine>> getOfflineMachines() async {
    final response = await _execute(
      () async => http.get(
        Uri.parse('$baseUrl/admin/machines/offline'),
        headers: await _getHeaders(),
      ),
    );

    final data = response['data'] as Map<String, dynamic>?;
    final machinesList =
        data?['machines'] as List? ?? response['machines'] as List? ?? [];

    return machinesList
        .map((json) => Machine.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ==================== User Management ====================

  /// Get all users (admin)
  Future<List<User>> getAllUsers({int page = 1, String? search}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _execute(
      () async => http.get(
        Uri.parse('$baseUrl/admin/users').replace(queryParameters: queryParams),
        headers: await _getHeaders(),
      ),
    );

    final data = response['data'] as Map<String, dynamic>?;

    // Laravel paginate() returns users under 'data.data'
    final usersList =
        data?['data'] as List? ??
        data?['users'] as List? ??
        response['users'] as List? ??
        [];

    return usersList
        .map((json) => User.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Suspend a user
  Future<void> suspendUser(int userId, String reason) async {
    await _execute(
      () async => http.post(
        Uri.parse('$baseUrl/admin/users/$userId/suspend'),
        headers: await _getHeaders(),
        body: jsonEncode({'reason': reason}),
      ),
    );
  }

  /// Resume a suspended user
  Future<void> resumeUser(int userId) async {
    await _execute(
      () async => http.post(
        Uri.parse('$baseUrl/admin/users/$userId/resume'),
        headers: await _getHeaders(),
      ),
    );
  }

  /// Delete a user
  Future<void> deleteUser(int userId) async {
    await _execute(
      () async => http.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: await _getHeaders(),
      ),
    );
  }

  /// Adjust user credits
  Future<void> adjustCredits(int userId, int amount, String reason) async {
    await _execute(
      () async => http.post(
        Uri.parse('$baseUrl/admin/users/$userId/credits'),
        headers: await _getHeaders(),
        body: jsonEncode({'amount': amount, 'reason': reason}),
      ),
    );
  }

  // ==================== Voucher Management ====================

  /// Generate a voucher
  Future<Voucher> generateVoucher({
    required int minutes,
    String type = 'single_use',
    int count = 1,
    DateTime? expiresAt,
  }) async {
    final response = await _execute(
      () async => http.post(
        Uri.parse('$baseUrl/voucher/generate'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'minutes': minutes,
          'type': type,
          'count': count,
          if (expiresAt != null)
            'expires_in_days': expiresAt
                .difference(DateTime.now())
                .inDays
                .clamp(1, 365),
        }),
      ),
    );

    final vouchers = response['vouchers'] as List?;
    if (vouchers != null && vouchers.isNotEmpty) {
      return Voucher.fromJson(vouchers.first as Map<String, dynamic>);
    }
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final voucherData = data['voucher'] as Map<String, dynamic>? ?? data;
    return Voucher.fromJson(voucherData);
  }

  /// Get all vouchers
  Future<List<Voucher>> getVouchers() async {
    final response = await _execute(
      () async => http.get(
        Uri.parse('$baseUrl/voucher/list'),
        headers: await _getHeaders(),
      ),
    );

    // Handle paginated response: { vouchers: { data: [...], current_page: 1, ... } }
    final vouchersField = response['vouchers'];
    List vouchersList;
    if (vouchersField is Map) {
      vouchersList = vouchersField['data'] as List? ?? [];
    } else if (vouchersField is List) {
      vouchersList = vouchersField;
    } else {
      final data = response['data'] as Map<String, dynamic>?;
      vouchersList = data?['vouchers'] as List? ?? [];
    }

    return vouchersList
        .map((json) => Voucher.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Revoke a voucher
  Future<void> revokeVoucher(int voucherId, {required String reason}) async {
    await _execute(
      () async => http.post(
        Uri.parse('$baseUrl/voucher/$voucherId/revoke'),
        headers: await _getHeaders(),
        body: jsonEncode({'reason': reason}),
      ),
    );
  }

  // ==================== Analytics ====================

  /// Get bottle analytics (admin-scoped, all users' data)
  Future<Map<String, dynamic>> getBottleAnalytics({
    String period = 'month',
  }) async {
    try {
      final response = await _execute(
        () async => http.get(
          Uri.parse(
            '$baseUrl/admin/analytics/bottles',
          ).replace(queryParameters: {'period': period}),
          headers: await _getHeaders(),
        ),
      );
      return response['data'] as Map<String, dynamic>? ?? {};
    } on ApiException {
      return {};
    }
  }

  /// Get bottle logs for analytics
  Future<List<BottleLog>> getBottleLogs({
    int page = 1,
    int? machineId,
    DateTime? from,
    DateTime? to,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (machineId != null) 'machine_id': machineId.toString(),
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    };

    try {
      final response = await _execute(
        () async => http.get(
          Uri.parse(
            '$baseUrl/bottles/history',
          ).replace(queryParameters: queryParams),
          headers: await _getHeaders(),
        ),
      );

      final data = response['data'] as Map<String, dynamic>?;
      final logsList =
          data?['bottles'] as List? ?? response['bottles'] as List? ?? [];

      return logsList
          .map((json) => BottleLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      return [];
    }
  }
}

/// Admin dashboard statistics model
class AdminDashboardStats {
  final int totalMachines;
  final int activeMachines;
  final int offlineMachines;
  final int totalUsers;
  final int activeSessionsCount;
  final int totalBottlesProcessed;
  final int todayBottles;
  final int totalCreditsAwarded;
  final List<DailyBottleCount> dailyBottles;

  AdminDashboardStats({
    required this.totalMachines,
    required this.activeMachines,
    required this.offlineMachines,
    required this.totalUsers,
    required this.activeSessionsCount,
    required this.totalBottlesProcessed,
    required this.todayBottles,
    required this.totalCreditsAwarded,
    required this.dailyBottles,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final dailyList = json['daily_bottles'] as List? ?? [];
    return AdminDashboardStats(
      totalMachines: json['total_machines'] as int? ?? 0,
      activeMachines: json['active_machines'] as int? ?? 0,
      offlineMachines: json['offline_machines'] as int? ?? 0,
      totalUsers: json['total_users'] as int? ?? 0,
      activeSessionsCount: json['active_sessions'] as int? ?? 0,
      totalBottlesProcessed: json['total_bottles'] as int? ?? 0,
      todayBottles: json['today_bottles'] as int? ?? 0,
      totalCreditsAwarded: json['total_credits'] as int? ?? 0,
      dailyBottles: dailyList
          .map((e) => DailyBottleCount.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory AdminDashboardStats.empty() {
    return AdminDashboardStats(
      totalMachines: 0,
      activeMachines: 0,
      offlineMachines: 0,
      totalUsers: 0,
      activeSessionsCount: 0,
      totalBottlesProcessed: 0,
      todayBottles: 0,
      totalCreditsAwarded: 0,
      dailyBottles: [],
    );
  }
}

/// Daily bottle count for charts
class DailyBottleCount {
  final DateTime date;
  final int count;

  DailyBottleCount({required this.date, required this.count});

  factory DailyBottleCount.fromJson(Map<String, dynamic> json) {
    return DailyBottleCount(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int? ?? 0,
    );
  }
}
