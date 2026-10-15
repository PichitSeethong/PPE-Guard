import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';

class RealtimeService {
  RealtimeService._();

  static final instance = RealtimeService._();

  final StreamController<Map<String, dynamic>> _events = StreamController.broadcast();
  StreamSubscription? _subscription;
  WebSocketChannel? _channel;
  Timer? _retryTimer;
  bool _closedByUser = false;

  Stream<Map<String, dynamic>> get events => _events.stream;

  void connect() {
    if (ApiClient.instance.accessToken == null || ApiClient.instance.accessToken!.isEmpty) return;
    disconnect(allowReconnect: false);
    _closedByUser = false;

    try {
      _channel = WebSocketChannel.connect(ApiClient.instance.dashboardSocketUri);
      _subscription = _channel!.stream.listen(
        (raw) {
          try {
            final parsed = jsonDecode(raw.toString());
            if (parsed is Map) _events.add(parsed.cast<String, dynamic>());
          } catch (_) {
            // Ignore malformed realtime payloads.
          }
        },
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void disconnect({bool allowReconnect = false}) {
    _retryTimer?.cancel();
    _retryTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _closedByUser = !allowReconnect;
  }

  void _scheduleReconnect() {
    if (_closedByUser || _retryTimer?.isActive == true) return;
    _retryTimer = Timer(const Duration(seconds: 5), connect);
  }
}
