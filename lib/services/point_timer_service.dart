import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

/// Handles bottle scanning for authenticated users.
/// Credits go directly to user account — no voucher intermediary.
class PointTimerService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  static const int _dailyScanLimit = 10;
  static const int _defaultCreditsPerBottle = 20;

  // ==================== Scan ====================

  /// Record a bottle scan and credit the user's account.
  /// Returns a result map consistent with the GuestService contract.
  Future<Map<String, dynamic>> scanBottleForUser({
    required int userId,
    String machineIdentifier = 'default_machine',
    int creditsPerBottle = _defaultCreditsPerBottle,
  }) async {
    try {
      final db = await _db.database;

      // Check daily limit
      final canScanResult = await canUserScan(userId);
      if (canScanResult['can_scan'] != true) {
        return {
          'success': false,
          'error': canScanResult['reason'] as String? ?? 'Scan limit reached',
        };
      }

      // Resolve machine
      final machineId = await _resolveMachineId(db, machineIdentifier);

      final now = DateTime.now().toIso8601String();

      // Record the bottle session
      await db.insert('bottle_sessions', {
        'user_id': userId,
        'machine_id': machineId,
        'credits_earned': creditsPerBottle,
        'session_type': 'scan',
        'created_at': now,
      });

      // Add credits to user account
      await db.rawUpdate(
        'UPDATE users SET credits = credits + ?, updated_at = ? WHERE id = ?',
        [creditsPerBottle, now, userId],
      );

      // Fetch updated total credits
      final userRows = await db.query(
        'users',
        columns: ['credits'],
        where: 'id = ?',
        whereArgs: [userId],
      );
      final totalCredits = userRows.isNotEmpty
          ? (userRows.first['credits'] as int? ?? 0)
          : 0;

      // Update machine bottle count
      if (machineId != null) {
        await db.rawUpdate(
          'UPDATE machines SET total_bottles_processed = total_bottles_processed + 1, updated_at = ? WHERE id = ?',
          [now, machineId],
        );
      }

      return {
        'success': true,
        'message': 'Bottle scanned! +$creditsPerBottle credits earned.',
        'session': {
          'credits_earned': creditsPerBottle,
          'total_credits': totalCredits,
          'session_type': 'points',
        },
      };
    } catch (e) {
      debugPrint('User scan error: $e');
      return {'success': false, 'error': 'Failed to scan bottle: $e'};
    }
  }

  // ==================== Rate Limit ====================

  /// Check whether the user has remaining scans today.
  Future<Map<String, dynamic>> canUserScan(int userId) async {
    try {
      final todayCount = await getTodayScanCount(userId);
      final canScan = todayCount < _dailyScanLimit;

      return {
        'success': true,
        'can_scan': canScan,
        'today_scans': todayCount,
        'remaining': (_dailyScanLimit - todayCount).clamp(0, _dailyScanLimit),
        if (!canScan)
          'reason': 'Daily scan limit reached ($_dailyScanLimit per day)',
      };
    } catch (e) {
      debugPrint('Can-scan check error: $e');
      return {'success': false, 'can_scan': false, 'reason': 'Check failed'};
    }
  }

  // ==================== Stats ====================

  /// Number of scans the user performed today.
  Future<int> getTodayScanCount(int userId) async {
    final db = await _db.database;
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ).toIso8601String();

    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM bottle_sessions '
            'WHERE user_id = ? AND created_at >= ?',
            [userId, todayStart],
          ),
        ) ??
        0;
  }

  /// Aggregate scan statistics for a user.
  Future<Map<String, dynamic>> getUserScanStats(int userId) async {
    final db = await _db.database;

    final totalScans =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM bottle_sessions WHERE user_id = ?',
            [userId],
          ),
        ) ??
        0;

    final totalCreditsEarned =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COALESCE(SUM(credits_earned), 0) FROM bottle_sessions '
            'WHERE user_id = ?',
            [userId],
          ),
        ) ??
        0;

    final todayCount = await getTodayScanCount(userId);

    return {
      'total_scans': totalScans,
      'total_credits_earned': totalCreditsEarned,
      'today_scans': todayCount,
      'daily_limit': _dailyScanLimit,
      'remaining': (_dailyScanLimit - todayCount).clamp(0, _dailyScanLimit),
    };
  }

  // ==================== Helpers ====================

  Future<int?> _resolveMachineId(Database db, String machineIdentifier) async {
    final parsed = int.tryParse(machineIdentifier);
    List<Map<String, dynamic>> rows;

    if (parsed != null) {
      rows = await db.query('machines', where: 'id = ?', whereArgs: [parsed]);
    } else {
      rows = await db.query(
        'machines',
        where: 'name = ?',
        whereArgs: [machineIdentifier],
      );
    }

    return rows.isNotEmpty ? (rows.first['id'] as int) : null;
  }
}
