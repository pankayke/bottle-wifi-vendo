import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/bottle_log.dart';
import '../models/machine.dart';
import '../models/user.dart';
import '../models/voucher.dart';
import 'database_helper.dart';
import 'storage_service.dart';

/// Admin-specific local service for admin panel operations.
/// All operations hit the on-device SQLite database.
class AdminApiService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Constructor kept compatible with existing callers.
  AdminApiService({required StorageService storageService, String? baseUrl});

  // ==================== Dashboard ====================

  Future<AdminDashboardStats> getDashboardStats() async {
    try {
      final db = await _db.database;

      int v(List<Map<String, dynamic>> r) => Sqflite.firstIntValue(r) ?? 0;

      final totalMachines = v(
        await db.rawQuery('SELECT COUNT(*) FROM machines'),
      );
      final activeMachines = v(
        await db.rawQuery(
          "SELECT COUNT(*) FROM machines WHERE status = 'active'",
        ),
      );
      final offlineMachines = v(
        await db.rawQuery('SELECT COUNT(*) FROM machines WHERE is_online = 0'),
      );
      final totalUsers = v(
        await db.rawQuery("SELECT COUNT(*) FROM users WHERE role = 'user'"),
      );
      final totalBottles = v(
        await db.rawQuery('SELECT COUNT(*) FROM bottle_logs'),
      );
      final todayStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ).toIso8601String();
      final todayBottles = v(
        await db.rawQuery(
          'SELECT COUNT(*) FROM bottle_logs WHERE created_at >= ?',
          [todayStart],
        ),
      );
      final totalCredits = v(
        await db.rawQuery(
          'SELECT COALESCE(SUM(credits_awarded), 0) FROM bottle_logs',
        ),
      );

      // Daily bottles for last 7 days
      final dailyBottles = <DailyBottleCount>[];
      for (int i = 6; i >= 0; i--) {
        final day = DateTime.now().subtract(Duration(days: i));
        final dayStart = DateTime(
          day.year,
          day.month,
          day.day,
        ).toIso8601String();
        final dayEnd = DateTime(
          day.year,
          day.month,
          day.day,
          23,
          59,
          59,
        ).toIso8601String();
        final count = v(
          await db.rawQuery(
            'SELECT COUNT(*) FROM bottle_logs WHERE created_at >= ? AND created_at <= ?',
            [dayStart, dayEnd],
          ),
        );
        dailyBottles.add(DailyBottleCount(date: day, count: count));
      }

      return AdminDashboardStats(
        totalMachines: totalMachines,
        activeMachines: activeMachines,
        offlineMachines: offlineMachines,
        totalUsers: totalUsers,
        activeSessionsCount: 0,
        totalBottlesProcessed: totalBottles,
        todayBottles: todayBottles,
        totalCreditsAwarded: totalCredits,
        dailyBottles: dailyBottles,
      );
    } catch (e) {
      debugPrint('Dashboard stats error: $e');
      return AdminDashboardStats.empty();
    }
  }

  // ==================== Machine Management ====================

  Future<List<Machine>> getAllMachines() async {
    final db = await _db.database;
    final rows = await db.query('machines', orderBy: 'created_at DESC');
    return rows
        .map((r) => Machine.fromJson(DatabaseHelper.machineRowToJson(r)))
        .toList();
  }

  Future<Machine> createMachine({
    required String name,
    required String location,
    String? macAddress,
    String? ipAddress,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('machines', {
      'name': name,
      'location': location,
      'mac_address': macAddress ?? '',
      'ip_address': ipAddress ?? '',
      'status': 'active',
      'is_online': 1,
      'last_online': now,
      'total_bottles_processed': 0,
      'created_at': now,
      'updated_at': now,
    });
    final row = (await db.query(
      'machines',
      where: 'id = ?',
      whereArgs: [id],
    )).first;
    return Machine.fromJson(DatabaseHelper.machineRowToJson(row));
  }

  Future<void> updateMachineStatus(int machineId, String status) async {
    final db = await _db.database;
    await db.update(
      'machines',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [machineId],
    );
  }

  Future<void> deleteMachine(int machineId) async {
    final db = await _db.database;
    await db.delete('machines', where: 'id = ?', whereArgs: [machineId]);
  }

  Future<List<Machine>> getOfflineMachines() async {
    final db = await _db.database;
    final rows = await db.query(
      'machines',
      where: 'is_online = 0',
      orderBy: 'updated_at DESC',
    );
    return rows
        .map((r) => Machine.fromJson(DatabaseHelper.machineRowToJson(r)))
        .toList();
  }

  // ==================== User Management ====================

  Future<List<User>> getAllUsers({int page = 1, String? search}) async {
    final db = await _db.database;
    String? where;
    List<dynamic>? whereArgs;

    if (search != null && search.isNotEmpty) {
      where = "(name LIKE ? OR email LIKE ?) AND role = 'user'";
      whereArgs = ['%$search%', '%$search%'];
    } else {
      where = "role = 'user'";
    }

    final rows = await db.query(
      'users',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => User.fromJson(r)).toList();
  }

  Future<void> suspendUser(int userId, String reason) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'users',
      {'suspended_at': now, 'suspension_reason': reason, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> resumeUser(int userId) async {
    final db = await _db.database;
    await db.update(
      'users',
      {
        'suspended_at': null,
        'suspension_reason': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteUser(int userId) async {
    final db = await _db.database;
    // Also delete related bottle logs
    await db.delete('bottle_logs', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> resetUserPassword(int userId) async {
    final db = await _db.database;
    await db.update(
      'users',
      {
        'password_hash': DatabaseHelper.hashPassword('password'),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> adjustCredits(int userId, int amount, String reason) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.rawUpdate(
      'UPDATE users SET credits = MAX(0, credits + ?), updated_at = ? WHERE id = ?',
      [amount, now, userId],
    );
  }

  // ==================== Voucher Management ====================

  Future<Voucher> generateVoucher({
    required int minutes,
    String type = 'single_use',
    int count = 1,
    DateTime? expiresAt,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final code = DatabaseHelper.generateVoucherCode();

    final id = await db.insert('vouchers', {
      'code': code,
      'minutes': minutes,
      'status': 'active',
      'type': type,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': now,
    });

    final row = (await db.query(
      'vouchers',
      where: 'id = ?',
      whereArgs: [id],
    )).first;
    return Voucher.fromJson(row);
  }

  Future<List<Voucher>> getVouchers() async {
    final db = await _db.database;
    final rows = await db.query('vouchers', orderBy: 'created_at DESC');
    return rows.map((r) => Voucher.fromJson(r)).toList();
  }

  Future<void> revokeVoucher(int voucherId, {required String reason}) async {
    final db = await _db.database;
    await db.update(
      'vouchers',
      {'status': 'revoked', 'revoke_reason': reason},
      where: 'id = ?',
      whereArgs: [voucherId],
    );
  }

  // ==================== Analytics ====================

  Future<Map<String, dynamic>> getBottleAnalytics({
    String period = 'month',
  }) async {
    try {
      final db = await _db.database;
      final days = period == 'week' ? 7 : (period == 'year' ? 365 : 30);
      final since = DateTime.now()
          .subtract(Duration(days: days))
          .toIso8601String();

      final total =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM bottle_logs WHERE created_at >= ?',
              [since],
            ),
          ) ??
          0;
      final credits =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COALESCE(SUM(credits_awarded), 0) FROM bottle_logs WHERE created_at >= ?',
              [since],
            ),
          ) ??
          0;

      return {
        'total_bottles': total,
        'total_credits': credits,
        'period': period,
      };
    } catch (e) {
      debugPrint('Analytics error: $e');
      return {};
    }
  }

  Future<List<BottleLog>> getBottleLogs({
    int page = 1,
    int? machineId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final db = await _db.database;
      final conditions = <String>[];
      final args = <dynamic>[];

      if (machineId != null) {
        conditions.add('machine_id = ?');
        args.add(machineId);
      }
      if (from != null) {
        conditions.add('created_at >= ?');
        args.add(from.toIso8601String());
      }
      if (to != null) {
        conditions.add('created_at <= ?');
        args.add(to.toIso8601String());
      }

      final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;
      final offset = (page - 1) * 20;

      final rows = await db.query(
        'bottle_logs',
        where: where,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'created_at DESC',
        limit: 20,
        offset: offset,
      );
      return rows.map((r) => BottleLog.fromJson(r)).toList();
    } catch (e) {
      debugPrint('Get bottle logs error: $e');
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
