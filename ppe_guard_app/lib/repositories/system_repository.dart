import '../models/system_health.dart';
import '../services/api_client.dart';

class SystemRepository {
  SystemRepository._();
  static final instance = SystemRepository._();

  Future<SystemHealth> health() async {
    final data = await ApiClient.instance.get('/api/v1/system/health');
    return SystemHealth.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<Map<String, dynamic>> createBackup() async {
    final data = await ApiClient.instance.post('/api/v1/system/backup', const {});
    return (data as Map).cast<String, dynamic>();
  }
}
