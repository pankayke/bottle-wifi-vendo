import 'package:sentry_flutter/sentry_flutter.dart';

/// Service for monitoring application performance and errors
class MonitoringService {
  /// Tracks API response time and reports to Sentry
  static Future<T> trackApiCall<T>({
    required String endpoint,
    required String method,
    required Future<T> Function() operation,
  }) async {
    final transaction = Sentry.startTransaction(
      'api.$method.$endpoint',
      'http.client',
    );

    try {
      final span = transaction.startChild(
        'http.client',
        description: '$method $endpoint',
      );

      span.setData('http.method', method);
      span.setData('http.url', endpoint);

      final startTime = DateTime.now();
      final result = await operation();
      final duration = DateTime.now().difference(startTime);

      span.setData('http.response_time_ms', duration.inMilliseconds);
      span.status = const SpanStatus.ok();

      await span.finish();

      // Add breadcrumb for successful API call
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'API call successful: $method $endpoint',
          category: 'http',
          level: SentryLevel.info,
          data: {'duration_ms': duration.inMilliseconds, 'status': 'success'},
        ),
      );

      // Alert if response time is too slow (>2 seconds)
      if (duration.inSeconds > 2) {
        Sentry.captureMessage(
          'Slow API Response: $method $endpoint took ${duration.inSeconds}s',
          level: SentryLevel.warning,
        );
      }

      return result;
    } catch (error, stackTrace) {
      transaction.status = const SpanStatus.internalError();

      // Track failed API call
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({'endpoint': endpoint, 'method': method}),
      );

      // Add breadcrumb for failed API call
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'API call failed: $method $endpoint',
          category: 'http',
          level: SentryLevel.error,
          data: {'error': error.toString()},
        ),
      );

      rethrow;
    } finally {
      await transaction.finish();
    }
  }

  /// Tracks authentication attempts
  static Future<void> trackAuthenticationAttempt({
    required String username,
    required bool success,
    String? errorMessage,
  }) async {
    if (success) {
      // Track successful authentication
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'User logged in successfully',
          category: 'auth',
          level: SentryLevel.info,
          data: {'username': username},
        ),
      );

      // Set user context for future events
      await Sentry.configureScope(
        (scope) => scope.setUser(SentryUser(username: username)),
      );
    } else {
      // Track failed authentication attempt
      await Sentry.captureMessage(
        'Failed login attempt for user: $username',
        level: SentryLevel.warning,
      );

      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Login failed',
          category: 'auth',
          level: SentryLevel.warning,
          data: {
            'username': username,
            'error': errorMessage ?? 'Unknown error',
          },
        ),
      );
    }
  }

  /// Tracks logout events
  static Future<void> trackLogout(String username) async {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: 'User logged out',
        category: 'auth',
        level: SentryLevel.info,
        data: {'username': username},
      ),
    );

    // Clear user context
    await Sentry.configureScope((scope) => scope.setUser(null));
  }

  /// Tracks custom events
  static Future<void> trackEvent({
    required String name,
    Map<String, dynamic>? properties,
    SentryLevel level = SentryLevel.info,
  }) async {
    await Sentry.captureMessage(name, level: level);

    Sentry.addBreadcrumb(
      Breadcrumb(
        message: name,
        category: 'custom',
        level: level,
        data: properties,
      ),
    );
  }

  /// Tracks network connectivity changes
  static void trackConnectivityChange({
    required bool isConnected,
    String? connectionType,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: isConnected
            ? 'Network connection restored'
            : 'Network connection lost',
        category: 'network',
        level: isConnected ? SentryLevel.info : SentryLevel.warning,
        data: {'connected': isConnected, 'type': connectionType ?? 'unknown'},
      ),
    );

    if (!isConnected) {
      Sentry.captureMessage(
        'App running in offline mode',
        level: SentryLevel.warning,
      );
    }
  }

  /// Tracks critical errors with context
  static Future<void> trackError({
    required dynamic error,
    required StackTrace stackTrace,
    String? context,
    Map<String, dynamic>? extraData,
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({
        if (context != null) 'context': context,
        if (extraData != null) ...extraData,
      }),
    );
  }

  /// Sets user context for error tracking
  static Future<void> setUser({
    required String id,
    String? username,
    String? email,
    Map<String, dynamic>? extraData,
  }) async {
    await Sentry.configureScope(
      (scope) => scope.setUser(
        SentryUser(id: id, username: username, email: email, data: extraData),
      ),
    );
  }

  /// Clears user context
  static Future<void> clearUser() async {
    await Sentry.configureScope((scope) => scope.setUser(null));
  }

  /// Adds custom tags to error reports
  static Future<void> setTag(String key, String value) async {
    await Sentry.configureScope((scope) => scope.setTag(key, value));
  }

  /// Adds custom context data
  static Future<void> setContext(
    String key,
    Map<String, dynamic> context,
  ) async {
    await Sentry.configureScope((scope) => scope.setContexts(key, context));
  }
}
