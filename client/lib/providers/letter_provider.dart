import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/letter_repository.dart';
import '../models/letter_template.dart';
import 'auth_provider.dart';

final letterRepositoryProvider = Provider<LetterRepository>((ref) {
  return LetterRepository(ref.watch(apiClientProvider));
});

final lettersProvider =
    FutureProvider.family<List<LetterTemplate>, String?>((ref, companyId) async {
  return ref.watch(letterRepositoryProvider).getLetters(companyId: companyId);
});

final letterDetailProvider =
    FutureProvider.family<LetterTemplate, String>((ref, id) async {
  return ref.watch(letterRepositoryProvider).getLetter(id);
});

class LetterNotifier extends AsyncNotifier<List<LetterTemplate>> {
  @override
  Future<List<LetterTemplate>> build() async {
    return ref.watch(letterRepositoryProvider).getLetters();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(letterRepositoryProvider).getLetters());
  }

  Future<LetterTemplate> create(Map<String, dynamic> data) async {
    final letter =
        await ref.read(letterRepositoryProvider).createLetter(data);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, letter]);
    return letter;
  }

  Future<LetterTemplate> update(String id, Map<String, dynamic> data) async {
    final letter =
        await ref.read(letterRepositoryProvider).updateLetter(id, data);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
        current.map((l) => l.id == id ? letter : l).toList());
    return letter;
  }

  Future<void> delete(String id) async {
    await ref.read(letterRepositoryProvider).deleteLetter(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((l) => l.id != id).toList());
  }
}

final letterNotifierProvider =
    AsyncNotifierProvider<LetterNotifier, List<LetterTemplate>>(
        LetterNotifier.new);
