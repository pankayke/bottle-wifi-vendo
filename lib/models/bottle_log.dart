/// Bottle log model representing a bottle detection event
class BottleLog {
  final int id;
  final int userId;
  final int machineId;
  final String? machineName;
  final int creditsAwarded;
  final String? imageUrl;
  final String status;
  final DateTime timestamp;
  final DateTime createdAt;

  BottleLog({
    required this.id,
    required this.userId,
    required this.machineId,
    this.machineName,
    required this.creditsAwarded,
    this.imageUrl,
    required this.status,
    required this.timestamp,
    required this.createdAt,
  });

  /// Create BottleLog from JSON
  factory BottleLog.fromJson(Map<String, dynamic> json) {
    return BottleLog(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      machineId: json['machine_id'] as int,
      machineName: json['machine_name'] as String?,
      creditsAwarded: json['credits_awarded'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert BottleLog to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'machine_id': machineId,
      'machine_name': machineName,
      'credits_awarded': creditsAwarded,
      'image_url': imageUrl,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Check if bottle is verified
  bool get isVerified => status == 'verified';

  /// Check if bottle is pending
  bool get isPending => status == 'pending';

  /// Check if bottle is rejected
  bool get isRejected => status == 'rejected';

  @override
  String toString() {
    return 'BottleLog(id: $id, machineId: $machineId, credits: $creditsAwarded, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BottleLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
