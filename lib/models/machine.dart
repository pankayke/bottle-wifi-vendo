/// Machine model representing a WiFi vendo machine
class Machine {
  final int id;
  final String name;
  final String macAddress;
  final String ipAddress;
  final String status;
  final bool isOnline;
  final DateTime? lastOnline;
  final String? location;
  final int totalBottlesProcessed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Machine({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.ipAddress,
    required this.status,
    required this.isOnline,
    this.lastOnline,
    this.location,
    required this.totalBottlesProcessed,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Machine from JSON
  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      macAddress: json['mac_address'] as String? ?? '',
      ipAddress: json['ip_address'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
      isOnline: json['is_online'] as bool? ?? false,
      lastOnline: _parseDateTime(json['last_online'] ?? json['last_heartbeat']),
      location: json['location'] as String?,
      totalBottlesProcessed:
          json['total_bottles_processed'] as int? ??
          json['today_bottles'] as int? ??
          0,
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Convert Machine to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mac_address': macAddress,
      'ip_address': ipAddress,
      'status': status,
      'is_online': isOnline,
      'last_online': lastOnline?.toIso8601String(),
      'location': location,
      'total_bottles_processed': totalBottlesProcessed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if machine is active
  bool get isActive => status == 'active';

  /// Check if machine is under maintenance
  bool get isInMaintenance => status == 'maintenance';

  /// Get status color indicator
  String get statusColor {
    if (isOnline) return 'green';
    if (isInMaintenance) return 'orange';
    return 'red';
  }

  @override
  String toString() {
    return 'Machine(id: $id, name: $name, status: $status, online: $isOnline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Machine && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
