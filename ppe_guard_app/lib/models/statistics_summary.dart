class StatisticsSummary {
  const StatisticsSummary({
    required this.period,
    required this.eventCount,
    required this.safeEventCount,
    required this.notSafeEventCount,
    required this.complianceRate,
    required this.missingPpeCounts,
  });

  final String period;
  final int eventCount;
  final int safeEventCount;
  final int notSafeEventCount;
  final double complianceRate;
  final Map<String, int> missingPpeCounts;

  bool get hasInspections => eventCount > 0;

  factory StatisticsSummary.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['missing_ppe_counts'];
    final counts = <String, int>{};
    if (rawCounts is Map) {
      rawCounts.forEach((key, value) {
        counts['$key'] = int.tryParse('$value') ?? 0;
      });
    }

    return StatisticsSummary(
      period: '${json['period'] ?? 'today'}',
      eventCount: _int(json['event_count'] ?? json['inspection_count']),
      safeEventCount: _int(json['safe_event_count']),
      notSafeEventCount: _int(json['not_safe_event_count']),
      complianceRate: _double(json['compliance_rate']),
      missingPpeCounts: counts,
    );
  }

  static int _int(Object? value) => int.tryParse('${value ?? ''}') ?? 0;
  static double _double(Object? value) =>
      double.tryParse('${value ?? ''}') ?? 0;
}
