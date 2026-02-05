/// WiFi session model representing an active internet session
class WifiSession {
  final int id;
  final int userId;
  final int machineId;
  final String? machineName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final String status;
  final String? userMacAddress;
  final String? userIpAddress;
  final int? dataUsedMb;

  WifiSession({
    required this.id,
    required this.userId,
    required this.machineId,
    this.machineName,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.status,
    this.userMacAddress,
    this.userIpAddress,
    this.dataUsedMb,
  });

  /// Create WifiSession from JSON
  factory WifiSession.fromJson(Map<String, dynamic> json) {
    return WifiSession(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      machineId: json['machine_id'] as int,
      machineName: json['machine_name'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      status: json['status'] as String? ?? 'inactive',
      userMacAddress: json['user_mac_address'] as String?,
      userIpAddress: json['user_ip_address'] as String?,
      dataUsedMb: json['data_used_mb'] as int?,
    );
  }

  /// Convert WifiSession to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'machine_id': machineId,
      'machine_name': machineName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'status': status,
      'user_mac_address': userMacAddress,
      'user_ip_address': userIpAddress,
      'data_used_mb': dataUsedMb,
    };
  }

  /// Check if session is active
  bool get isActive => status == 'active';

  /// Check if session is completed
  bool get isCompleted => status == 'completed';

  /// Check if session is expired
  bool get isExpired => status == 'expired';

  /// Get remaining minutes
  int get remainingMinutes {
    if (endTime == null || !isActive) return 0;
    final remaining = endTime!.difference(DateTime.now()).inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// Get elapsed time
  Duration get elapsedTime {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  @override
  String toString() {
    return 'WifiSession(id: $id, machine: $machineName, status: $status, duration: $durationMinutes min)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WifiSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
