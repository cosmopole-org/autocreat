import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/realtime_provider.dart';
import '../../theme/app_colors.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Ensure realtime is connected
    ref.read(realtimeConnectionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark, cs),
          _buildSearchBar(context, cs),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildError(context, e),
              data: (tasks) => _buildTaskList(context, tasks, cs, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.task_alt_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Tasks',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              Consumer(builder: (ctx, ref2, _) {
                final count = ref2.watch(pendingTaskCountProvider);
                return Text(
                  count == 0
                      ? 'No pending tasks'
                      : '$count task${count == 1 ? '' : 's'} waiting',
                  style: TextStyle(
                    fontSize: 13,
                    color: count > 0
                        ? AppColors.warning
                        : cs.onSurface.withValues(alpha: 0.5),
                  ),
                );
              }),
            ],
          ),
          const Spacer(),
          IconButton.filled(
            onPressed: () => ref.read(taskListProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              foregroundColor: AppColors.primary,
            ),
            tooltip: 'Refresh tasks',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TextField(
        onChanged: (v) => setState(() => _search = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search tasks…',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          filled: true,
          fillColor: cs.surface,
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object e) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.error.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text('Failed to load tasks', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text(e.toString(), style: const TextStyle(fontSize: 12, color: AppColors.error)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(taskListProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<MyTask> tasks,
      ColorScheme cs, bool isDark) {
    final filtered = _search.isEmpty
        ? tasks
        : tasks
            .where((t) =>
                t.flowName.toLowerCase().contains(_search) ||
                t.nodeLabel.toLowerCase().contains(_search) ||
                t.roleName.toLowerCase().contains(_search))
            .toList();

    if (filtered.isEmpty) {
      return _buildEmpty(context, tasks.isEmpty);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => _TaskCard(
        task: filtered[i],
        onTap: () => context.go(
          '/tasks/${filtered[i].instanceId}/${filtered[i].nodeId}',
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool noTasks) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              noTasks ? Icons.check_circle_outline_rounded : Icons.search_off_rounded,
              size: 52,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            noTasks ? 'All caught up!' : 'No matching tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            noTasks
                ? 'No tasks assigned to you right now.\nNew tasks will appear here in real-time.'
                : 'Try adjusting your search query.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final MyTask task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final timeAgo = _timeAgo(task.instanceCreatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    _NodeTypeBadge(nodeType: 'step'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task.nodeLabel.isNotEmpty ? task.nodeLabel : 'Task Step',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Flow name
                Row(
                  children: [
                    Icon(Icons.account_tree_outlined,
                        size: 14,
                        color: cs.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        task.flowName.isNotEmpty ? task.flowName : 'Flow',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Role badge + time
                Row(
                  children: [
                    if (task.roleName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 11,
                                color: AppColors.accent.withValues(alpha: 0.8)),
                            const SizedBox(width: 3),
                            Text(
                              task.roleName,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.accent.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (task.formName.isNotEmpty) ...[
                      Icon(Icons.dynamic_form_outlined,
                          size: 12,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: 3),
                      Text(
                        task.formName,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    Icon(Icons.access_time_rounded,
                        size: 11,
                        color: cs.onSurface.withValues(alpha: 0.35)),
                    const SizedBox(width: 3),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                if (task.previousSteps.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _StepProgressRow(steps: task.previousSteps),
                ],
                if (task.startedByUser != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 13,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text(
                        'Started by ${task.startedByUser!.fullName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _StepProgressRow extends StatelessWidget {
  final List<StepHistoryItem> steps;

  const _StepProgressRow({required this.steps});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          'Progress:',
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: steps
                  .map((s) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.status == 'COMPLETED'
                              ? AppColors.success
                              : s.status == 'REJECTED'
                                  ? AppColors.error
                                  : AppColors.warning,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _NodeTypeBadge extends StatelessWidget {
  final String nodeType;

  const _NodeTypeBadge({required this.nodeType});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (nodeType.toLowerCase()) {
      case 'start':
        color = AppColors.nodeStart;
        icon = Icons.play_circle_outline_rounded;
        break;
      case 'end':
        color = AppColors.nodeEnd;
        icon = Icons.stop_circle_outlined;
        break;
      case 'decision':
        color = AppColors.nodeDecision;
        icon = Icons.call_split_rounded;
        break;
      default:
        color = AppColors.nodeStep;
        icon = Icons.radio_button_checked_rounded;
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
