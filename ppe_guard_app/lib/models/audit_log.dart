class AuditLog {
  const AuditLog({
    required this.id,
    required this.actorUsername,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.detail,
    required this.createdAt,
  });

  final String id;
  final String? actorUsername;
  final String action;
  final String targetType;
  final String? targetId;
  final Map<String, dynamic> detail;
  final DateTime? createdAt;

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    final raw = json['detail'];
    return AuditLog(
      id: '${json['id'] ?? ''}',
      actorUsername: json['actor_username']?.toString(),
      action: '${json['action'] ?? ''}',
      targetType: '${json['target_type'] ?? ''}',
      targetId: json['target_id']?.toString(),
      detail: raw is Map ? raw.cast<String, dynamic>() : const <String, dynamic>{},
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }
}
