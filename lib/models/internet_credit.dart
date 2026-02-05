/// Internet credit model representing user's available internet minutes
class InternetCredit {
  final int totalMinutes;
  final int usedMinutes;
  final int remainingMinutes;
  final DateTime? expirationDate;
  final bool isActive;

  InternetCredit({
    required this.totalMinutes,
    required this.usedMinutes,
    required this.remainingMinutes,
    this.expirationDate,
    required this.isActive,
  });

  /// Create InternetCredit from JSON
  factory InternetCredit.fromJson(Map<String, dynamic> json) {
    return InternetCredit(
      totalMinutes: json['total_minutes'] as int? ?? 0,
      usedMinutes: json['used_minutes'] as int? ?? 0,
      remainingMinutes: json['remaining_minutes'] as int? ?? 0,
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  /// Convert InternetCredit to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_minutes': totalMinutes,
      'used_minutes': usedMinutes,
      'remaining_minutes': remainingMinutes,
      'expiration_date': expirationDate?.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Check if credit is expired
  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  /// Get percentage used
  double get usagePercentage {
    if (totalMinutes == 0) return 0;
    return (usedMinutes / totalMinutes) * 100;
  }

  @override
  String toString() {
    return 'InternetCredit(remaining: $remainingMinutes min, active: $isActive)';
  }
}
