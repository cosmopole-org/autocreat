import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/demo_data.dart';
import '../data/repositories/user_repository.dart';
import '../models/user.dart';
import 'auth_provider.dart';
import 'demo_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

final usersProvider =
    FutureProvider.family<List<User>, String?>((ref, companyId) async {
  final isDemo = ref.watch(isDemoModeProvider);
  if (isDemo) return DemoData.users.map(User.fromJson).toList();
  return ref.watch(userRepositoryProvider).getUsers(companyId: companyId);
});

final userDetailProvider =
    FutureProvider.family<User, String>((ref, id) async {
  final isDemo = ref.watch(isDemoModeProvider);
  if (isDemo) {
    final match = DemoData.users.firstWhere(
      (u) => u['id'] == id,
      orElse: () => DemoData.users.first,
    );
    return User.fromJson(match);
  }
  return ref.watch(userRepositoryProvider).getUser(id);
});

class UserNotifier extends AsyncNotifier<List<User>> {
  @override
  Future<List<User>> build() async {
    final isDemo = ref.watch(isDemoModeProvider);
    if (isDemo) return DemoData.users.map(User.fromJson).toList();
    return ref.watch(userRepositoryProvider).getUsers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(userRepositoryProvider).getUsers());
  }

  Future<User> create(Map<String, dynamic> data) async {
    final user = await ref.read(userRepositoryProvider).createUser(data);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, user]);
    return user;
  }

  Future<User> updateItem(String id, Map<String, dynamic> data) async {
    final user = await ref.read(userRepositoryProvider).updateUser(id, data);
    final current = state.valueOrNull ?? [];
    state =
        AsyncValue.data(current.map((u) => u.id == id ? user : u).toList());
    return user;
  }

  Future<void> delete(String id) async {
    await ref.read(userRepositoryProvider).deleteUser(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((u) => u.id != id).toList());
  }
}

final userNotifierProvider =
    AsyncNotifierProvider<UserNotifier, List<User>>(UserNotifier.new);
