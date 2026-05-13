import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../data/repositories/company_repository.dart';
import '../models/company.dart';
import 'auth_provider.dart';
import 'theme_provider.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(ref.watch(apiClientProvider));
});

final companiesProvider = FutureProvider<List<Company>>((ref) async {
  return ref.watch(companyRepositoryProvider).getCompanies();
});

final companyDetailProvider =
    FutureProvider.family<Company, String>((ref, id) async {
  return ref.watch(companyRepositoryProvider).getCompany(id);
});

final selectedCompanyIdProvider =
    StateProvider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString(AppConstants.lastCompanyKey);
});

final selectedCompanyProvider = Provider<Company?>((ref) {
  final id = ref.watch(selectedCompanyIdProvider);
  if (id == null) return null;
  return ref.watch(companyDetailProvider(id)).valueOrNull;
});

class CompanyNotifier extends AsyncNotifier<List<Company>> {
  @override
  Future<List<Company>> build() async {
    return ref.watch(companyRepositoryProvider).getCompanies();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(companyRepositoryProvider).getCompanies());
  }

  Future<Company> create(Map<String, dynamic> data) async {
    final company =
        await ref.read(companyRepositoryProvider).createCompany(data);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, company]);
    return company;
  }

  Future<Company> updateItem(String id, Map<String, dynamic> data) async {
    final company =
        await ref.read(companyRepositoryProvider).updateCompany(id, data);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
        current.map((c) => c.id == id ? company : c).toList());
    return company;
  }

  Future<void> delete(String id) async {
    await ref.read(companyRepositoryProvider).deleteCompany(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((c) => c.id != id).toList());
  }
}

final companyNotifierProvider =
    AsyncNotifierProvider<CompanyNotifier, List<Company>>(CompanyNotifier.new);
