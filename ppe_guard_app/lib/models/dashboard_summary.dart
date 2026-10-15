import 'camera_status.dart';
import 'ppe_event.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.cameras,
    required this.latestEvent,
    required this.recentEvents,
    required this.eventCount,
    required this.safeEventCount,
    required this.notSafeEventCount,
    required this.complianceRate,
  });

  final List<CameraStatus> cameras;
  final PpeEvent? latestEvent;
  final List<PpeEvent> recentEvents;
  final int eventCount;
  final int safeEventCount;
  final int notSafeEventCount;
  final double complianceRate;

  bool get hasInspections => eventCount > 0;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final rawStats = json['today_statistics'];
    final stats = rawStats is Map
        ? rawStats.cast<String, dynamic>()
        : <String, dynamic>{};
    final rawCameras = json['cameras'];
    final rawRecent = json['recent_events'];
    final rawLatest = json['latest_event'];

    return DashboardSummary(
      cameras: rawCameras is List
          ? rawCameras
              .whereType<Map>()
              .map(
                (item) =>
                    CameraStatus.fromJson(item.cast<String, dynamic>()),
              )
              .toList()
          : const [],
      latestEvent: rawLatest is Map
          ? PpeEvent.fromJson(rawLatest.cast<String, dynamic>())
          : null,
      recentEvents: rawRecent is List
          ? rawRecent
              .whereType<Map>()
              .map(
                (item) => PpeEvent.fromJson(item.cast<String, dynamic>()),
              )
              .toList()
          : const [],
      eventCount: _int(stats['event_count'] ?? stats['inspection_count']),
      safeEventCount: _int(stats['safe_event_count']),
      notSafeEventCount: _int(stats['not_safe_event_count']),
      complianceRate: _double(stats['compliance_rate']),
    );
  }

  static int _int(Object? value) => int.tryParse('${value ?? ''}') ?? 0;
  static double _double(Object? value) =>
      double.tryParse('${value ?? ''}') ?? 0;
}
