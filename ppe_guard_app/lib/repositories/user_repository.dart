import '../models/app_user.dart';
import '../models/audit_log.dart';
import '../services/api_client.dart';

class UserRepository {
  UserRepository._();
  static final instance = UserRepository._();

  Future<List<AppUser>> list() async {
    final data = await ApiClient.instance.get('/api/v1/users');
    final items = ((data as Map)['items'] as List?) ?? const [];
    return items.whereType<Map>().map((item) => AppUser.fromJson(item.cast<String, dynamic>())).toList();
  }

  Future<AppUser> create({
    required String username,
    required String password,
    required String displayName,
    required String role,
    required String department,
  }) async {
    final data = await ApiClient.instance.post('/api/v1/users', {
      'username': username,
      'password': password,
      'display_name': displayName,
      'role': role,
      'department': department,
    });
    return AppUser.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<AppUser> update(String id, Map<String, dynamic> fields) async {
    final data = await ApiClient.instance.patch('/api/v1/users/$id', fields);
    return AppUser.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<AppUser> resetPassword(String id, String temporaryPassword) async {
    final data = await ApiClient.instance.post('/api/v1/users/$id/reset-password', {'temporary_password': temporaryPassword});
    return AppUser.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<List<AuditLog>> auditLogs() async {
    final data = await ApiClient.instance.get('/api/v1/users/audit/logs', query: {'limit': '150'});
    final items = ((data as Map)['items'] as List?) ?? const [];
    return items.whereType<Map>().map((item) => AuditLog.fromJson(item.cast<String, dynamic>())).toList();
  }
}
