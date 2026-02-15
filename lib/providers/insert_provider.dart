import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/piso_timer_service.dart';
import '../services/reward_dispatcher.dart';
import '../services/wifi_session_service.dart';
import '../utils/constants.dart';

/// State phases of the bottle insertion flow.
enum InsertPhase { idle, counting, scanSuccess, wifiActive, error }

/// Manages the full insert → timer → reward lifecycle.
/// Screens observe this provider to render the correct UI phase.
class InsertProvider with ChangeNotifier {
  final PisoTimerService _pisoTimer = PisoTimerService.instance;
  final RewardDispatcher _rewardDispatcher = RewardDispatcher.instance;
  final WifiSessionService _wifiSession = WifiSessionService.instance;

  InsertPhase _phase = InsertPhase.idle;
  int _remainingSeconds = 0;
  RewardResult? _rewardResult;
  String? _errorMessage;

  // WiFi session countdown (guest only)
  int _wifiRemainingSeconds = 0;

  // ==================== Getters ====================

  InsertPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  RewardResult? get rewardResult => _rewardResult;
  String? get errorMessage => _errorMessage;
  int get wifiRemainingSeconds => _wifiRemainingSeconds;
  bool get isWifiActive => _wifiSession.isActive;

  /// Formatted insert timer string (e.g. "00:27").
  String get formattedInsertTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Formatted WiFi timer string (e.g. "19:58").
  String get formattedWifiTime {
    final m = _wifiRemainingSeconds ~/ 60;
    final s = _wifiRemainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Progress (0.0 → 1.0) of the 30s insert timer.
  double get insertProgress {
    const total = AppConstants.insertTimerSeconds;
    if (total == 0) return 0.0;
    return 1.0 - (_remainingSeconds / total);
  }

  /// Progress (0.0 → 1.0) of the WiFi session.
  double get wifiProgress => _wifiSession.progress;

  // ==================== Actions ====================

  /// Begins the 30-second bottle insertion countdown.
  /// On completion, dispatches the reward (guest = WiFi, user = credits).
  void startInsert(User? user) {
    _phase = InsertPhase.counting;
    _remainingSeconds = AppConstants.insertTimerSeconds;
    _rewardResult = null;
    _errorMessage = null;
    notifyListeners();

    _pisoTimer.startInsertTimer(
      durationSeconds: AppConstants.insertTimerSeconds,
      onTick: (remaining) {
        _remainingSeconds = remaining;
        notifyListeners();
      },
      onComplete: () async {
        await _dispatchReward(user);
      },
    );
  }

  /// Called when the 30s timer completes. Awards based on user type.
  Future<void> _dispatchReward(User? user) async {
    try {
      final result = await _rewardDispatcher.dispatch(
        user: user,
        onWifiTick: (remaining) {
          _wifiRemainingSeconds = remaining;
          notifyListeners();
        },
        onWifiExpired: () {
          _phase = InsertPhase.idle;
          _wifiRemainingSeconds = 0;
          notifyListeners();
        },
      );

      _rewardResult = result;

      if (result.isGuest) {
        _phase = InsertPhase.wifiActive;
        _wifiRemainingSeconds = AppConstants.guestFreeWifiMinutes * 60;
      } else {
        _phase = InsertPhase.scanSuccess;
      }
      notifyListeners();
    } catch (e) {
      _phase = InsertPhase.error;
      _errorMessage = 'Reward dispatch failed: $e';
      notifyListeners();
    }
  }

  /// Cancels any active timers and resets to idle.
  void reset() {
    _pisoTimer.cancel();
    _wifiSession.stopSession();
    _phase = InsertPhase.idle;
    _remainingSeconds = 0;
    _wifiRemainingSeconds = 0;
    _rewardResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pisoTimer.cancel();
    super.dispose();
  }
}
