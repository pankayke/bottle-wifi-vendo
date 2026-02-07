import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceFingerprintService {
  /// Generate a unique device fingerprint
  /// This creates a stable identifier for the device without requiring authentication
  Future<String> generateFingerprint() async {
    final components = await _collectFingerprintComponents();

    // Create SHA-256 hash of components
    final input = components.values.join('|');
    final bytes = utf8.encode(input);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }

  /// Collect device-specific components for fingerprinting
  Future<Map<String, String>> _collectFingerprintComponents() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, String> components = {};

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        components = {
          'platform': 'android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'device': androidInfo.device,
          'sdk': androidInfo.version.sdkInt.toString(),
          'display': androidInfo.display,
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        components = {
          'platform': 'ios',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemVersion': iosInfo.systemVersion,
          'identifierForVendor': iosInfo.identifierForVendor ?? 'unknown',
        };
      } else if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        components = {
          'platform': 'web',
          'browser': webInfo.browserName.name,
          'userAgent': webInfo.userAgent ?? 'unknown',
          'language': webInfo.language ?? 'unknown',
          'vendor': webInfo.vendor ?? 'unknown',
        };
      } else {
        // Desktop fallback
        components = {
          'platform': defaultTargetPlatform.toString(),
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        };
      }
    } catch (e) {
      debugPrint('Error collecting fingerprint components: $e');
      // Fallback fingerprint
      components = {
        'platform': 'unknown',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };
    }

    return components;
  }

  /// Validate fingerprint format (SHA-256 = 64 hex characters)
  bool isValidFingerprint(String fingerprint) {
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(fingerprint);
  }
}
