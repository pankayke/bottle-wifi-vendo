import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/bottle_log.dart';
import '../services/api_service.dart';
import '../utils/api_exception.dart';

/// Bottle management state provider
class BottleProvider with ChangeNotifier {
  final ApiService _apiService;

  List<BottleLog> _bottleLogs = [];
  BottleStatistics? _statistics;
  bool _isLoading = false;
  bool _hasMorePages = true;
  int _currentPage = 1;
  String? _errorMessage;

  BottleProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  List<BottleLog> get bottleLogs => _bottleLogs;
  BottleStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get hasMorePages => _hasMorePages;
  String? get errorMessage => _errorMessage;

  /// Report a bottle
  Future<bool> reportBottle({
    required int machineId,
    String? imageBase64,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.reportBottle(
        machineId: machineId,
        imageBase64: imageBase64,
      );

      if (response.data != null) {
        _bottleLogs.insert(0, response.data!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to report bottle';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch bottle history
  Future<void> fetchBottleHistory({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _bottleLogs = [];
      _hasMorePages = true;
    }

    if (!_hasMorePages) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getBottleHistory(
        page: _currentPage,
        perPage: 20,
      );

      if (response.data != null) {
        _bottleLogs.addAll(response.data!);
        _currentPage++;

        // Check if there are more pages
        final meta = response.meta;
        if (meta != null) {
          final currentPage = meta['current_page'] as int?;
          final lastPage = meta['last_page'] as int?;
          _hasMorePages =
              currentPage != null && lastPage != null && currentPage < lastPage;
        }
      }

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch bottle history';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch bottle statistics
  Future<void> fetchStatistics() async {
    try {
      final response = await _apiService.getBottleStatistics();
      _statistics = response.data;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch statistics';
      notifyListeners();
    }
  }

  /// Get bottle by ID
  BottleLog? getBottleById(int id) {
    try {
      return _bottleLogs.firstWhere((bottle) => bottle.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get verified bottles
  List<BottleLog> get verifiedBottles {
    return _bottleLogs.where((bottle) => bottle.isVerified).toList();
  }

  /// Get pending bottles
  List<BottleLog> get pendingBottles {
    return _bottleLogs.where((bottle) => bottle.isPending).toList();
  }

  /// Get rejected bottles
  List<BottleLog> get rejectedBottles {
    return _bottleLogs.where((bottle) => bottle.isRejected).toList();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _bottleLogs = [];
    _statistics = null;
    _isLoading = false;
    _hasMorePages = true;
    _currentPage = 1;
    _errorMessage = null;
    notifyListeners();
  }
}
