import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the app is currently running in client-side demo mode.
///
/// When `true`, screens should prefer the `demo*Provider` variants from
/// `demo_overrides.dart` over real API providers so that no network calls
/// are made and no credentials are required.
final isDemoModeProvider = StateProvider<bool>((ref) => false);
