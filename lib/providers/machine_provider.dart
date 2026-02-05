import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/machine.dart';
import '../services/api_service.dart';
import '../utils/api_exception.dart';

/// Machine monitoring state provider
class MachineProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Machine> _machines = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  MachineProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  List<Machine> get machines => _machines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get online machines
  List<Machine> get onlineMachines {
    return _machines.where((machine) => machine.isOnline).toList();
  }

  /// Get offline machines
  List<Machine> get offlineMachines {
    return _machines.where((machine) => !machine.isOnline).toList();
  }

  /// Get active machines
  List<Machine> get activeMachines {
    return _machines.where((machine) => machine.isActive).toList();
  }

  /// Fetch machine status
  Future<void> fetchMachineStatus({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _apiService.getMachineStatus();
      _machines = response.data ?? [];
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch machine status';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send heartbeat for a machine
  Future<bool> sendHeartbeat({required int machineId}) async {
    try {
      final response = await _apiService.sendMachineHeartbeat(
        machineId: machineId,
      );

      if (response.data != null) {
        // Update machine in list
        final index = _machines.indexWhere((m) => m.id == machineId);
        if (index != -1) {
          _machines[index] = response.data!;
          notifyListeners();
        }
      }

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send heartbeat';
      notifyListeners();
      return false;
    }
  }

  /// Get machine by ID
  Machine? getMachineById(int id) {
    try {
      return _machines.firstWhere((machine) => machine.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Start automatic refresh
  void startAutoRefresh({Duration interval = const Duration(minutes: 1)}) {
    _stopAutoRefresh();

    _refreshTimer = Timer.periodic(interval, (timer) async {
      await fetchMachineStatus(showLoading: false);
    });
  }

  /// Stop automatic refresh
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Get total bottle count across all machines
  int get totalBottlesProcessed {
    return _machines.fold(
      0,
      (sum, machine) => sum + machine.totalBottlesProcessed,
    );
  }

  /// Get machine health status summary
  Map<String, int> get machineHealthSummary {
    int online = 0;
    int offline = 0;
    int maintenance = 0;

    for (final machine in _machines) {
      if (machine.isOnline) {
        online++;
      } else if (machine.isInMaintenance) {
        maintenance++;
      } else {
        offline++;
      }
    }

    return {
      'online': online,
      'offline': offline,
      'maintenance': maintenance,
      'total': _machines.length,
    };
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _machines = [];
    _isLoading = false;
    _errorMessage = null;
    _stopAutoRefresh();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }
}
