import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';

/// Service to queue API requests when offline and retry when connection restored
class OfflineQueueService {
  static const String _queueKey = 'offline_request_queue';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);

  final ApiService _apiService;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isProcessingQueue = false;

  OfflineQueueService(this._apiService);

  /// Initialize connectivity listener
  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      if (result != ConnectivityResult.none) {
        processQueue();
      }
    });
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Add request to offline queue
  Future<void> queueRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey);
    final List<dynamic> queue = queueJson != null ? jsonDecode(queueJson) : [];

    queue.add({
      'endpoint': endpoint,
      'method': method,
      'body': body,
      'headers': headers,
      'timestamp': DateTime.now().toIso8601String(),
      'retries': 0,
    });

    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  /// Process queued requests
  Future<void> processQueue() async {
    if (_isProcessingQueue) return;

    _isProcessingQueue = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson == null || queueJson.isEmpty) {
        _isProcessingQueue = false;
        return;
      }

      final List<dynamic> queue = jsonDecode(queueJson);
      final List<dynamic> failedRequests = [];

      for (var request in queue) {
        try {
          // Check connectivity before each request
          final connectivityResult = await _connectivity.checkConnectivity();
          if (connectivityResult == ConnectivityResult.none) {
            failedRequests.addAll(queue);
            break;
          }

          // Execute request based on method
          final String method = request['method'];
          final String endpoint = request['endpoint'];
          final Map<String, dynamic>? body = request['body'] != null
              ? Map<String, dynamic>.from(request['body'])
              : null;

          if (method == 'POST') {
            await _apiService.post(endpoint, body: body);
          } else if (method == 'PUT') {
            await _apiService.put(endpoint, body: body);
          } else if (method == 'DELETE') {
            await _apiService.delete(endpoint);
          }

          // Request successful, don't add to failed list
        } catch (e) {
          // Increment retry count
          request['retries'] = (request['retries'] ?? 0) + 1;

          // Only re-queue if below max retries
          if (request['retries'] < _maxRetries) {
            failedRequests.add(request);
          }
        }

        // Small delay between requests
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Update queue with failed requests
      if (failedRequests.isEmpty) {
        await prefs.remove(_queueKey);
      } else {
        await prefs.setString(_queueKey, jsonEncode(failedRequests));
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Get number of queued requests
  Future<int> getQueueLength() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey);

    if (queueJson == null || queueJson.isEmpty) {
      return 0;
    }

    final List<dynamic> queue = jsonDecode(queueJson);
    return queue.length;
  }

  /// Clear all queued requests
  Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}
