import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/role_repository.dart';
import '../models/role.dart';
import 'auth_provider.dart';

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return RoleRepository(ref.watch(apiClientProvider));
});

final rolesProvider =
    FutureProvider.family<List<Role>, String?>((ref, companyId) async {
  return ref.watch(roleRepositoryProvider).getRoles(companyId: companyId);
});

final roleDetailProvider =
    FutureProvider.family<Role, String>((ref, id) async {
  return ref.watch(roleRepositoryProvider).getRole(id);
});

class RoleNotifier extends AsyncNotifier<List<Role>> {
  @override
  Future<List<Role>> build() async {
    return ref.watch(roleRepositoryProvider).getRoles();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(roleRepositoryProvider).getRoles());
  }

  Future<Role> create(Map<String, dynamic> data) async {
    final role = await ref.read(roleRepositoryProvider).createRole(data);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, role]);
    return role;
  }

  Future<Role> update(String id, Map<String, dynamic> data) async {
    final role = await ref.read(roleRepositoryProvider).updateRole(id, data);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
        current.map((r) => r.id == id ? role : r).toList());
    return role;
  }

  Future<void> delete(String id) async {
    await ref.read(roleRepositoryProvider).deleteRole(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((r) => r.id != id).toList());
  }
}

final roleNotifierProvider =
    AsyncNotifierProvider<RoleNotifier, List<Role>>(RoleNotifier.new);
