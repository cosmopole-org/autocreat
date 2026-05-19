import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils.dart';
import '../../models/binding.dart';
import '../../models/flow.dart';
import '../../models/letter_template.dart';
import '../../models/model_definition.dart';
import '../../providers/binding_provider.dart';
import '../../providers/form_provider.dart';
import '../../providers/letter_provider.dart';
import '../../providers/model_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_colors.dart';
import '../../data/ui_text.dart';

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
    final nodeColor = AppUtils.getNodeTypeColor(node.type.name, isDark: isDark);
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
                    Text(UiText.nodeProperties,
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
                        node.type.displayName.toUpperCase(),
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
                tooltip: UiText.deleteNode,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.07),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // ── Label ─────────────────────────────────────────────────
        _FieldLabel(UiText.nodeLabel),
        const SizedBox(height: 6),
        TextFormField(
          controller: _labelController,
          decoration: InputDecoration(
            hintText: UiText.enterLabelEllipsis,
            prefixIcon: const Icon(Icons.label_outline_rounded, size: 18),
          ),
          onChanged: (v) => widget.onUpdate(node.copyWith(label: v)),
        ),
        const SizedBox(height: 14),

        // ── Description ───────────────────────────────────────────
        _FieldLabel(UiText.description),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descController,
          decoration: InputDecoration(
            hintText: UiText.optionalDescriptionEllipsis,
            prefixIcon: const Icon(Icons.notes_rounded, size: 18),
          ),
          maxLines: 2,
          onChanged: (v) => widget.onUpdate(node.copyWith(description: v)),
        ),
        const SizedBox(height: 16),

        // ── Role assignment ────────────────────────────────────────
        _FieldLabel(UiText.assignedRole),
        const SizedBox(height: 6),
        rolesAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (_, __) => _ErrorTile(UiText.errorLoadingRoles),
          data: (roles) => DropdownButtonFormField<String?>(
            value: node.assignedRoleId,
            items: [
              DropdownMenuItem(
                  value: null, child: Text(UiText.noRoleAssigned)),
              ...roles.map(
                  (r) => DropdownMenuItem(value: r.id, child: Text(r.name))),
            ],
            onChanged: (v) => widget.onUpdate(node.copyWith(assignedRoleId: v)),
            decoration: InputDecoration(
              hintText: UiText.selectRoleEllipsis,
              prefixIcon: const Icon(Icons.shield_outlined, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Form assignment ───────────────────────────────────────
        _FieldLabel(UiText.assignedForm),
        const SizedBox(height: 6),
        formsAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (_, __) => _ErrorTile(UiText.errorLoadingForms),
          data: (forms) => DropdownButtonFormField<String?>(
            value: node.assignedFormId,
            items: [
              DropdownMenuItem(
                  value: null, child: Text(UiText.noFormAssigned)),
              ...forms.map(
                  (f) => DropdownMenuItem(value: f.id, child: Text(f.name))),
            ],
            onChanged: (v) => widget.onUpdate(node.copyWith(assignedFormId: v)),
            decoration: InputDecoration(
              hintText: UiText.selectFormEllipsis,
              prefixIcon: const Icon(Icons.dynamic_form_outlined, size: 18),
            ),
          ),
        ),

        // ── Decision branches ─────────────────────────────────────
        if (node.type == NodeType.decision) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Text(UiText.branches,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(UiText.addBranch),
                onPressed: () {
                  const uuid = Uuid();
                  final branch = BranchCondition(
                    id: uuid.v4(),
                    label: UiText.branchName(node.branches.length + 1),
                  );
                  widget.onUpdate(
                      node.copyWith(branches: [...node.branches, branch]));
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
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
                            color: AppColors.primary.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            branch.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                        if (branch.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(UiText.defaultText,
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700)),
                          ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            final newBranches =
                                List<BranchCondition>.from(node.branches)
                                  ..removeAt(e.key);
                            widget.onUpdate(node.copyWith(branches: newBranches));
                          },
                          icon: const Icon(Icons.close_rounded, size: 14),
                          color: AppColors.error,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.error.withValues(alpha: 0.10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.all(4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(24, 24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: branch.condition ?? '',
                      decoration: InputDecoration(
                        hintText: UiText.conditionEGStatusApproved,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (v) {
                        final newBranches =
                            List<BranchCondition>.from(node.branches);
                        newBranches[e.key] = branch.copyWith(condition: v);
                        widget.onUpdate(node.copyWith(branches: newBranches));
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],

        // ── Model Bindings ─────────────────────────────────────────
        if (node.id.isNotEmpty) ...[
          const SizedBox(height: 20),
          _ModelBindingsSection(nodeId: node.id),
        ],

        // ── Letter Assignments ─────────────────────────────────────
        if (node.id.isNotEmpty) ...[
          const SizedBox(height: 12),
          _LetterAssignmentsSection(nodeId: node.id),
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
                color:
                    isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
            const SizedBox(width: 5),
            Text(UiText.position,
                style: Theme.of(context).textTheme.labelSmall),
            const Spacer(),
            Text(
              UiText.nodePosition(node.x, node.y),
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

// ═══════════════════════════════════════════════════════════════
// Model Bindings Panel
// ═══════════════════════════════════════════════════════════════

class _ModelBindingsSection extends ConsumerStatefulWidget {
  final String nodeId;
  const _ModelBindingsSection({required this.nodeId});

  @override
  ConsumerState<_ModelBindingsSection> createState() =>
      _ModelBindingsSectionState();
}

class _ModelBindingsSectionState extends ConsumerState<_ModelBindingsSection> {
  bool _saving = false;

  Future<void> _saveBinding(FormModelBinding binding) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(bindingRepositoryProvider)
          .saveBinding(widget.nodeId, binding);
      ref.invalidate(nodeBindingsProvider(widget.nodeId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving binding: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteBinding(String id) async {
    try {
      await ref.read(bindingRepositoryProvider).deleteBinding(id);
      ref.invalidate(nodeBindingsProvider(widget.nodeId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting binding: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bindingsAsync = ref.watch(nodeBindingsProvider(widget.nodeId));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.sync_alt_rounded,
              size: 18,
              color:
                  isDark ? AppColors.darkTextSecondary : AppColors.primary),
          title: Text('Model Bindings',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)),
          childrenPadding:
              const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            bindingsAsync.when(
              loading: () =>
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(minHeight: 2)),
              error: (e, _) => const _ErrorTile('Failed to load bindings'),
              data: (bindings) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...bindings.map((b) => _BindingCard(
                        binding: b,
                        onSave: _saveBinding,
                        onDelete: () => _deleteBinding(b.id),
                        saving: _saving,
                      )),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Binding'),
                      onPressed: _saving
                          ? null
                          : () => _saveBinding(
                              FormModelBinding.empty(widget.nodeId)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BindingCard extends ConsumerStatefulWidget {
  final FormModelBinding binding;
  final Future<void> Function(FormModelBinding) onSave;
  final VoidCallback onDelete;
  final bool saving;

  const _BindingCard({
    required this.binding,
    required this.onSave,
    required this.onDelete,
    required this.saving,
  });

  @override
  ConsumerState<_BindingCard> createState() => _BindingCardState();
}

class _BindingCardState extends ConsumerState<_BindingCard> {
  late FormModelBinding _binding;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _binding = widget.binding;
    _nameCtrl = TextEditingController(text: _binding.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addRule() {
    final newRule = FormModelBindingRule(
      id: '',
      bindingId: _binding.id,
      formFieldKey: '',
      modelDefinitionId: '',
      modelInstanceKey: 'default',
      modelFieldKey: '',
    );
    setState(() {
      _binding = _binding.copyWith(rules: [..._binding.rules, newRule]);
    });
  }

  void _updateRule(int index, FormModelBindingRule updated) {
    final newRules = List<FormModelBindingRule>.from(_binding.rules);
    newRules[index] = updated;
    setState(() => _binding = _binding.copyWith(rules: newRules));
  }

  void _removeRule(int index) {
    final newRules = List<FormModelBindingRule>.from(_binding.rules)
      ..removeAt(index);
    setState(() => _binding = _binding.copyWith(rules: newRules));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modelsAsync = ref.watch(modelsProvider(null));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBorder.withValues(alpha: 0.3)
            : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Binding name',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) =>
                      setState(() => _binding = _binding.copyWith(name: v)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: AppColors.error),
                onPressed: widget.onDelete,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(28, 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Rules
          ...(_binding.rules.asMap().entries.map((e) {
            final idx = e.key;
            final rule = e.value;
            return modelsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (models) => _RuleRow(
                rule: rule,
                models: models,
                onUpdate: (updated) => _updateRule(idx, updated),
                onRemove: () => _removeRule(idx),
              ),
            );
          })),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                label: const Text('Add Rule'),
                onPressed: _addRule,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: widget.saving
                    ? null
                    : () => widget.onSave(
                        _binding.copyWith(name: _nameCtrl.text)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                  minimumSize: const Size(0, 30),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatefulWidget {
  final FormModelBindingRule rule;
  final List<ModelDefinition> models;
  final ValueChanged<FormModelBindingRule> onUpdate;
  final VoidCallback onRemove;

  const _RuleRow({
    required this.rule,
    required this.models,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_RuleRow> createState() => _RuleRowState();
}

class _RuleRowState extends State<_RuleRow> {
  late TextEditingController _fieldKeyCtrl;
  late TextEditingController _instanceKeyCtrl;
  late TextEditingController _sourceNodeCtrl;
  String? _selectedModelId;
  String? _selectedFieldKey;

  @override
  void initState() {
    super.initState();
    _fieldKeyCtrl = TextEditingController(text: widget.rule.formFieldKey);
    _instanceKeyCtrl =
        TextEditingController(text: widget.rule.modelInstanceKey);
    _sourceNodeCtrl =
        TextEditingController(text: widget.rule.sourceNodeId ?? '');
    _selectedModelId = widget.rule.modelDefinitionId.isNotEmpty
        ? widget.rule.modelDefinitionId
        : null;
    _selectedFieldKey = widget.rule.modelFieldKey.isNotEmpty
        ? widget.rule.modelFieldKey
        : null;
  }

  @override
  void dispose() {
    _fieldKeyCtrl.dispose();
    _instanceKeyCtrl.dispose();
    _sourceNodeCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onUpdate(widget.rule.copyWith(
      formFieldKey: _fieldKeyCtrl.text,
      modelDefinitionId: _selectedModelId ?? '',
      modelInstanceKey:
          _instanceKeyCtrl.text.isEmpty ? 'default' : _instanceKeyCtrl.text,
      modelFieldKey: _selectedFieldKey ?? '',
      sourceNodeId:
          _sourceNodeCtrl.text.isEmpty ? null : _sourceNodeCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedModel = widget.models
        .where((m) => m.id == _selectedModelId)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _fieldKeyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Form field key',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 14, color: AppColors.error),
                onPressed: widget.onRemove,
                padding: const EdgeInsets.all(2),
                style: IconButton.styleFrom(
                  minimumSize: const Size(22, 22),
                  backgroundColor: AppColors.error.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            value: _selectedModelId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Model',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            style: const TextStyle(fontSize: 12),
            items: [
              const DropdownMenuItem(value: null, child: Text('Select model…')),
              ...widget.models.map((m) =>
                  DropdownMenuItem(value: m.id, child: Text(m.name))),
            ],
            onChanged: (v) {
              setState(() {
                _selectedModelId = v;
                _selectedFieldKey = null;
              });
              _emit();
            },
          ),
          if (selectedModel != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedFieldKey,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Model field',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    style: const TextStyle(fontSize: 12),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Select field…')),
                      ...selectedModel.fields.map((f) =>
                          DropdownMenuItem(
                              value: f.name, child: Text(f.name))),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedFieldKey = v);
                      _emit();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextFormField(
                    controller: _instanceKeyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Instance key',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          TextFormField(
            controller: _sourceNodeCtrl,
            decoration: const InputDecoration(
              labelText: 'Source node ID (blank = this node)',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            style: const TextStyle(fontSize: 11),
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Letter Assignments Panel
// ═══════════════════════════════════════════════════════════════

class _LetterAssignmentsSection extends ConsumerWidget {
  final String nodeId;
  const _LetterAssignmentsSection({required this.nodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignmentsAsync = ref.watch(nodeLetterAssignmentsProvider(nodeId));
    final lettersAsync = ref.watch(lettersProvider(null));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.mail_outline_rounded,
              size: 18,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.primary),
          title: Text('Letter Assignments',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            assignmentsAsync.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(minHeight: 2)),
              error: (e, _) =>
                  const _ErrorTile('Failed to load letter assignments'),
              data: (assignments) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...assignments.map((a) => _LetterAssignmentCard(
                        assignment: a,
                        nodeId: nodeId,
                      )),
                  const SizedBox(height: 8),
                  lettersAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (letters) => _AssignLetterButton(
                      nodeId: nodeId,
                      letters: letters,
                      existingIds: assignments
                          .map((a) => a.letterTemplateId)
                          .toSet(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterAssignmentCard extends ConsumerStatefulWidget {
  final NodeLetterAssignment assignment;
  final String nodeId;

  const _LetterAssignmentCard({
    required this.assignment,
    required this.nodeId,
  });

  @override
  ConsumerState<_LetterAssignmentCard> createState() =>
      _LetterAssignmentCardState();
}

class _LetterAssignmentCardState
    extends ConsumerState<_LetterAssignmentCard> {
  late NodeLetterAssignment _assignment;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(bindingRepositoryProvider)
          .saveNodeLetterAssignment(widget.nodeId, _assignment);
      ref.invalidate(nodeLetterAssignmentsProvider(widget.nodeId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    try {
      await ref
          .read(bindingRepositoryProvider)
          .deleteNodeLetterAssignment(_assignment.id);
      ref.invalidate(nodeLetterAssignmentsProvider(widget.nodeId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBorder.withValues(alpha: 0.3)
            : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _assignment.letterName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: AppColors.error),
                onPressed: _delete,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(28, 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Generation settings
          _SettingToggle(
            label: 'Auto-generate after approval',
            value: _assignment.autoGenerateOnApprove,
            icon: Icons.auto_awesome_rounded,
            onChanged: (v) => setState(() =>
                _assignment = _assignment.copyWith(autoGenerateOnApprove: v)),
          ),
          const SizedBox(height: 6),
          _SettingToggle(
            label: 'Allow manual generation before approval',
            value: _assignment.allowBeforeApprove,
            icon: Icons.edit_note_rounded,
            onChanged: (v) => setState(() =>
                _assignment = _assignment.copyWith(allowBeforeApprove: v)),
          ),
          // Variable bindings
          if (_assignment.letterVariables.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Variable Bindings',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    letterSpacing: 0.3)),
            const SizedBox(height: 6),
            ..._assignment.letterVariables.map((varName) {
              final binding = _assignment.variableBindings[varName] ??
                  const VariableBindingEntry(formFieldKey: '');
              return _VarBindingRow(
                varName: varName,
                binding: binding,
                onChanged: (updated) {
                  final newVb =
                      Map<String, VariableBindingEntry>.from(
                          _assignment.variableBindings)
                        ..[varName] = updated;
                  setState(() => _assignment =
                      _assignment.copyWith(variableBindings: newVb));
                },
              );
            }),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
                minimumSize: const Size(0, 30),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final String label;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: value
                  ? AppColors.primary
                  : isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _VarBindingRow extends StatefulWidget {
  final String varName;
  final VariableBindingEntry binding;
  final ValueChanged<VariableBindingEntry> onChanged;

  const _VarBindingRow({
    required this.varName,
    required this.binding,
    required this.onChanged,
  });

  @override
  State<_VarBindingRow> createState() => _VarBindingRowState();
}

class _VarBindingRowState extends State<_VarBindingRow> {
  late TextEditingController _fieldCtrl;
  late TextEditingController _nodeCtrl;

  @override
  void initState() {
    super.initState();
    _fieldCtrl = TextEditingController(text: widget.binding.formFieldKey);
    _nodeCtrl =
        TextEditingController(text: widget.binding.sourceNodeId ?? '');
  }

  @override
  void dispose() {
    _fieldCtrl.dispose();
    _nodeCtrl.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(VariableBindingEntry(
        formFieldKey: _fieldCtrl.text,
        sourceNodeId: _nodeCtrl.text.isEmpty ? null : _nodeCtrl.text,
      ));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text('{{${widget.varName}}}',
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace')),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Icon(Icons.arrow_forward_rounded,
                size: 14, color: AppColors.primary),
          ),
          Expanded(
            child: Column(
              children: [
                TextFormField(
                  controller: _fieldCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Form field key',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  style: const TextStyle(fontSize: 11),
                  onChanged: (_) => _emit(),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _nodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Source node ID (blank = any step)',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  style: const TextStyle(fontSize: 10),
                  onChanged: (_) => _emit(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignLetterButton extends ConsumerWidget {
  final String nodeId;
  final List<LetterTemplate> letters;
  final Set<String> existingIds;

  const _AssignLetterButton({
    required this.nodeId,
    required this.letters,
    required this.existingIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = letters
        .where((l) => !existingIds.contains(l.id))
        .toList();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('Assign Letter'),
        onPressed: available.isEmpty
            ? null
            : () async {
                final picked = await showDialog<LetterTemplate>(
                  context: context,
                  builder: (ctx) => _LetterPickerDialog(letters: available),
                );
                if (picked == null) return;
                final assignment = NodeLetterAssignment(
                  id: '',
                  flowNodeId: nodeId,
                  letterTemplateId: picked.id,
                  letterName: picked.name,
                  letterVariables: picked.variables,
                  autoGenerateOnApprove: false,
                  allowBeforeApprove: true,
                  variableBindings: {},
                );
                try {
                  await ref
                      .read(bindingRepositoryProvider)
                      .saveNodeLetterAssignment(nodeId, assignment);
                  ref.invalidate(nodeLetterAssignmentsProvider(nodeId));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')));
                  }
                }
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _LetterPickerDialog extends StatelessWidget {
  final List<LetterTemplate> letters;
  const _LetterPickerDialog({required this.letters});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      title: const Text('Assign a Letter Template'),
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightSurface,
      content: SizedBox(
        width: 320,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: letters.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final l = letters[i];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.mail_outline_rounded,
                    size: 16, color: AppColors.primary),
              ),
              title: Text(l.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: l.description != null && l.description!.isNotEmpty
                  ? Text(l.description!,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)
                  : null,
              onTap: () => Navigator.of(ctx).pop(l),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
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
        color:
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
              style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ],
      ),
    );
  }
}
