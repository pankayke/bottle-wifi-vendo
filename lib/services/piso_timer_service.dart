import 'dart:async';

import 'package:flutter/foundation.dart';

/// Manages the 30-second bottle insertion countdown timer.
/// Mimics the Piso WiFi coin-slot countdown experience:
/// user inserts a bottle and has 30s for the scan to complete.
class PisoTimerService {
  PisoTimerService._();
  static final PisoTimerService instance = PisoTimerService._();

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;

  /// Current remaining seconds on the insert timer.
  int get remainingSeconds => _remainingSeconds;

  /// Whether the timer is actively counting down.
  bool get isRunning => _isRunning;

  /// Fraction of time elapsed (0.0 → 1.0).
  double get progress {
    if (_totalSeconds == 0) return 0.0;
    return 1.0 - (_remainingSeconds / _totalSeconds);
  }

  int _totalSeconds = 0;

  /// Starts the insert countdown.
  /// [durationSeconds] defaults to 30.
  /// [onTick] fires every second with the remaining time.
  /// [onComplete] fires when the timer reaches zero.
  void startInsertTimer({
    int durationSeconds = 30,
    required ValueChanged<int> onTick,
    required VoidCallback onComplete,
  }) {
    cancel();
    _totalSeconds = durationSeconds;
    _remainingSeconds = durationSeconds;
    _isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      onTick(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        _isRunning = false;
        timer.cancel();
        onComplete();
      }
    });
  }

  /// Cancels the running timer.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _remainingSeconds = 0;
  }

  /// Formats remaining seconds as MM:SS.
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
