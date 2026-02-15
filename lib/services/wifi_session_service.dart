import 'dart:async';

import 'package:flutter/foundation.dart';

/// Manages the free WiFi session countdown for guest users.
/// After a successful scan, starts a 20-minute WiFi access window.
class WifiSessionService {
  WifiSessionService._();
  static final WifiSessionService instance = WifiSessionService._();

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isActive = false;
  DateTime? _sessionStart;

  /// Whether a WiFi session is currently active.
  bool get isActive => _isActive;

  /// Current remaining seconds of the WiFi session.
  int get remainingSeconds => _remainingSeconds;

  /// Total session duration in seconds.
  int get totalSeconds => _totalSeconds;
  int _totalSeconds = 0;

  /// Progress fraction (0.0 → 1.0) of elapsed time.
  double get progress {
    if (_totalSeconds == 0) return 0.0;
    return 1.0 - (_remainingSeconds / _totalSeconds);
  }

  /// When the session started.
  DateTime? get sessionStart => _sessionStart;

  /// Starts a free WiFi session.
  /// [minutes] - how long the session lasts (default 20).
  /// [onTick] - called every second with remaining seconds.
  /// [onExpired] - called when the session is over.
  void startFreeSession({
    int minutes = 20,
    required ValueChanged<int> onTick,
    required VoidCallback onExpired,
  }) {
    stopSession();
    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
    _isActive = true;
    _sessionStart = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      onTick(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        _isActive = false;
        timer.cancel();
        onExpired();
      }
    });
  }

  /// Stops the current WiFi session.
  void stopSession() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _remainingSeconds = 0;
    _totalSeconds = 0;
    _sessionStart = null;
  }

  /// Formats remaining seconds as MM:SS.
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
