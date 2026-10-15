import '../core/constants/ppe.dart';

class CameraStatus {
  const CameraStatus({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.lastHeartbeatAt,
    required this.lastStatus,
    required this.lastConfidence,
    required this.modelVersion,
  });

  final String id;
  final String name;
  final String location;
  final String status;
  final DateTime? lastHeartbeatAt;
  final String? lastStatus;
  final double? lastConfidence;
  final String? modelVersion;

  bool get isOnline => status == 'ONLINE';
  bool get isSafe => lastStatus == Ppe.safe;

  factory CameraStatus.fromJson(Map<String, dynamic> json) {
    return CameraStatus(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? json['id'] ?? 'reCamera'}',
      location: '${json['location'] ?? '-'}',
      status: '${json['status'] ?? Ppe.offline}',
      lastHeartbeatAt: _parseDate(json['last_heartbeat_at'] ?? json['lastHeartbeatAt']),
      lastStatus: json['last_status']?.toString() ?? json['lastStatus']?.toString(),
      lastConfidence: _toDouble(json['last_confidence'] ?? json['lastConfidence']),
      modelVersion: json['model_version']?.toString() ?? json['modelVersion']?.toString(),
    );
  }

  static DateTime? _parseDate(Object? value) => value == null ? null : DateTime.tryParse(value.toString());
  static double? _toDouble(Object? value) => value == null ? null : double.tryParse(value.toString());
}
