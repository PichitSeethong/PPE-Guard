import '../models/dashboard_summary.dart';
import '../services/api_client.dart';

class DashboardRepository {
  DashboardRepository._();

  static final instance = DashboardRepository._();

  Future<DashboardSummary> load() async {
    final data = await ApiClient.instance.get('/api/v1/dashboard');
    return DashboardSummary.fromJson((data as Map).cast<String, dynamic>());
  }
}
