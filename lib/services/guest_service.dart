import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'device_fingerprint_service.dart';

/// Guest service — bottle scanning and stats for unauthenticated users.
/// All operations hit the on-device SQLite database.
class GuestService {
  final DeviceFingerprintService _fingerprintService =
      DeviceFingerprintService();
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Scan a bottle as a guest user (NO authentication required).
  /// Creates a voucher for each bottle scanned.
  Future<Map<String, dynamic>> scanBottle({
    required String machineIdentifier,
    int minutesPerBottle = 20,
  }) async {
    try {
      final deviceFingerprint = await _fingerprintService.generateFingerprint();
      final deviceInfo = await _getDeviceInfo();

      final db = await _db.database;

      // Find machine by name or id
      List<Map<String, dynamic>> machineRows;
      final parsed = int.tryParse(machineIdentifier);
      if (parsed != null) {
        machineRows = await db.query(
          'machines',
          where: 'id = ?',
          whereArgs: [parsed],
        );
      } else {
        machineRows = await db.query(
          'machines',
          where: 'name = ?',
          whereArgs: [machineIdentifier],
        );
      }

      int? machineId;
      if (machineRows.isNotEmpty) {
        machineId = machineRows.first['id'] as int;
      }

      final now = DateTime.now().toIso8601String();
      final code = DatabaseHelper.generateVoucherCode();

      // Record guest scan
      await db.insert('guest_scans', {
        'device_fingerprint': deviceFingerprint,
        'device_info': deviceInfo.toString(),
        'machine_id': machineId,
        'credits_earned': minutesPerBottle,
        'created_at': now,
      });

      // Generate voucher for the guest
      await db.insert('vouchers', {
        'code': code,
        'minutes': minutesPerBottle,
        'status': 'active',
        'type': 'single_use',
        'created_at': now,
      });

      // Update machine bottle count if found
      if (machineId != null) {
        await db.rawUpdate(
          'UPDATE machines SET total_bottles_processed = total_bottles_processed + 1, updated_at = ? WHERE id = ?',
          [now, machineId],
        );
      }

      return {
        'success': true,
        'message': 'Bottle scanned successfully! Here is your voucher.',
        'session': {
          'voucher_code': code,
          'minutes_granted': minutesPerBottle,
          'expires_at': DateTime.now()
              .add(const Duration(days: 7))
              .toIso8601String(),
        },
      };
    } catch (e) {
      debugPrint('Guest scan error: $e');
      return {'success': false, 'error': 'Failed to scan bottle: $e'};
    }
  }

  /// Get guest statistics for this device.
  Future<Map<String, dynamic>> getStats() async {
    try {
      final deviceFingerprint = await _fingerprintService.generateFingerprint();
      final db = await _db.database;

      final totalScans =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM guest_scans WHERE device_fingerprint = ?',
              [deviceFingerprint],
            ),
          ) ??
          0;

      final todayStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ).toIso8601String();

      final todayScans =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM guest_scans WHERE device_fingerprint = ? AND created_at >= ?',
              [deviceFingerprint, todayStart],
            ),
          ) ??
          0;

      final totalCredits =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COALESCE(SUM(credits_earned), 0) FROM guest_scans WHERE device_fingerprint = ?',
              [deviceFingerprint],
            ),
          ) ??
          0;

      return {
        'success': true,
        'total_scans': totalScans,
        'today_scans': todayScans,
        'total_credits': totalCredits,
      };
    } catch (e) {
      debugPrint('Get stats error: $e');
      return {'success': false, 'error': 'Failed to fetch stats'};
    }
  }

  /// Check if device can scan (rate limit: 10 scans per day).
  Future<Map<String, dynamic>> canScan() async {
    try {
      final deviceFingerprint = await _fingerprintService.generateFingerprint();
      final db = await _db.database;

      final todayStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ).toIso8601String();

      final todayScans =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM guest_scans WHERE device_fingerprint = ? AND created_at >= ?',
              [deviceFingerprint, todayStart],
            ),
          ) ??
          0;

      const dailyLimit = 10;
      final canScan = todayScans < dailyLimit;

      return {
        'success': true,
        'can_scan': canScan,
        if (!canScan)
          'reason': 'Daily scan limit reached ($dailyLimit per day)',
      };
    } catch (e) {
      debugPrint('Can scan check error: $e');
      return {'success': false, 'can_scan': false, 'reason': 'Check failed'};
    }
  }

  /// Get device info for fingerprinting.
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> info = {};

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        info = {
          'device_name': webInfo.browserName.name,
          'device_type': 'web',
          'platform': webInfo.platform ?? 'unknown',
        };
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        info = {
          'device_name': androidInfo.model,
          'device_type': 'mobile',
          'platform': 'Android',
          'os_version': androidInfo.version.release,
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        info = {
          'device_name': iosInfo.name,
          'device_type': 'mobile',
          'platform': 'iOS',
          'os_version': iosInfo.systemVersion,
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return info;
  }

  /// Convert guest to registered user — transfers guest credits.
  Future<Map<String, dynamic>> convertToRegisteredUser({
    required String deviceFingerprint,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final db = await _db.database;

      // Check duplicate email
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );
      if (existing.isNotEmpty) {
        return {'success': false, 'error': 'Email is already registered'};
      }

      // Calculate total guest credits
      final totalCredits =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COALESCE(SUM(credits_earned), 0) FROM guest_scans WHERE device_fingerprint = ?',
              [deviceFingerprint],
            ),
          ) ??
          0;

      final now = DateTime.now().toIso8601String();

      // Create user account with accumulated credits
      final userId = await db.insert('users', {
        'name': name,
        'email': email.toLowerCase(),
        'password_hash': DatabaseHelper.hashPassword(password),
        'credits': totalCredits,
        'role': 'user',
        'last_login_at': now,
        'created_at': now,
        'updated_at': now,
      });

      final userRow = (await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      )).first;

      return {
        'success': true,
        'data': {
          'token': 'local_auth_$userId',
          'user': userRow,
          'credits_transferred': totalCredits,
        },
      };
    } catch (e) {
      debugPrint('Guest conversion error: $e');
      return {'success': false, 'error': 'Registration failed: $e'};
    }
  }

  /// Get preview of what guest will receive on registration.
  Future<Map<String, dynamic>> getConversionPreview(
    String deviceFingerprint,
  ) async {
    try {
      final db = await _db.database;

      final totalScans =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM guest_scans WHERE device_fingerprint = ?',
              [deviceFingerprint],
            ),
          ) ??
          0;
      final totalCredits =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COALESCE(SUM(credits_earned), 0) FROM guest_scans WHERE device_fingerprint = ?',
              [deviceFingerprint],
            ),
          ) ??
          0;

      return {
        'success': true,
        'total_scans': totalScans,
        'total_credits': totalCredits,
        'message':
            'Your $totalScans scans ($totalCredits credits) will be transferred to your new account.',
      };
    } catch (e) {
      debugPrint('Conversion preview error: $e');
      return {'success': false, 'error': 'Failed to fetch preview'};
    }
  }

  /// Check if system should suggest registration to guest.
  Future<bool> shouldSuggestRegistration(String deviceFingerprint) async {
    try {
      final db = await _db.database;
      final scanCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM guest_scans WHERE device_fingerprint = ?',
              [deviceFingerprint],
            ),
          ) ??
          0;
      // Suggest registration after 3 scans
      return scanCount >= 3;
    } catch (e) {
      debugPrint('Should register check error: $e');
      return false;
    }
  }
}
