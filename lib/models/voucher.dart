/// Voucher model representing a WiFi time voucher
class Voucher {
  final int id;
  final String code;
  final int minutes;
  final String status;
  final int? userId;
  final String? userName;
  final DateTime? redeemedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  Voucher({
    required this.id,
    required this.code,
    required this.minutes,
    required this.status,
    this.userId,
    this.userName,
    this.redeemedAt,
    this.expiresAt,
    required this.createdAt,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String,
      minutes: json['minutes'] as int? ?? json['minutes_value'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      userId: json['user_id'] as int? ?? json['assigned_to_user_id'] as int?,
      userName:
          json['user_name'] as String? ?? json['user']?['name'] as String?,
      redeemedAt: json['redeemed_at'] != null
          ? DateTime.parse(json['redeemed_at'] as String)
          : (json['first_used_at'] != null
                ? DateTime.parse(json['first_used_at'] as String)
                : null),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : (json['valid_until'] != null
                ? DateTime.parse(json['valid_until'] as String)
                : null),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'minutes': minutes,
      'status': status,
      'user_id': userId,
      'user_name': userName,
      'redeemed_at': redeemedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isRedeemed => status == 'redeemed';
  bool get isRevoked => status == 'revoked';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  String toString() =>
      'Voucher(id: $id, code: $code, minutes: $minutes, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Voucher && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
