import '../core/utils/role_utils.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.department,
    required this.isActive,
    required this.mustChangePassword,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String role;
  final String department;
  final bool isActive;
  final bool mustChangePassword;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  bool get canAcknowledge => RoleUtils.canAcknowledge(role);
  bool get isAdmin => role == 'admin';
  String get roleThai => RoleUtils.thai(role);

  AppUser copyWith({
    String? displayName,
    String? role,
    String? department,
    bool? isActive,
    bool? mustChangePassword,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id,
      username: username,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: '${json['id'] ?? ''}',
      username: '${json['username'] ?? ''}',
      displayName: '${json['display_name'] ?? json['displayName'] ?? ''}',
      role: '${json['role'] ?? 'viewer'}',
      department: '${json['department'] ?? '-'}',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      mustChangePassword: json['must_change_password'] ?? json['mustChangePassword'] ?? false,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
      lastLoginAt: _parseDate(json['last_login_at'] ?? json['lastLoginAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
