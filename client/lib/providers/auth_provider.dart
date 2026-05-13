import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/api_client.dart';
import '../data/repositories/auth_repository.dart';
import '../models/user.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(
    storage: storage,
    // When the interceptor can't refresh an expired token it clears storage
    // and calls this callback, which propagates the logout into Riverpod state
    // so the router redirects to the login page.
    onUnauthorized: () => ref.read(authProvider.notifier).forceLogout(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(apiClient, storage);
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final isLoggedIn = await repo.isLoggedIn();
    if (!isLoggedIn) return null;
    try {
      return await repo.getMe();
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final auth = await repo.login(email, password);
      return auth.user;
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? companyName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final auth = await repo.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        companyName: companyName,
        phone: phone,
      );
      return auth.user;
    });
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
  }

  /// Called by the API interceptor when token refresh fails so the app
  /// transitions to the logged-out state without an explicit user action.
  void forceLogout() {
    state = const AsyncValue.data(null);
  }

  /// Sets a synthetic demo user as the current session without any network
  /// call, used exclusively by client-side demo mode.
  void loginAsDemoUser() {
    state = const AsyncValue.data(
      User(
        id: 'demo',
        email: 'demo@autocreat.io',
        firstName: 'Demo',
        lastName: 'User',
        role: 'owner',
      ),
    );
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});

// Provides the current access token as a String? (null when logged out).
// Derived from authProvider so it updates when auth state changes.
final authTokenProvider = FutureProvider<String?>((ref) async {
  // Re-evaluate whenever auth state changes
  ref.watch(authProvider);
  final repo = ref.read(authRepositoryProvider);
  return repo.getAccessToken();
});
