import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/realtime_service.dart';
import 'auth_provider.dart';

// Singleton service provider
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final svc = RealtimeService();
  ref.onDispose(svc.dispose);
  return svc;
});

// Watches auth token and connects/disconnects WS accordingly
final realtimeConnectionProvider = Provider<void>((ref) {
  final tokenAsync = ref.watch(authTokenProvider);
  final svc = ref.watch(realtimeServiceProvider);
  final token = tokenAsync.valueOrNull;
  if (token != null && token.isNotEmpty) {
    svc.connect(token);
  } else {
    svc.disconnect();
  }
});

// Raw stream of all WS messages
final realtimeStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  ref.watch(realtimeConnectionProvider); // ensure connected
  return ref.watch(realtimeServiceProvider).messages;
});
