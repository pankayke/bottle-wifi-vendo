import 'package:flutter/foundation.dart';

import '../../services/piso_timer_service.dart';

/// Starts the 30-second bottle insertion countdown.
/// Returns a stream-like callback interface via [onTick] / [onComplete].
class StartInsertTimerUseCase {
  final PisoTimerService _timerService = PisoTimerService.instance;

  /// Executes the 30s countdown.
  /// [onTick] fires every second with remaining time.
  /// [onComplete] fires when timer reaches zero → ready for reward.
  void execute({
    int durationSeconds = 30,
    required ValueChanged<int> onTick,
    required VoidCallback onComplete,
  }) {
    _timerService.startInsertTimer(
      durationSeconds: durationSeconds,
      onTick: onTick,
      onComplete: onComplete,
    );
  }

  /// Cancels the active timer.
  void cancel() {
    _timerService.cancel();
  }
}
