import 'package:flutter/foundation.dart';
import '../models/bottle_log.dart';
import '../models/machine.dart';
import '../models/user.dart';
import '../models/voucher.dart';
import '../services/admin_api_service.dart';
import '../utils/api_exception.dart';

/// Admin state provider for the admin panel
class AdminProvider with ChangeNotifier {
  final AdminApiService _adminApiService;

  AdminProvider({required AdminApiService adminApiService})
    : _adminApiService = adminApiService;

  // ==================== State ====================

  bool _isLoading = false;
  String? _errorMessage;

  // Dashboard
  AdminDashboardStats? _dashboardStats;

  // Machines
  List<Machine> _machines = [];
  List<Machine> _offlineMachines = [];

  // Users
  List<User> _users = [];
  String _userSearchQuery = '';

  // Vouchers
  List<Voucher> _vouchers = [];

  // Analytics
  List<BottleLog> _bottleLogs = [];

  // ==================== Getters ====================

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AdminDashboardStats? get dashboardStats => _dashboardStats;

  List<Machine> get machines => _machines;
  List<Machine> get offlineMachines => _offlineMachines;
  int get activeMachineCount => _machines.where((m) => m.isOnline).length;

  List<User> get users => _users;
  String get userSearchQuery => _userSearchQuery;
  List<User> get filteredUsers {
    if (_userSearchQuery.isEmpty) return _users;
    final query = _userSearchQuery.toLowerCase();
    return _users.where((u) {
      return u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query);
    }).toList();
  }

  List<Voucher> get vouchers => _vouchers;
  List<Voucher> get activeVouchers =>
      _vouchers.where((v) => v.isActive).toList();
  List<Voucher> get redeemedVouchers =>
      _vouchers.where((v) => v.isRedeemed).toList();

  List<BottleLog> get bottleLogs => _bottleLogs;

  // ==================== Dashboard ====================

  Future<void> loadDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardStats = await _adminApiService.getDashboardStats();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load dashboard stats';
      debugPrint('Dashboard error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Machines ====================

  Future<void> loadMachines() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _machines = await _adminApiService.getAllMachines();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load machines';
      debugPrint('Load machines error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMachine({
    required String name,
    required String location,
    String? macAddress,
    String? ipAddress,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final machine = await _adminApiService.createMachine(
        name: name,
        location: location,
        macAddress: macAddress,
        ipAddress: ipAddress,
      );
      _machines.insert(0, machine);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create machine';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMachineStatus(int machineId, String status) async {
    try {
      await _adminApiService.updateMachineStatus(machineId, status);
      final index = _machines.indexWhere((m) => m.id == machineId);
      if (index != -1) {
        // Reload machines to get updated data
        await loadMachines();
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update machine status';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMachine(int machineId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminApiService.deleteMachine(machineId);
      _machines.removeWhere((m) => m.id == machineId);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete machine';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadOfflineMachines() async {
    try {
      _offlineMachines = await _adminApiService.getOfflineMachines();
      notifyListeners();
    } catch (e) {
      debugPrint('Load offline machines error: $e');
    }
  }

  // ==================== Users ====================

  Future<void> loadUsers({String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _adminApiService.getAllUsers(search: search);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load users';
      debugPrint('Load users error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setUserSearchQuery(String query) {
    _userSearchQuery = query;
    notifyListeners();
  }

  Future<bool> suspendUser(int userId, String reason) async {
    try {
      await _adminApiService.suspendUser(userId, reason);
      await loadUsers();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to suspend user';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resumeUser(int userId) async {
    try {
      await _adminApiService.resumeUser(userId);
      await loadUsers();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to resume user';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      await _adminApiService.deleteUser(userId);
      _users.removeWhere((u) => u.id == userId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete user';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetUserPassword(int userId) async {
    try {
      await _adminApiService.resetUserPassword(userId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to reset password';
      notifyListeners();
      return false;
    }
  }

  Future<bool> adjustCredits(int userId, int amount, String reason) async {
    try {
      await _adminApiService.adjustCredits(userId, amount, reason);
      await loadUsers();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to adjust credits';
      notifyListeners();
      return false;
    }
  }

  // ==================== Vouchers ====================

  Future<void> loadVouchers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vouchers = await _adminApiService.getVouchers();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load vouchers';
      debugPrint('Load vouchers error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Voucher?> generateVoucher({
    required int minutes,
    String type = 'single_use',
    int count = 1,
    DateTime? expiresAt,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final voucher = await _adminApiService.generateVoucher(
        minutes: minutes,
        type: type,
        count: count,
        expiresAt: expiresAt,
      );
      _vouchers.insert(0, voucher);
      _isLoading = false;
      notifyListeners();
      return voucher;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to generate voucher';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> revokeVoucher(int voucherId, {required String reason}) async {
    try {
      await _adminApiService.revokeVoucher(voucherId, reason: reason);
      await loadVouchers();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to revoke voucher';
      notifyListeners();
      return false;
    }
  }

  /// Convert user credits to a WiFi voucher
  Future<Voucher?> convertCreditsToVoucher({
    required int userId,
    required int minutes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Deduct credits from user
      await _adminApiService.adjustCredits(
        userId,
        -minutes,
        'Converted $minutes credit minutes to WiFi voucher',
      );

      // 2. Generate voucher with those minutes
      final voucher = await _adminApiService.generateVoucher(
        minutes: minutes,
        type: 'single_use',
      );

      _vouchers.insert(0, voucher);
      await loadUsers();
      _isLoading = false;
      notifyListeners();
      return voucher;
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

  // ==================== Analytics ====================

  Future<void> loadBottleLogs({
    int? machineId,
    DateTime? from,
    DateTime? to,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bottleLogs = await _adminApiService.getBottleLogs(
        machineId: machineId,
        from: from,
        to: to,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load bottle logs';
      debugPrint('Load bottle logs error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Utilities ====================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
