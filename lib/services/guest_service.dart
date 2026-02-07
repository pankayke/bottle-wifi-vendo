import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import 'device_fingerprint_service.dart';

class GuestService {
  final DeviceFingerprintService _fingerprintService =
      DeviceFingerprintService();

  /// Scan a bottle as a guest user (NO authentication required)
  Future<Map<String, dynamic>> scanBottle({
    required String machineIdentifier,
    int minutesPerBottle = 30,
  }) async {
    try {
      // Generate device fingerprint
      final deviceFingerprint = await _fingerprintService.generateFingerprint();
      final deviceInfo = await _getDeviceInfo();

      // Call API
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/guest/bottle-scan'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'machine_identifier': machineIdentifier,
          'device_fingerprint': deviceFingerprint,
          'device_info': deviceInfo,
          'minutes_per_bottle': minutesPerBottle,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Success - return session details
        return data;
      } else {
        // Error
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to scan bottle',
        };
      }
    } catch (e) {
      debugPrint('Guest scan error: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  /// Get guest statistics (scans today, limits, etc.)
  Future<Map<String, dynamic>> getStats() async {
    try {
      final deviceFingerprint = await _fingerprintService.generateFingerprint();

      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/guest/stats?device_fingerprint=$deviceFingerprint',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'Failed to fetch stats'};
      }
    } catch (e) {
      debugPrint('Get stats error: $e');
      return {'success': false, 'error': 'Network error'};
    }
  }

  /// Check if device can scan (rate limits, bans, etc.)
  Future<Map<String, dynamic>> canScan() async {
    try {
      final deviceFingerprint = await _fingerprintService.generateFingerprint();

      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/guest/can-scan?device_fingerprint=$deviceFingerprint',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'can_scan': false,
          'reason': 'Unable to check scan status',
        };
      }
    } catch (e) {
      debugPrint('Can scan check error: $e');
      return {'success': false, 'can_scan': false, 'reason': 'Network error'};
    }
  }

  /// Get device info for fingerprinting
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> info = {};

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
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
      } else if (kIsWeb) {
        final webInfo = await deviceInfoPlugin.webBrowserInfo;
        info = {
          'device_name': webInfo.browserName.name,
          'device_type': 'web',
          'platform': webInfo.platform ?? 'unknown',
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return info;
  }

  /// Convert guest to registered user (optional registration)
  Future<Map<String, dynamic>> convertToRegisteredUser({
    required String deviceFingerprint,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/guest/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'device_fingerprint': deviceFingerprint,
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      debugPrint('Guest conversion error: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  /// Get preview of what guest will receive on registration
  Future<Map<String, dynamic>> getConversionPreview(
    String deviceFingerprint,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/guest/conversion-preview?device_fingerprint=$deviceFingerprint',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'error': 'Failed to fetch preview'};
      }
    } catch (e) {
      debugPrint('Conversion preview error: $e');
      return {'success': false, 'error': 'Network error'};
    }
  }

  /// Check if system should suggest registration to guest
  Future<bool> shouldSuggestRegistration(String deviceFingerprint) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/guest/should-register?device_fingerprint=$deviceFingerprint',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['should_suggest'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Should register check error: $e');
      return false;
    }
  }
}
