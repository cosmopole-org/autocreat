import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils.dart';
import '../../models/flow.dart';
import '../../providers/form_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_colors.dart';
import '../../data/mock_ui_text.dart';

class FlowNodeEditor extends ConsumerStatefulWidget {
  final FlowNode node;
  final ValueChanged<FlowNode> onUpdate;
  final VoidCallback onDelete;

  /// When `true`, strips the duplicate header row (the sheet provides its own).
  final bool compact;

  const FlowNodeEditor({
    super.key,
    required this.node,
    required this.onUpdate,
    required this.onDelete,
    this.compact = false,
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
    _descController =
        TextEditingController(text: widget.node.description ?? '');
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

    // Panel background: slightly different from cards so inner widgets stand out
    final panelBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header (only for side-panel; sheet provides its own) ──
        if (!widget.compact) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: nodeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AppUtils.getNodeTypeIcon(node.type.name),
                  color: nodeColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(MockUiText.nodeProperties,
                        style: Theme.of(context).textTheme.titleSmall),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: nodeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        node.type.name.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9,
                            color: nodeColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 18),
                onPressed: widget.onDelete,
                tooltip: MockUiText.deleteNode,
                style: IconButton.styleFrom(
                  backgroundColor:
                      AppColors.error.withValues(alpha: 0.07),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // ── Label ─────────────────────────────────────────────────
        _FieldLabel(MockUiText.nodeLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _labelController,
          decoration: const InputDecoration(
            hintText: MockUiText.enterLabelEllipsis,
            prefixIcon: Icon(Icons.label_outline_rounded, size: 18),
          ),
          onChanged: (v) => widget.onUpdate(node.copyWith(label: v)),
        ),
        const SizedBox(height: 14),

        // ── Description ───────────────────────────────────────────
        _FieldLabel(MockUiText.description),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descController,
          decoration: const InputDecoration(
            hintText: MockUiText.optionalDescriptionEllipsis,
            prefixIcon: Icon(Icons.notes_rounded, size: 18),
          ),
          maxLines: 2,
          onChanged: (v) =>
              widget.onUpdate(node.copyWith(description: v)),
        ),
        const SizedBox(height: 16),

        // ── Role assignment ────────────────────────────────────────
        _FieldLabel(MockUiText.assignedRole),
        const SizedBox(height: 6),
        rolesAsync.when(
          loading: () =>
              const LinearProgressIndicator(minHeight: 2),
          error: (_, __) =>
              _ErrorTile(MockUiText.errorLoadingRoles),
          data: (roles) => DropdownButtonFormField<String?>(
            value: node.assignedRoleId,
            items: [
              const DropdownMenuItem(
                  value: null,
                  child: Text(MockUiText.noRoleAssigned)),
              ...roles.map((r) => DropdownMenuItem(
                  value: r.id, child: Text(r.name))),
            ],
            onChanged: (v) =>
                widget.onUpdate(node.copyWith(assignedRoleId: v)),
            decoration: const InputDecoration(
              hintText: MockUiText.selectRoleEllipsis,
              prefixIcon:
                  Icon(Icons.shield_outlined, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Form assignment ───────────────────────────────────────
        _FieldLabel(MockUiText.assignedForm),
        const SizedBox(height: 6),
        formsAsync.when(
          loading: () =>
              const LinearProgressIndicator(minHeight: 2),
          error: (_, __) =>
              _ErrorTile(MockUiText.errorLoadingForms),
          data: (forms) => DropdownButtonFormField<String?>(
            value: node.assignedFormId,
            items: [
              const DropdownMenuItem(
                  value: null,
                  child: Text(MockUiText.noFormAssigned)),
              ...forms.map((f) => DropdownMenuItem(
                  value: f.id, child: Text(f.name))),
            ],
            onChanged: (v) =>
                widget.onUpdate(node.copyWith(assignedFormId: v)),
            decoration: const InputDecoration(
              hintText: MockUiText.selectFormEllipsis,
              prefixIcon:
                  Icon(Icons.dynamic_form_outlined, size: 18),
            ),
          ),
        ),

        // ── Decision branches ─────────────────────────────────────
        if (node.type == NodeType.decision) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Text(MockUiText.branches,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(MockUiText.addBranch),
                onPressed: () {
                  const uuid = Uuid();
                  final branch = BranchCondition(
                    id: uuid.v4(),
                    label: MockUiText.branchName(node.branches.length + 1),
                  );
                  widget.onUpdate(
                      node.copyWith(branches: [...node.branches, branch]));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...node.branches.asMap().entries.map((e) {
            final branch = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.5)
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.primaryLight.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            branch.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ),
                        if (branch.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(MockUiText.defaultText,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700)),
                          ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            final newBranches =
                                List<BranchCondition>.from(
                                    node.branches)
                                  ..removeAt(e.key);
                            widget.onUpdate(node.copyWith(
                                branches: newBranches));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: branch.condition ?? '',
                      decoration: InputDecoration(
                        hintText: MockUiText.conditionEGStatusApproved,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        fillColor: isDark
                            ? AppColors.darkCard
                            : Colors.white,
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

        // ── Position info ──────────────────────────────────────────
        const SizedBox(height: 16),
        Divider(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 13,
                color: isDark
                    ? AppColors.darkTextHint
                    : AppColors.lightTextHint),
            const SizedBox(width: 5),
            Text(MockUiText.position,
                style: Theme.of(context).textTheme.labelSmall),
            const Spacer(),
            Text(
              MockUiText.nodePosition(node.x, node.y),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );

    // Side-panel wraps in its own Container with border + scroll
    if (widget.compact) return content;

    return Container(
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  const _ErrorTile(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Text(message,
              style: const TextStyle(
                  color: AppColors.error, fontSize: 12)),
        ],
      ),
    );
  }
}
