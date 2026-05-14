import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils.dart';
import '../../models/flow.dart';
import '../../providers/form_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_colors.dart';

class FlowNodeEditor extends ConsumerStatefulWidget {
  final FlowNode node;
  final ValueChanged<FlowNode> onUpdate;
  final VoidCallback onDelete;

  const FlowNodeEditor({
    super.key,
    required this.node,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  ConsumerState<FlowNodeEditor> createState() => _FlowNodeEditorState();
}

class _FlowNodeEditorState extends ConsumerState<FlowNodeEditor> {
  late TextEditingController _labelController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.node.label);
    _descController = TextEditingController(text: widget.node.description ?? '');
  }

  @override
  void didUpdateWidget(FlowNodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) {
      _labelController.text = widget.node.label;
      _descController.text = widget.node.description ?? '';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final node = widget.node;
    final nodeColor = AppUtils.getNodeTypeColor(node.type.name);
    final rolesAsync = ref.watch(rolesProvider(null));
    final formsAsync = ref.watch(formsProvider(null));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: nodeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    AppUtils.getNodeTypeIcon(node.type.name),
                    color: nodeColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Node Properties',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        node.type.name.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            color: nodeColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete node',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Label
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Node label',
                prefixIcon: Icon(Icons.label_outline, size: 18),
              ),
              onChanged: (v) => widget.onUpdate(node.copyWith(label: v)),
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.notes, size: 18),
              ),
              maxLines: 2,
              onChanged: (v) =>
                  widget.onUpdate(node.copyWith(description: v)),
            ),
            const SizedBox(height: 16),

            // Role assignment
            Text('Assigned Role',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            rolesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading roles'),
              data: (roles) => DropdownButtonFormField<String?>(
                value: node.assignedRoleId,
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('No role')),
                  ...roles.map((r) =>
                      DropdownMenuItem(value: r.id, child: Text(r.name))),
                ],
                onChanged: (v) =>
                    widget.onUpdate(node.copyWith(assignedRoleId: v)),
                decoration: const InputDecoration(
                  hintText: 'Select role...',
                  prefixIcon: Icon(Icons.shield_outlined, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Form assignment
            Text('Assigned Form',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            formsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading forms'),
              data: (forms) => DropdownButtonFormField<String?>(
                value: node.assignedFormId,
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('No form')),
                  ...forms.map((f) =>
                      DropdownMenuItem(value: f.id, child: Text(f.name))),
                ],
                onChanged: (v) =>
                    widget.onUpdate(node.copyWith(assignedFormId: v)),
                decoration: const InputDecoration(
                  hintText: 'Select form...',
                  prefixIcon: Icon(Icons.dynamic_form_outlined, size: 18),
                ),
              ),
            ),

            // Branches for decision nodes
            if (node.type == NodeType.decision) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Branches',
                      style: Theme.of(context).textTheme.labelLarge),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add'),
                    onPressed: () {
                      const uuid = Uuid();
                      final branch = BranchCondition(
                        id: uuid.v4(),
                        label: 'Branch ${node.branches.length + 1}',
                      );
                      widget.onUpdate(node.copyWith(
                          branches: [...node.branches, branch]));
                    },
                  ),
                ],
              ),
              ...node.branches.asMap().entries.map((e) {
                final branch = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.primaryLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(branch.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                            if (branch.isDefault)
                              const Text('DEFAULT',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.success)),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                final newBranches =
                                    List<BranchCondition>.from(
                                        node.branches)
                                      ..removeAt(e.key);
                                widget.onUpdate(
                                    node.copyWith(branches: newBranches));
                              },
                              child: const Icon(Icons.close,
                                  size: 14, color: AppColors.error),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          initialValue: branch.condition ?? '',
                          decoration: const InputDecoration(
                            hintText: 'Condition (e.g. status == approved)',
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 12),
                          onChanged: (v) {
                            final newBranches =
                                List<BranchCondition>.from(node.branches);
                            newBranches[e.key] =
                                branch.copyWith(condition: v);
                            widget.onUpdate(
                                node.copyWith(branches: newBranches));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            // Node position info
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Position',
                    style: Theme.of(context).textTheme.labelSmall),
                const Spacer(),
                Text(
                  'x: ${node.x.toInt()}, y: ${node.y.toInt()}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
