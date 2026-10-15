import '../core/constants/ppe.dart';

class PpeEvent {
  const PpeEvent({
    required this.id,
    required this.cameraId,
    required this.personTrackId,
    required this.status,
    required this.previousStatus,
    required this.missingPpe,
    required this.detectedPpe,
    required this.confidence,
    required this.personCount,
    required this.capturedAt,
    required this.imageUrl,
    required this.acknowledged,
    required this.acknowledgedBy,
    required this.acknowledgedAt,
    required this.resolvedAt,
    required this.durationSeconds,
    required this.modelVersion,
  });

  final String id;
  final String cameraId;
  final String? personTrackId;
  final String status;
  final String? previousStatus;
  final List<String> missingPpe;
  final List<String> detectedPpe;
  final double confidence;
  final int personCount;
  final DateTime capturedAt;
  final String? imageUrl;
  final bool acknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final int? durationSeconds;
  final String? modelVersion;

  bool get isSafe => status == Ppe.safe;
  bool get isNotSafe => status == Ppe.notSafe;
  String get statusThai => isSafe ? 'ปลอดภัย' : 'ไม่ปลอดภัย';
  String get missingThai => isSafe
      ? 'ตรวจพบอุปกรณ์ PPE ครบถ้วน'
      : 'ขาด ${missingPpe.map(Ppe.thai).join(' • ')}';

  factory PpeEvent.fromJson(Map<String, dynamic> json) {
    return PpeEvent(
      id: '${json['id'] ?? ''}',
      cameraId: '${json['camera_id'] ?? json['cameraId'] ?? ''}',
      personTrackId: json['person_track_id']?.toString() ?? json['personTrackId']?.toString(),
      status: '${json['status'] ?? Ppe.notSafe}',
      previousStatus: json['previous_status']?.toString() ?? json['previousStatus']?.toString(),
      missingPpe: _list(json['missing_ppe'] ?? json['missingPpe']),
      detectedPpe: _list(json['detected_ppe'] ?? json['detectedPpe']),
      confidence: _double(json['confidence']),
      personCount: _int(json['person_count'] ?? json['personCount']),
      capturedAt: _date(json['captured_at'] ?? json['capturedAt']) ?? DateTime.now(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      acknowledged: json['acknowledged'] == true,
      acknowledgedBy: json['acknowledged_by']?.toString() ?? json['acknowledgedBy']?.toString(),
      acknowledgedAt: _date(json['acknowledged_at'] ?? json['acknowledgedAt']),
      resolvedAt: _date(json['resolved_at'] ?? json['resolvedAt']),
      durationSeconds: _nullableInt(json['duration_seconds'] ?? json['durationSeconds']),
      modelVersion: json['model_version']?.toString() ?? json['modelVersion']?.toString(),
    );
  }

  static List<String> _list(Object? value) => value is List ? value.map((item) => '$item').toList() : const [];
  static DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString());
  static int _int(Object? value) => int.tryParse('${value ?? ''}') ?? 0;
  static int? _nullableInt(Object? value) => value == null ? null : int.tryParse('$value');
  static double _double(Object? value) => double.tryParse('${value ?? ''}') ?? 0;
}
