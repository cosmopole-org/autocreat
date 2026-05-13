import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  String? _token;
  bool _disposed = false;
  int _retryDelay = 1;
  Timer? _reconnectTimer;

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  void connect(String token) {
    _token = token;
    _disposed = false;
    _retryDelay = 1;
    _doConnect();
  }

  void _doConnect() {
    if (_disposed || _token == null) return;
    try {
      final uri = Uri.parse(
        '${AppConstants.wsBaseUrl}${AppConstants.wsRealtimeEndpoint}',
      ).replace(queryParameters: {'token': _token!});
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        (data) {
          if (data is String) {
            try {
              final msg = json.decode(data) as Map<String, dynamic>;
              // Handle ping/pong
              if (msg['type'] == 'ping') {
                _channel?.sink.add(json.encode({'type': 'pong'}));
                return;
              }
              _controller.add(msg);
            } catch (_) {}
          }
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
      );
      _retryDelay = 1; // reset on success
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _retryDelay), () {
      _retryDelay = (_retryDelay * 2).clamp(1, 30);
      _doConnect();
    });
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _token = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
