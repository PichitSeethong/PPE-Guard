import '../models/statistics_summary.dart';
import '../services/api_client.dart';

class StatisticsRepository {
  StatisticsRepository._();

  static final instance = StatisticsRepository._();

  Future<StatisticsSummary> load(String period) async {
    final data = await ApiClient.instance.get('/api/v1/statistics', query: {'period': period});
    return StatisticsSummary.fromJson((data as Map).cast<String, dynamic>());
  }
}
