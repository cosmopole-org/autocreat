import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/task_repository.dart';
import '../models/task.dart';
import 'auth_provider.dart';
import 'company_provider.dart';
import 'demo_provider.dart';
import 'realtime_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(apiClientProvider));
});

class TaskListNotifier extends AsyncNotifier<List<MyTask>> {
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  Future<List<MyTask>> build() async {
    final isDemo = ref.watch(isDemoModeProvider);
    if (isDemo) return [];

    // Rebuild on login/logout so the list reflects the current user.
    final user = ref.watch(authProvider).valueOrNull;
    if (user == null) return [];

    _wsSub?.cancel();
    _wsSub = ref.watch(realtimeServiceProvider).messages.listen(_onWsMessage);
    ref.onDispose(() => _wsSub?.cancel());

    return _fetch();
  }

  Future<List<MyTask>> _fetch() async {
    final companyId = ref.read(selectedCompanyIdProvider);
    return ref.read(taskRepositoryProvider).getMyTasks(companyId: companyId);
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == 'task.assigned' ||
        type == 'task.updated' ||
        type == 'flow.instance_advanced' ||
        type == 'flow.instance_rejected') {
      ref.invalidateSelf();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> submitTask({
    required String instanceId,
    required Map<String, dynamic> formData,
    String? nextUserId,
    bool useRoundRobin = false,
  }) async {
    await ref.read(taskRepositoryProvider).submitTask(
          instanceId: instanceId,
          formData: formData,
          nextUserId: nextUserId,
          useRoundRobin: useRoundRobin,
        );
    await refresh();
  }

  Future<void> rejectTask({
    required String instanceId,
    String? comment,
    String? rejectToNodeId,
  }) async {
    await ref.read(taskRepositoryProvider).rejectTask(
          instanceId: instanceId,
          comment: comment,
          rejectToNodeId: rejectToNodeId,
        );
    await refresh();
  }

  Future<void> startFlow({
    required String flowId,
    required Map<String, dynamic> formData,
  }) async {
    final companyId = ref.read(selectedCompanyIdProvider);
    final instanceId = await ref.read(taskRepositoryProvider).startFlow(
          flowId: flowId,
          companyId: companyId,
        );
    if (instanceId.isNotEmpty) {
      await ref.read(taskRepositoryProvider).submitTask(
            instanceId: instanceId,
            formData: formData,
          );
    }
    await refresh();
  }
}

final taskListProvider =
    AsyncNotifierProvider<TaskListNotifier, List<MyTask>>(TaskListNotifier.new);

final pendingTaskCountProvider = Provider<int>((ref) {
  return ref.watch(taskListProvider).maybeWhen(
        data: (tasks) => tasks.length,
        orElse: () => 0,
      );
});

final taskDetailProvider =
    FutureProvider.family<MyTask, ({String instanceId, String nodeId})>(
        (ref, args) async {
  final isDemo = ref.watch(isDemoModeProvider);
  if (isDemo) throw Exception('Demo mode');
  final companyId = ref.read(selectedCompanyIdProvider);
  return ref.read(taskRepositoryProvider).getTaskDetail(
        instanceId: args.instanceId,
        nodeId: args.nodeId,
        companyId: companyId,
      );
});

final roleUsersProvider =
    FutureProvider.family<List<UserBrief>, String>((ref, roleId) async {
  if (roleId.isEmpty) return [];
  return ref.read(taskRepositoryProvider).getUsersForRole(roleId);
});

class StartableFlowsNotifier extends AsyncNotifier<List<StartableFlow>> {
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  Future<List<StartableFlow>> build() async {
    final isDemo = ref.watch(isDemoModeProvider);
    if (isDemo) return [];

    // Rebuild on login/logout so the quick-start section reflects the current user's role.
    final user = ref.watch(authProvider).valueOrNull;
    if (user == null) return [];

    _wsSub?.cancel();
    _wsSub = ref.watch(realtimeServiceProvider).messages.listen(_onWsMessage);
    ref.onDispose(() => _wsSub?.cancel());

    return _fetch();
  }

  Future<List<StartableFlow>> _fetch() async {
    final companyId = ref.read(selectedCompanyIdProvider);
    return ref
        .read(taskRepositoryProvider)
        .getStartableFlows(companyId: companyId);
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == 'flow.assignments_updated' || type == 'flow.graph_saved') {
      ref.invalidateSelf();
    }
  }
}

final startableFlowsProvider =
    AsyncNotifierProvider<StartableFlowsNotifier, List<StartableFlow>>(
        StartableFlowsNotifier.new);
