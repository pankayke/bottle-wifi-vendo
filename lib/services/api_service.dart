import 'package:sqflite/sqflite.dart';
import '../models/api_response.dart';
import '../models/bottle_log.dart';
import '../models/internet_credit.dart';
import '../models/machine.dart';
import '../models/user.dart';
import '../models/wifi_session.dart';
import '../utils/api_exception.dart';
import '../utils/constants.dart';
import 'database_helper.dart';
import 'storage_service.dart';

/// Local API service — all operations run against the on-device SQLite database.
/// Method signatures are identical to the original HTTP-based service so that
/// providers and screens continue to work without modification.
class ApiService {
  final StorageService _storageService;
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Constructor kept compatible with existing callers.
  ApiService({required StorageService storageService, String? baseUrl})
    : _storageService = storageService;

  // ==================== Authentication ====================

  /// Register a new user
  Future<ApiResponse<User>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      if (password != passwordConfirmation) {
        throw ApiException.validationError('Passwords do not match');
      }
      if (password.length < AppConstants.minPasswordLength) {
        throw ApiException.validationError(
          'Password must be at least ${AppConstants.minPasswordLength} characters',
        );
      }

      final db = await _db.database;

      // Check for duplicate email
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );
      if (existing.isNotEmpty) {
        throw ApiException.validationError(
          'An account with this email already exists',
        );
      }

      final now = DateTime.now().toIso8601String();
      final id = await db.insert('users', {
        'name': name,
        'email': email.toLowerCase(),
        'password_hash': DatabaseHelper.hashPassword(password),
        'credits': 0,
        'role': 'user',
        'last_login_at': now,
        'created_at': now,
        'updated_at': now,
      });

      final userRow = (await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      )).first;

      final user = User.fromJson(userRow);
      await _storageService.saveToken('local_auth_$id');
      await _storageService.saveUser(user);

      return ApiResponse<User>(
        success: true,
        message: 'Registration successful',
        data: user,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Registration failed: $e', statusCode: null);
    }
  }

  /// Login user
  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'users',
        where: 'email = ? AND password_hash = ?',
        whereArgs: [email.toLowerCase(), DatabaseHelper.hashPassword(password)],
      );

      if (rows.isEmpty) {
        throw ApiException.validationError('Invalid email or password');
      }

      final userRow = rows.first;

      // Check suspension
      if (userRow['suspended_at'] != null) {
        final reason = userRow['suspension_reason'] as String? ?? 'No reason';
        throw ApiException(
          message: 'Account suspended: $reason',
          statusCode: 403,
        );
      }

      // Update last login
      final now = DateTime.now().toIso8601String();
      await db.update(
        'users',
        {'last_login_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [userRow['id']],
      );

      final updatedRow = (await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userRow['id']],
      )).first;

      final user = User.fromJson(updatedRow);
      await _storageService.saveToken('local_auth_${user.id}');
      await _storageService.saveUser(user);

      return ApiResponse<User>(
        success: true,
        message: 'Login successful',
        data: user,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Login failed: $e', statusCode: null);
    }
  }

  /// Forgot password — resets to the default password 'password'.
  Future<void> forgotPassword({required String email}) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (rows.isEmpty) {
      throw ApiException.validationError('No account found with this email');
    }
    await db.update(
      'users',
      {
        'password_hash': DatabaseHelper.hashPassword('password'),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
  }

  /// Convert user credits to a WiFi voucher
  Future<Map<String, dynamic>> convertCreditsToVoucher({
    required int minutes,
  }) async {
    final db = await _db.database;
    final currentUser = await _storageService.getUser();
    if (currentUser == null) throw ApiException.unauthorized();

    // Refresh credits from DB
    final userRow = (await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [currentUser.id],
    )).first;
    final availableCredits = userRow['credits'] as int? ?? 0;

    if (availableCredits < minutes) {
      throw ApiException.validationError(
        'Not enough credits. Available: $availableCredits',
      );
    }

    final now = DateTime.now().toIso8601String();
    final code = DatabaseHelper.generateVoucherCode();

    // Deduct credits
    await db.rawUpdate(
      'UPDATE users SET credits = credits - ?, updated_at = ? WHERE id = ?',
      [minutes, now, currentUser.id],
    );

    // Create voucher
    final voucherId = await db.insert('vouchers', {
      'code': code,
      'minutes': minutes,
      'status': 'active',
      'type': 'single_use',
      'created_at': now,
    });

    // Refresh user in storage
    final refreshedUser = (await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [currentUser.id],
    )).first;
    await _storageService.saveUser(User.fromJson(refreshedUser));

    return {
      'voucher': {
        'id': voucherId,
        'code': code,
        'minutes': minutes,
        'status': 'active',
        'created_at': now,
      },
    };
  }

  /// Logout user
  Future<ApiResponse<void>> logout() async {
    await _storageService.clearAll();
    return ApiResponse<void>(success: true, message: 'Logged out');
  }

  // ==================== Bottle Operations ====================

  /// Report a bottle (scan)
  Future<ApiResponse<BottleLog>> reportBottle({
    required int machineId,
    String? imageBase64,
  }) async {
    try {
      final db = await _db.database;
      final currentUser = await _storageService.getUser();
      if (currentUser == null) throw ApiException.unauthorized();

      // Verify machine exists
      final machineRows = await db.query(
        'machines',
        where: 'id = ?',
        whereArgs: [machineId],
      );
      if (machineRows.isEmpty) {
        throw ApiException.validationError('Machine not found');
      }
      final machineName = machineRows.first['name'] as String?;

      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      const creditsPerBottle = 1;

      // Insert bottle log
      final logId = await db.insert('bottle_logs', {
        'user_id': currentUser.id,
        'machine_id': machineId,
        'machine_name': machineName,
        'credits_awarded': creditsPerBottle,
        'image_url': imageBase64,
        'status': 'verified',
        'timestamp': nowStr,
        'created_at': nowStr,
      });

      // Update user credits
      await db.rawUpdate(
        'UPDATE users SET credits = credits + ?, updated_at = ? WHERE id = ?',
        [creditsPerBottle, nowStr, currentUser.id],
      );

      // Update machine bottle count
      await db.rawUpdate(
        'UPDATE machines SET total_bottles_processed = total_bottles_processed + 1, updated_at = ? WHERE id = ?',
        [nowStr, machineId],
      );

      final bottleLog = BottleLog(
        id: logId,
        userId: currentUser.id,
        machineId: machineId,
        machineName: machineName,
        creditsAwarded: creditsPerBottle,
        imageUrl: imageBase64,
        status: 'verified',
        timestamp: now,
        createdAt: now,
      );

      return ApiResponse<BottleLog>(
        success: true,
        message: 'Bottle reported successfully',
        data: bottleLog,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to report bottle: $e',
        statusCode: null,
      );
    }
  }

  /// Get bottle history
  Future<ApiResponse<List<BottleLog>>> getBottleHistory({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final db = await _db.database;
      final currentUser = await _storageService.getUser();
      if (currentUser == null) throw ApiException.unauthorized();

      final offset = (page - 1) * perPage;

      final rows = await db.query(
        'bottle_logs',
        where: 'user_id = ?',
        whereArgs: [currentUser.id],
        orderBy: 'created_at DESC',
        limit: perPage,
        offset: offset,
      );

      final totalCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM bottle_logs WHERE user_id = ?',
              [currentUser.id],
            ),
          ) ??
          0;

      final logs = rows.map((r) => BottleLog.fromJson(r)).toList();
      final lastPage = (totalCount / perPage).ceil();

      return ApiResponse<List<BottleLog>>(
        success: true,
        data: logs,
        meta: {
          'current_page': page,
          'last_page': lastPage < 1 ? 1 : lastPage,
          'total': totalCount,
        },
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch bottle history: $e',
        statusCode: null,
      );
    }
  }

  /// Get bottle statistics
  Future<ApiResponse<BottleStatistics>> getBottleStatistics() async {
    try {
      final db = await _db.database;
      final currentUser = await _storageService.getUser();
      if (currentUser == null) throw ApiException.unauthorized();

      final uid = currentUser.id;
      final weekAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .toIso8601String();
      final monthAgo = DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String();

      int cnt(List<Map<String, dynamic>> r) => Sqflite.firstIntValue(r) ?? 0;

      final total = cnt(
        await db.rawQuery(
          'SELECT COUNT(*) FROM bottle_logs WHERE user_id = ?',
          [uid],
        ),
      );
      final verified = cnt(
        await db.rawQuery(
          "SELECT COUNT(*) FROM bottle_logs WHERE user_id = ? AND status = 'verified'",
          [uid],
        ),
      );
      final pending = cnt(
        await db.rawQuery(
          "SELECT COUNT(*) FROM bottle_logs WHERE user_id = ? AND status = 'pending'",
          [uid],
        ),
      );
      final rejected = cnt(
        await db.rawQuery(
          "SELECT COUNT(*) FROM bottle_logs WHERE user_id = ? AND status = 'rejected'",
          [uid],
        ),
      );
      final creditsEarned =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COALESCE(SUM(credits_awarded), 0) FROM bottle_logs WHERE user_id = ?',
              [uid],
            ),
          ) ??
          0;
      final thisWeek = cnt(
        await db.rawQuery(
          'SELECT COUNT(*) FROM bottle_logs WHERE user_id = ? AND created_at >= ?',
          [uid, weekAgo],
        ),
      );
      final thisMonth = cnt(
        await db.rawQuery(
          'SELECT COUNT(*) FROM bottle_logs WHERE user_id = ? AND created_at >= ?',
          [uid, monthAgo],
        ),
      );

      final stats = BottleStatistics(
        totalBottles: total,
        verifiedBottles: verified,
        pendingBottles: pending,
        rejectedBottles: rejected,
        totalCreditsEarned: creditsEarned,
        thisWeekBottles: thisWeek,
        thisMonthBottles: thisMonth,
      );

      return ApiResponse<BottleStatistics>(success: true, data: stats);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch statistics: $e',
        statusCode: null,
      );
    }
  }

  // ==================== Internet / Credits ====================

  /// Request internet access (deducts credits, for record keeping).
  Future<ApiResponse<WifiSession>> requestInternet({
    required int machineId,
    required int minutes,
  }) async {
    try {
      final db = await _db.database;
      final currentUser = await _storageService.getUser();
      if (currentUser == null) throw ApiException.unauthorized();

      final userRow = (await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [currentUser.id],
      )).first;
      final available = userRow['credits'] as int? ?? 0;
      if (available < minutes) {
        throw ApiException.validationError('Not enough credits');
      }

      final now = DateTime.now();
      await db.rawUpdate(
        'UPDATE users SET credits = credits - ?, updated_at = ? WHERE id = ?',
        [minutes, now.toIso8601String(), currentUser.id],
      );

      // Refresh user in storage
      final refreshedRow = (await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [currentUser.id],
      )).first;
      await _storageService.saveUser(User.fromJson(refreshedRow));

      final session = WifiSession(
        id: 0,
        userId: currentUser.id,
        machineId: machineId,
        startTime: now,
        endTime: now.add(Duration(minutes: minutes)),
        durationMinutes: minutes,
        status: 'active',
      );

      return ApiResponse<WifiSession>(
        success: true,
        message: 'Internet session started',
        data: session,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to start session: $e',
        statusCode: null,
      );
    }
  }

  /// View user credits
  Future<ApiResponse<InternetCredit>> viewCredits() async {
    try {
      final db = await _db.database;
      final currentUser = await _storageService.getUser();
      if (currentUser == null) throw ApiException.unauthorized();

      final userRow = (await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [currentUser.id],
      )).first;

      final totalCredits = userRow['credits'] as int? ?? 0;
      final totalEarned =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COALESCE(SUM(credits_awarded), 0) FROM bottle_logs WHERE user_id = ?',
              [currentUser.id],
            ),
          ) ??
          0;
      final used = totalEarned > totalCredits ? totalEarned - totalCredits : 0;

      final credits = InternetCredit(
        totalMinutes: totalEarned,
        usedMinutes: used,
        remainingMinutes: totalCredits,
        isActive: totalCredits > 0,
      );

      return ApiResponse<InternetCredit>(success: true, data: credits);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch credits: $e',
        statusCode: null,
      );
    }
  }

  /// Get active session — standalone mode has no persistent sessions.
  Future<ApiResponse<WifiSession?>> getActiveSession() async {
    return ApiResponse<WifiSession?>(success: true, data: null);
  }

  // ==================== Machines ====================

  /// Get machine status
  Future<ApiResponse<List<Machine>>> getMachineStatus() async {
    try {
      final db = await _db.database;
      final rows = await db.query('machines', orderBy: 'created_at DESC');
      final machines = rows
          .map((r) => Machine.fromJson(DatabaseHelper.machineRowToJson(r)))
          .toList();

      return ApiResponse<List<Machine>>(success: true, data: machines);
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch machines: $e',
        statusCode: null,
      );
    }
  }

  /// Send machine heartbeat (mark as online).
  Future<ApiResponse<Machine>> sendMachineHeartbeat({
    required int machineId,
  }) async {
    try {
      final db = await _db.database;
      final now = DateTime.now().toIso8601String();
      await db.update(
        'machines',
        {'is_online': 1, 'last_online': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [machineId],
      );
      final row = (await db.query(
        'machines',
        where: 'id = ?',
        whereArgs: [machineId],
      )).first;
      final machine = Machine.fromJson(DatabaseHelper.machineRowToJson(row));
      return ApiResponse<Machine>(success: true, data: machine);
    } catch (e) {
      throw ApiException(message: 'Heartbeat failed: $e', statusCode: null);
    }
  }

  // ==================== User Profile ====================

  /// Get user profile
  Future<ApiResponse<User>> getUserProfile() async {
    try {
      final db = await _db.database;
      final currentUser = await _storageService.getUser();
      if (currentUser == null) throw ApiException.unauthorized();

      final rows = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [currentUser.id],
      );
      if (rows.isEmpty) throw ApiException.unauthorized();

      final user = User.fromJson(rows.first);
      await _storageService.saveUser(user);

      return ApiResponse<User>(success: true, data: user);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch profile: $e',
        statusCode: null,
      );
    }
  }

  /// Update user profile
  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final db = await _db.database;
      final currentUser = await _storageService.getUser();
      if (currentUser == null) throw ApiException.unauthorized();

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email.toLowerCase();
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;

      await db.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [currentUser.id],
      );

      final row = (await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [currentUser.id],
      )).first;
      final user = User.fromJson(row);
      await _storageService.saveUser(user);

      return ApiResponse<User>(success: true, data: user);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to update profile: $e',
        statusCode: null,
      );
    }
  }

  /// Change user password
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      if (newPassword != newPasswordConfirmation) {
        throw ApiException.validationError('Passwords do not match');
      }

      final db = await _db.database;
      final currentUser = await _storageService.getUser();
      if (currentUser == null) throw ApiException.unauthorized();

      // Verify current password
      final rows = await db.query(
        'users',
        where: 'id = ? AND password_hash = ?',
        whereArgs: [
          currentUser.id,
          DatabaseHelper.hashPassword(currentPassword),
        ],
      );
      if (rows.isEmpty) {
        throw ApiException.validationError('Current password is incorrect');
      }

      await db.update(
        'users',
        {
          'password_hash': DatabaseHelper.hashPassword(newPassword),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [currentUser.id],
      );

      return ApiResponse<void>(
        success: true,
        message: 'Password changed successfully',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to change password: $e',
        statusCode: null,
      );
    }
  }
}
