class SystemHealth {
  const SystemHealth({
    required this.checkedAt,
    required this.databasePath,
    required this.evidencePath,
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
    required this.freePercent,
    required this.cameraCount,
    required this.eventCount,
    required this.evidenceFiles,
    required this.activeUsers,
    required this.backupFiles,
  });

  final DateTime? checkedAt;
  final String databasePath;
  final String evidencePath;
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;
  final double freePercent;
  final int cameraCount;
  final int eventCount;
  final int evidenceFiles;
  final int activeUsers;
  final int backupFiles;

  factory SystemHealth.fromJson(Map<String, dynamic> json) {
    final storage = (json['storage'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final counts = (json['counts'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return SystemHealth(
      checkedAt: DateTime.tryParse('${json['checked_at'] ?? ''}'),
      databasePath: '${json['database_path'] ?? '-'}',
      evidencePath: '${json['evidence_path'] ?? '-'}',
      totalBytes: _toInt(storage['total_bytes']),
      usedBytes: _toInt(storage['used_bytes']),
      freeBytes: _toInt(storage['free_bytes']),
      freePercent: _toDouble(storage['free_percent']),
      cameraCount: _toInt(counts['cameras']),
      eventCount: _toInt(counts['events']),
      evidenceFiles: _toInt(counts['evidence_files']),
      activeUsers: _toInt(counts['active_users']),
      backupFiles: _toInt(counts['backup_files']),
    );
  }

  static int _toInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  static double _toDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
