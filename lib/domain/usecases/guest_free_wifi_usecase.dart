import 'package:flutter/foundation.dart';

import '../../services/wifi_session_service.dart';
import '../../utils/constants.dart';

/// Starts a free 20-minute WiFi session for guest users.
class GuestFreeWifiUseCase {
  final WifiSessionService _wifiService = WifiSessionService.instance;

  /// Executes the free WiFi grant.
  /// [onTick] fires every second with remaining seconds.
  /// [onExpired] fires when the session ends.
  void execute({
    int minutes = AppConstants.guestFreeWifiMinutes,
    required ValueChanged<int> onTick,
    required VoidCallback onExpired,
  }) {
    _wifiService.startFreeSession(
      minutes: minutes,
      onTick: onTick,
      onExpired: onExpired,
    );
  }

  /// Stops the active WiFi session.
  void stop() {
    _wifiService.stopSession();
  }
}
