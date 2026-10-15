import '../models/ppe_event.dart';
import '../services/api_client.dart';

class EventRepository {
  EventRepository._();

  static final instance = EventRepository._();

  Future<List<PpeEvent>> list({String? status, String period = 'all'}) async {
    final query = <String, String>{'period': period, 'limit': '100'};
    if (status != null && status != 'ALL') query['status'] = status;
    final data = await ApiClient.instance.get('/api/v1/events', query: query);
    final map = (data as Map).cast<String, dynamic>();
    final items = map['items'];
    if (items is! List) return const [];
    return items.whereType<Map>().map((item) => PpeEvent.fromJson(item.cast<String, dynamic>())).toList();
  }

  Future<PpeEvent> byId(String eventId) async {
    final data = await ApiClient.instance.get('/api/v1/events/$eventId');
    return PpeEvent.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<PpeEvent> acknowledge(String eventId) async {
    final data = await ApiClient.instance.post('/api/v1/events/$eventId/acknowledge', const {});
    return PpeEvent.fromJson((data as Map).cast<String, dynamic>());
  }
}
