import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../utils/constants.dart';
import 'credit_service.dart';
import 'wifi_session_service.dart';

/// Reward result after a successful bottle scan.
class RewardResult {
  final bool isGuest;
  final int wifiMinutes;
  final int creditsEarned;
  final int totalCredits;
  final String message;

  const RewardResult({
    required this.isGuest,
    this.wifiMinutes = 0,
    this.creditsEarned = 0,
    this.totalCredits = 0,
    required this.message,
  });
}

/// Dispatches the correct reward based on user authentication state.
///   - Guest (null user): Start 20-minute free WiFi session.
///   - Logged-in user: Add 20 credits to account.
class RewardDispatcher {
  RewardDispatcher._();
  static final RewardDispatcher instance = RewardDispatcher._();

  final CreditService _creditService = CreditService.instance;
  final WifiSessionService _wifiService = WifiSessionService.instance;

  /// Dispatches the reward.
  /// [user] is null for guests.
  /// [onWifiTick] / [onWifiExpired] are required for guest WiFi flow.
  Future<RewardResult> dispatch({
    User? user,
    ValueChanged<int>? onWifiTick,
    VoidCallback? onWifiExpired,
  }) async {
    if (user == null) {
      return _dispatchGuestReward(onTick: onWifiTick, onExpired: onWifiExpired);
    }
    return _dispatchUserReward(user);
  }

  /// Guest: start free 20-minute WiFi session.
  RewardResult _dispatchGuestReward({
    ValueChanged<int>? onTick,
    VoidCallback? onExpired,
  }) {
    const minutes = AppConstants.guestFreeWifiMinutes;

    _wifiService.startFreeSession(
      minutes: minutes,
      onTick: onTick ?? (_) {},
      onExpired: onExpired ?? () {},
    );

    return const RewardResult(
      isGuest: true,
      wifiMinutes: minutes,
      message: '$minutes Minutes FREE WiFi Unlocked!',
    );
  }

  /// User: add 20 credits.
  Future<RewardResult> _dispatchUserReward(User user) async {
    const credits = AppConstants.creditsPerBottle;

    try {
      final totalCredits = await _creditService.addCredits(
        userId: user.id,
        amount: credits,
      );

      return RewardResult(
        isGuest: false,
        creditsEarned: credits,
        totalCredits: totalCredits,
        message: '+$credits Credits Earned!',
      );
    } catch (e) {
      debugPrint('RewardDispatcher user reward error: $e');
      return const RewardResult(
        isGuest: false,
        creditsEarned: 0,
        message: 'Failed to add credits. Please try again.',
      );
    }
  }
}
