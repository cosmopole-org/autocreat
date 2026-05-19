import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_colors.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String instanceId;
  final String nodeId;

  const TaskDetailScreen({
    super.key,
    required this.instanceId,
    required this.nodeId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, dynamic> _formValues = {};
  String? _selectedNextUserId;
  bool _useRoundRobin = false;
  bool _submitting = false;
  bool _rejecting = false;
  final _rejectCommentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rejectCommentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taskAsync = ref.watch(taskDetailProvider(
        (instanceId: widget.instanceId, nodeId: widget.nodeId)));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, e),
        data: (task) => _buildContent(context, task, cs, isDark),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object e) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/tasks'),
        ),
        title: const Text('Task'),
      ),
      body: Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, MyTask task, ColorScheme cs, bool isDark) {
    return NestedScrollView(
      headerSliverBuilder: (ctx, inner) => [
        _buildAppBar(ctx, task, cs, isDark),
      ],
      body: Column(
        children: [
          _buildTabBar(cs, isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFormTab(context, task, cs, isDark),
                _buildHistoryTab(context, task, cs, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, MyTask task, ColorScheme cs, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.go('/tasks'),
      ),
      actions: [
        _buildRejectButton(context, task),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.1),
                AppColors.accent.withValues(alpha: isDark ? 0.2 : 0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  _NodeBadge(label: task.nodeLabel),
                  const SizedBox(width: 10),
                  if (task.roleName.isNotEmpty)
                    _RoleBadge(roleName: task.roleName),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                task.flowName.isNotEmpty ? task.flowName : 'Flow Task',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (task.nodeDescription.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.nodeDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (task.startedByUser != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 13,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      'Started by ${task.startedByUser!.fullName} · ${_formatDate(task.instanceCreatedAt)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectButton(BuildContext context, MyTask task) {
    return OutlinedButton.icon(
      onPressed: _rejecting ? null : () => _showRejectDialog(context, task),
      icon: _rejecting
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.cancel_outlined, size: 16),
      label: const Text('Reject'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        textStyle: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: cs.outline.withValues(alpha: 0.3), width: 1),
        ),
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_note_rounded, size: 16),
                SizedBox(width: 6),
                Text('Fill Form'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 16),
                SizedBox(width: 6),
                Text('Step History'),
              ],
            ),
          ),
        ],
        labelColor: AppColors.primary,
        unselectedLabelColor: cs.onSurface.withValues(alpha: 0.55),
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
      ),
    );
  }

  Widget _buildFormTab(
      BuildContext context, MyTask task, ColorScheme cs, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.formName.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.dynamic_form_outlined,
              label: task.formName,
            ),
            const SizedBox(height: 16),
          ],
          if (task.formFields.isEmpty)
            _buildNoFormMessage(cs)
          else
            ...task.formFields.map((field) => _buildFormField(field, cs)),
          const SizedBox(height: 24),
          _buildNextUserSection(context, task, cs, isDark),
          const SizedBox(height: 24),
          _buildSubmitButton(context, task),
        ],
      ),
    );
  }

  Widget _buildNoFormMessage(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No form assigned to this step. You can approve it directly.',
              style: TextStyle(
                fontSize: 13.5,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(Map<String, dynamic> field, ColorScheme cs) {
    final fieldId = (field['id'] ?? field['name'] ?? '').toString();
    final label = (field['label'] ?? fieldId).toString();
    final type = (field['type'] ?? 'text').toString().toLowerCase();
    final required = field['required'] == true;
    final hint = (field['placeholder'] ?? field['hint'] ?? '').toString();

    Widget input;
    switch (type) {
      case 'textarea':
      case 'longtext':
        input = TextFormField(
          maxLines: 4,
          decoration: _inputDeco(label, hint, required),
          onChanged: (v) => setState(() => _formValues[fieldId] = v),
        );
        break;
      case 'number':
      case 'integer':
        input = TextFormField(
          keyboardType: TextInputType.number,
          decoration: _inputDeco(label, hint, required),
          onChanged: (v) =>
              setState(() => _formValues[fieldId] = num.tryParse(v) ?? v),
        );
        break;
      case 'boolean':
      case 'checkbox':
        input = SwitchListTile(
          title: Text(label,
              style: TextStyle(fontSize: 13.5, color: cs.onSurface)),
          value: _formValues[fieldId] == true,
          onChanged: (v) => setState(() => _formValues[fieldId] = v),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        );
        break;
      case 'select':
      case 'dropdown':
        final options =
            (field['options'] as List<dynamic>? ?? []).map((o) {
          if (o is Map) return o['value']?.toString() ?? o.toString();
          return o.toString();
        }).toList();
        input = DropdownButtonFormField<String>(
          value: _formValues[fieldId]?.toString(),
          decoration: _inputDeco(label, hint, required),
          items: options
              .map((o) =>
                  DropdownMenuItem<String>(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => setState(() => _formValues[fieldId] = v),
        );
        break;
      case 'date':
        input = TextFormField(
          readOnly: true,
          decoration: _inputDeco(label, hint, required).copyWith(
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          controller: TextEditingController(
            text: _formValues[fieldId]?.toString() ?? '',
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2040),
            );
            if (picked != null) {
              setState(() =>
                  _formValues[fieldId] = picked.toIso8601String().split('T').first);
            }
          },
        );
        break;
      default:
        input = TextFormField(
          decoration: _inputDeco(label, hint, required),
          onChanged: (v) => setState(() => _formValues[fieldId] = v),
        );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: type == 'boolean' || type == 'checkbox' ? input : input,
    );
  }

  InputDecoration _inputDeco(String label, String hint, bool required) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: hint.isNotEmpty ? hint : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildNextUserSection(
      BuildContext context, MyTask task, ColorScheme cs, bool isDark) {
    if (task.nextNodeRoleUsers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add_outlined,
                  size: 16,
                  color: AppColors.accent.withValues(alpha: 0.8)),
              const SizedBox(width: 8),
              Text(
                'Assign Next Step To',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Round-robin toggle
          Row(
            children: [
              Switch(
                value: _useRoundRobin,
                onChanged: (v) => setState(() {
                  _useRoundRobin = v;
                  if (v) _selectedNextUserId = null;
                }),
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-assign (Round Robin)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'System picks the least-loaded user automatically',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_useRoundRobin) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedNextUserId,
              decoration: InputDecoration(
                labelText: 'Select user for next step',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    size: 18),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('— Let system decide —',
                      style: TextStyle(fontSize: 13)),
                ),
                ...task.nextNodeRoleUsers.map((u) => DropdownMenuItem<String>(
                      value: u.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              u.initials,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(u.fullName,
                                  style: const TextStyle(fontSize: 13)),
                              Text(u.email,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.lightTextSecondary)),
                            ],
                          ),
                        ],
                      ),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedNextUserId = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, MyTask task) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : () => _submit(context, task),
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: Text(
          _submitting ? 'Submitting…' : 'Submit & Advance',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(
      BuildContext context, MyTask task, ColorScheme cs, bool isDark) {
    if (task.previousSteps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 48,
                color: cs.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            Text(
              'No previous steps',
              style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 4),
            Text(
              'This is the first step in the flow.',
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.35)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: task.previousSteps.length,
      itemBuilder: (ctx, i) {
        final step = task.previousSteps[i];
        final isLast = i == task.previousSteps.length - 1;
        return _StepHistoryCard(step: step, isLast: isLast);
      },
    );
  }

  Future<void> _submit(BuildContext context, MyTask task) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _submitting = true);
    try {
      await ref.read(taskListProvider.notifier).submitTask(
            instanceId: task.instanceId,
            formData: _formValues,
            nextUserId: _selectedNextUserId,
            useRoundRobin: _useRoundRobin,
          );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('Task submitted! ${task.flowName} advanced.'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        router.go('/tasks');
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showRejectDialog(BuildContext context, MyTask task) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Text('Reject Step'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will reject the current step. Optionally provide a reason.',
              style: TextStyle(
                  fontSize: 13.5,
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectCommentCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Rejection reason (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _rejecting = true);
      try {
        await ref.read(taskListProvider.notifier).rejectTask(
              instanceId: task.instanceId,
              comment: _rejectCommentCtrl.text.trim().isNotEmpty
                  ? _rejectCommentCtrl.text.trim()
                  : null,
            );
        if (mounted) {
          router.go('/tasks');
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _rejecting = false);
      }
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

class _StepHistoryCard extends StatelessWidget {
  final StepHistoryItem step;
  final bool isLast;

  const _StepHistoryCard({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = step.status == 'COMPLETED';
    final isRejected = step.status == 'REJECTED';

    final statusColor = isCompleted
        ? AppColors.success
        : isRejected
            ? AppColors.error
            : AppColors.warning;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.4), width: 2),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : isRejected
                          ? Icons.close_rounded
                          : Icons.hourglass_empty_rounded,
                  size: 14,
                  color: statusColor,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: cs.outline.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.nodeLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCompleted
                              ? 'Completed'
                              : isRejected
                                  ? 'Rejected'
                                  : 'Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (step.roleName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 12,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 4),
                        Text(
                          step.roleName,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        if (step.filledByUser != null) ...[
                          const SizedBox(width: 8),
                          Text('·',
                              style: TextStyle(
                                  color: cs.onSurface
                                      .withValues(alpha: 0.3))),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 9,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              step.filledByUser!.initials,
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            step.filledByUser!.fullName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (step.formData.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(
                      'Submitted Data',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...step.formData.entries.map((e) {
                      final fieldDef = step.formFields.firstWhere(
                        (f) =>
                            f['id']?.toString() == e.key ||
                            f['name']?.toString() == e.key,
                        orElse: () => {},
                      );
                      final label = fieldDef['label']?.toString() ?? e.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value?.toString() ?? '—',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (step.rejectionComment.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              step.rejectionComment,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (step.completedAt != null || step.rejectedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(step.completedAt ?? step.rejectedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy · HH:mm').format(dt);
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _NodeBadge extends StatelessWidget {
  final String label;

  const _NodeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.nodeStep.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppColors.nodeStep.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.radio_button_checked_rounded,
              size: 12, color: AppColors.nodeStep),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.nodeStep,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String roleName;

  const _RoleBadge({required this.roleName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, size: 12, color: AppColors.accent),
          const SizedBox(width: 5),
          Text(
            roleName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
