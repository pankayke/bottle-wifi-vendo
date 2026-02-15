import 'package:flutter/foundation.dart';

import '../utils/constants.dart';
import 'database_helper.dart';

/// Manages user credit operations: add, deduct, convert to voucher.
class CreditService {
  CreditService._();
  static final CreditService instance = CreditService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Adds [amount] credits to the user's account.
  Future<int> addCredits({required int userId, int amount = 20}) async {
    try {
      final db = await _db.database;
      final now = DateTime.now().toIso8601String();

      await db.rawUpdate(
        'UPDATE users SET credits = credits + ?, updated_at = ? WHERE id = ?',
        [amount, now, userId],
      );

      return await fetchBalance(userId);
    } catch (e) {
      debugPrint('CreditService.addCredits error: $e');
      rethrow;
    }
  }

  /// Fetches the current credit balance for [userId].
  Future<int> fetchBalance(int userId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'users',
        columns: ['credits'],
        where: 'id = ?',
        whereArgs: [userId],
      );
      if (rows.isEmpty) return 0;
      return (rows.first['credits'] as int?) ?? 0;
    } catch (e) {
      debugPrint('CreditService.fetchBalance error: $e');
      return 0;
    }
  }

  /// Converts [creditsToSpend] into a WiFi voucher.
  /// 1 credit = 1 minute (ratio from [AppConstants.creditsToMinutesRatio]).
  /// Returns the voucher code or null on failure.
  Future<String?> convertToVoucher({
    required int userId,
    required int creditsToSpend,
  }) async {
    try {
      if (creditsToSpend < AppConstants.minCreditsToConvert) {
        debugPrint(
          'Minimum ${AppConstants.minCreditsToConvert} credits required',
        );
        return null;
      }

      final wifiMinutes = creditsToSpend * AppConstants.creditsToMinutesRatio;
      final db = await _db.database;
      final balance = await fetchBalance(userId);

      if (balance < creditsToSpend) {
        debugPrint('Insufficient credits: $balance < $creditsToSpend');
        return null;
      }

      final now = DateTime.now().toIso8601String();
      final code = DatabaseHelper.generateVoucherCode();

      // Deduct credits
      await db.rawUpdate(
        'UPDATE users SET credits = credits - ?, updated_at = ? WHERE id = ?',
        [creditsToSpend, now, userId],
      );

      // Create voucher
      await db.insert('vouchers', {
        'code': code,
        'minutes': wifiMinutes,
        'status': 'active',
        'type': 'single_use',
        'user_id': userId,
        'created_at': now,
      });

      return code;
    } catch (e) {
      debugPrint('CreditService.convertToVoucher error: $e');
      return null;
    }
  }
}
