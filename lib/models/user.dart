/// User model representing authenticated user data
class User {
  final int id;
  final String name;
  final String email;
  final int credits;
  final String? phoneNumber;
  final String role;
  final DateTime? emailVerifiedAt;
  final DateTime? lastLoginAt;
  final DateTime? suspendedAt;
  final String? suspensionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.credits,
    this.phoneNumber,
    this.role = 'user',
    this.emailVerifiedAt,
    this.lastLoginAt,
    this.suspendedAt,
    this.suspensionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user has admin role
  bool get isAdmin => role == 'admin';

  /// Check if user is suspended
  bool get isSuspended => suspendedAt != null;

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      credits: json['credits'] as int? ?? json['total_credits'] as int? ?? 0,
      phoneNumber: json['phone_number'] as String?,
      role: json['role'] as String? ?? 'user',
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      suspendedAt: json['suspended_at'] != null
          ? DateTime.parse(json['suspended_at'] as String)
          : null,
      suspensionReason: json['suspension_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'credits': credits,
      'phone_number': phoneNumber,
      'role': role,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'suspended_at': suspendedAt?.toIso8601String(),
      'suspension_reason': suspensionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    int? id,
    String? name,
    String? email,
    int? credits,
    String? phoneNumber,
    String? role,
    DateTime? emailVerifiedAt,
    DateTime? lastLoginAt,
    DateTime? suspendedAt,
    String? suspensionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      credits: credits ?? this.credits,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, credits: $credits)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
