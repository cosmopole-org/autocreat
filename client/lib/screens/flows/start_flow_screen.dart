import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/form_field_widgets.dart';
import '../../models/form_definition.dart';

class StartFlowScreen extends ConsumerStatefulWidget {
  final String flowId;

  const StartFlowScreen({super.key, required this.flowId});

  @override
  ConsumerState<StartFlowScreen> createState() => _StartFlowScreenState();
}

class _StartFlowScreenState extends ConsumerState<StartFlowScreen> {
  final Map<String, dynamic> _formValues = {};
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startableAsync = ref.watch(startableFlowsProvider);

    return startableAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Start Flow')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (flows) {
        final flow = flows.where((f) => f.flowId == widget.flowId).firstOrNull;
        if (flow == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Start Flow')),
            body: const Center(child: Text('Flow not found or not accessible.')),
          );
        }
        return _buildContent(context, flow, cs, isDark);
      },
    );
  }

  Widget _buildContent(
      BuildContext context, StartableFlow flow, ColorScheme cs, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_outline_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flow.flowName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (flow.startNodeLabel.isNotEmpty)
                    Text(
                      flow.startNodeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (flow.flowDescription.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16,
                              color: AppColors.primary.withValues(alpha: 0.7)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              flow.flowDescription,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (flow.formFields.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.dynamic_form_outlined,
                      label: flow.formName.isNotEmpty
                          ? flow.formName
                          : 'Start Form',
                    ),
                    const SizedBox(height: 16),
                    ...flow.formFields
                        .map((f) => _buildFormField(f, cs)),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              color: AppColors.primary.withValues(alpha: 0.7)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No form required for this step. Click Start to begin the flow.',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: cs.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildBottomBar(context, flow, cs, isDark),
        ],
      ),
    );
  }

  Widget _buildFormField(Map<String, dynamic> fieldMap, ColorScheme cs) {
    final field = AppFormField.fromJson(fieldMap);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FormFieldRenderer(
        field: field,
        value: _formValues[field.id],
        onChanged: (v) => setState(() => _formValues[field.id] = v),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, StartableFlow flow,
      ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _submitting ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _submitting ? null : () => _submit(context, flow),
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(_submitting ? 'Starting…' : 'Start Flow'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, StartableFlow flow) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _submitting = true);
    try {
      await ref.read(taskListProvider.notifier).startFlow(
            flowId: flow.flowId,
            formData: _formValues,
          );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('${flow.flowName} started successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        router.go('/tasks');
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to start flow: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
        Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
