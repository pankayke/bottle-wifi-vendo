/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.meta,
  });

  /// Create ApiResponse from JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? dataParser,
  }) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && dataParser != null
          ? dataParser(json['data'])
          : json['data'] as T?,
      errors: json['errors'] as Map<String, dynamic>?,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  /// Convert ApiResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'errors': errors,
      'meta': meta,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data)';
  }
}

/// Bottle statistics model
class BottleStatistics {
  final int totalBottles;
  final int verifiedBottles;
  final int pendingBottles;
  final int rejectedBottles;
  final int totalCreditsEarned;
  final int thisMonthBottles;
  final int thisWeekBottles;

  BottleStatistics({
    required this.totalBottles,
    required this.verifiedBottles,
    required this.pendingBottles,
    required this.rejectedBottles,
    required this.totalCreditsEarned,
    required this.thisMonthBottles,
    required this.thisWeekBottles,
  });

  factory BottleStatistics.fromJson(Map<String, dynamic> json) {
    return BottleStatistics(
      totalBottles: json['total_bottles'] as int? ?? 0,
      verifiedBottles: json['verified_bottles'] as int? ?? 0,
      pendingBottles: json['pending_bottles'] as int? ?? 0,
      rejectedBottles: json['rejected_bottles'] as int? ?? 0,
      totalCreditsEarned: json['total_credits_earned'] as int? ?? 0,
      thisMonthBottles: json['this_month_bottles'] as int? ?? 0,
      thisWeekBottles: json['this_week_bottles'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_bottles': totalBottles,
      'verified_bottles': verifiedBottles,
      'pending_bottles': pendingBottles,
      'rejected_bottles': rejectedBottles,
      'total_credits_earned': totalCreditsEarned,
      'this_month_bottles': thisMonthBottles,
      'this_week_bottles': thisWeekBottles,
    };
  }
}
