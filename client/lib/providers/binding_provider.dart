import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/binding_repository.dart';
import '../models/binding.dart';
import 'auth_provider.dart';

final bindingRepositoryProvider = Provider<BindingRepository>((ref) {
  return BindingRepository(ref.watch(apiClientProvider));
});

// ---------- Form-Model Bindings ----------

final nodeBindingsProvider =
    FutureProvider.family<List<FormModelBinding>, String>((ref, nodeId) async {
  if (nodeId.isEmpty) return [];
  return ref.watch(bindingRepositoryProvider).getNodeBindings(nodeId);
});

// ---------- Node Letter Assignments ----------

final nodeLetterAssignmentsProvider =
    FutureProvider.family<List<NodeLetterAssignment>, String>(
        (ref, nodeId) async {
  if (nodeId.isEmpty) return [];
  return ref.watch(bindingRepositoryProvider).getNodeLetterAssignments(nodeId);
});

// ---------- Step Generated Letters ----------

typedef StepLetterArgs = ({String instanceId, String stepId});

final stepGeneratedLettersProvider =
    FutureProvider.family<List<StepGeneratedLetter>, StepLetterArgs>(
        (ref, args) async {
  if (args.instanceId.isEmpty || args.stepId.isEmpty) return [];
  return ref.watch(bindingRepositoryProvider).getGeneratedLettersForStep(
        instanceId: args.instanceId,
        stepId: args.stepId,
      );
});
