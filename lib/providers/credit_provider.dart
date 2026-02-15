import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/internet_credit.dart';
import '../models/voucher.dart';
import '../models/wifi_session.dart';
import '../services/api_service.dart';
import '../utils/api_exception.dart';

/// Unified internet credit and session state provider.
/// Supports admin session management, user credit balance, and voucher redemption.
class CreditProvider with ChangeNotifier {
  final ApiService _apiService;

  // Admin fields
  InternetCredit? _credits;
  WifiSession? _activeSession;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _sessionTimer;

  // User fields
  int _creditBalance = 0;
  String? _successMessage;
  Voucher? _lastRedeemedVoucher;

  CreditProvider({required ApiService apiService}) : _apiService = apiService;

  // ==================== Getters ====================

  InternetCredit? get credits => _credits;
  WifiSession? get activeSession => _activeSession;
  bool get isLoading => _isLoading;
  bool get hasActiveSession => _activeSession?.isActive ?? false;
  String? get errorMessage => _errorMessage;

  // User getters
  int get creditBalance => _creditBalance;
  String? get successMessage => _successMessage;
  Voucher? get lastRedeemedVoucher => _lastRedeemedVoucher;

  /// Fetch user credits
  Future<void> fetchCredits() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.viewCredits();
      _credits = response.data;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch credits';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Request internet access
  Future<bool> requestInternet({
    required int machineId,
    required int minutes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.requestInternet(
        machineId: machineId,
        minutes: minutes,
      );

      _activeSession = response.data;
      _isLoading = false;
      notifyListeners();

      // Start session monitoring
      if (_activeSession?.isActive ?? false) {
        _startSessionTimer();
      }

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to request internet access';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch active session
  Future<void> fetchActiveSession() async {
    try {
      final response = await _apiService.getActiveSession();
      _activeSession = response.data;
      notifyListeners();

      // Start or stop session timer based on session status
      if (_activeSession?.isActive ?? false) {
        _startSessionTimer();
      } else {
        _stopSessionTimer();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch active session';
      notifyListeners();
    }
  }

  /// Start session monitoring timer
  void _startSessionTimer() {
    _stopSessionTimer();

    _sessionTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await fetchActiveSession();

      // Stop timer if session is no longer active
      if (!(_activeSession?.isActive ?? false)) {
        _stopSessionTimer();
      }
    });
  }

  /// Stop session monitoring timer
  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Get remaining session time as string
  String? get remainingTimeString {
    if (_activeSession == null || !_activeSession!.isActive) {
      return null;
    }

    final remaining = _activeSession!.remainingMinutes;
    final hours = remaining ~/ 60;
    final minutes = remaining % 60;

    if (hours > 0) {
      return '$hours hr $minutes min';
    }
    return '$minutes min';
  }

  /// Get session progress (0.0 to 1.0)
  double? get sessionProgress {
    if (_activeSession == null || !_activeSession!.isActive) {
      return null;
    }

    final total = _activeSession!.durationMinutes;
    final remaining = _activeSession!.remainingMinutes;

    if (total == 0) return 0.0;
    return 1.0 - (remaining / total);
  }

  /// Convert credits to a voucher
  Future<Map<String, dynamic>?> convertCreditsToVoucher({
    required int minutes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.convertCreditsToVoucher(
        minutes: minutes,
      );

      // Refresh credits after conversion
      await fetchCredits();

      _isLoading = false;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to convert credits to voucher';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _credits = null;
    _activeSession = null;
    _isLoading = false;
    _errorMessage = null;
    _successMessage = null;
    _creditBalance = 0;
    _lastRedeemedVoucher = null;
    _stopSessionTimer();
    notifyListeners();
  }

  // ==================== User Methods ====================

  /// Fetch simple credit balance for user screens.
  Future<void> fetchBalance() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _creditBalance = await _apiService.getCreditBalance();
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch balance';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Redeem a voucher code.
  Future<bool> redeemVoucher({required String code}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _lastRedeemedVoucher = null;
    notifyListeners();

    try {
      final response = await _apiService.redeemVoucher(code: code);

      if (response.success && response.data != null) {
        _lastRedeemedVoucher = response.data;
        _successMessage = response.message ?? 'Voucher redeemed successfully!';
        // Refresh balance after redemption
        await fetchBalance();
        notifyListeners();
        return true;
      }

      _errorMessage = response.message ?? 'Redemption failed';
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to redeem voucher';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear success/error messages.
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopSessionTimer();
    super.dispose();
  }
}
