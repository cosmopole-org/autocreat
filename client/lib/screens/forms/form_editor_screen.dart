import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/form_definition.dart';
import '../../providers/form_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/form_field_widgets.dart';

class FormEditorScreen extends ConsumerStatefulWidget {
  final String formId;

  const FormEditorScreen({super.key, required this.formId});

  @override
  ConsumerState<FormEditorScreen> createState() => _FormEditorScreenState();
}

class _FormEditorScreenState extends ConsumerState<FormEditorScreen> {
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    final repo = ref.read(formRepositoryProvider);
    try {
      if (widget.formId != 'new') {
        final form = await repo.getForm(widget.formId);
        ref.read(formEditorProvider.notifier).loadForm(form);
      } else {
        ref.read(formEditorProvider.notifier).newForm('');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(formRepositoryProvider);
      await ref.read(formEditorProvider.notifier).save(repo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Form saved'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addField(FormFieldType type) {
    const uuid = Uuid();
    final field = FormField(
      id: uuid.v4(),
      type: type,
      label: type.displayName,
      order: ref.read(formEditorProvider).fields.length,
    );
    ref.read(formEditorProvider.notifier).addField(field);
    ref.read(formEditorProvider.notifier).selectField(field.id);
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(formEditorProvider);
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.forms),
        ),
        title: Row(
          children: [
            Text(editorState.form?.name ?? 'Form Editor'),
            if (editorState.isDirty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Unsaved',
                    style: TextStyle(fontSize: 11, color: AppColors.warning)),
              ),
            ],
          ],
        ),
        actions: [
          AppButton(
            label: 'Save',
            icon: Icons.save_outlined,
            loading: _saving,
            onPressed: _save,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Field palette
          Container(
            width: isDesktop ? 220 : 160,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Field Types',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: FormFieldType.values
                        .map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: FieldPaletteItem(
                                type: t,
                                onTap: () => _addField(t),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Form canvas
          Expanded(
            child: Column(
              children: [
                // Form name editor
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: TextFormField(
                    initialValue: editorState.form?.name ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Form name',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                    onChanged: (v) => ref
                        .read(formEditorProvider.notifier)
                        .updateFormMeta(v, null),
                  ),
                ),

                // Fields list
                Expanded(
                  child: editorState.fields.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_box_outlined,
                                size: 48,
                                color: AppColors.lightTextSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Click a field type to add it',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView(
                          padding: const EdgeInsets.all(16),
                          onReorder: (oldIndex, newIndex) {
                            ref
                                .read(formEditorProvider.notifier)
                                .reorderFields(oldIndex,
                                    newIndex > oldIndex ? newIndex - 1 : newIndex);
                          },
                          children: editorState.fields
                              .asMap()
                              .entries
                              .map(
                                (e) => _FieldCard(
                                  key: ValueKey(e.value.id),
                                  field: e.value,
                                  isSelected:
                                      editorState.selectedFieldId == e.value.id,
                                  onSelect: () => ref
                                      .read(formEditorProvider.notifier)
                                      .selectField(e.value.id),
                                  onDelete: () => ref
                                      .read(formEditorProvider.notifier)
                                      .deleteField(e.value.id),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          ),

          // Field properties panel
          if (editorState.selectedField != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isDesktop ? 280 : 240,
              child: _FieldPropertiesPanel(
                field: editorState.selectedField!,
                onUpdate: (field) => ref
                    .read(formEditorProvider.notifier)
                    .updateField(field),
              ),
            ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final FormField field;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _FieldCard({
    super.key,
    required this.field,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCard
                  : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.drag_indicator,
              size: 18,
              color: AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontSize: 13),
                  ),
                  Text(
                    field.type.displayName +
                        (field.required ? ' · Required' : ''),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: AppColors.error),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldPropertiesPanel extends StatefulWidget {
  final FormField field;
  final ValueChanged<FormField> onUpdate;

  const _FieldPropertiesPanel({required this.field, required this.onUpdate});

  @override
  State<_FieldPropertiesPanel> createState() => _FieldPropertiesPanelState();
}

class _FieldPropertiesPanelState extends State<_FieldPropertiesPanel> {
  late TextEditingController _labelController;
  late TextEditingController _placeholderController;
  late TextEditingController _helpTextController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.field.label);
    _placeholderController =
        TextEditingController(text: widget.field.placeholder ?? '');
    _helpTextController =
        TextEditingController(text: widget.field.helpText ?? '');
  }

  @override
  void didUpdateWidget(_FieldPropertiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.id != widget.field.id) {
      _labelController.text = widget.field.label;
      _placeholderController.text = widget.field.placeholder ?? '';
      _helpTextController.text = widget.field.helpText ?? '';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _placeholderController.dispose();
    _helpTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final field = widget.field;

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
            Row(
              children: [
                Text('Field Properties',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    field.type.displayName,
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label'),
              onChanged: (v) =>
                  widget.onUpdate(field.copyWith(label: v)),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _placeholderController,
              decoration: const InputDecoration(labelText: 'Placeholder'),
              onChanged: (v) =>
                  widget.onUpdate(field.copyWith(placeholder: v)),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _helpTextController,
              decoration: const InputDecoration(labelText: 'Help text'),
              onChanged: (v) =>
                  widget.onUpdate(field.copyWith(helpText: v)),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Required', style: TextStyle(fontSize: 14)),
              value: field.required,
              onChanged: (v) =>
                  widget.onUpdate(field.copyWith(required: v)),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),

            SwitchListTile(
              title: const Text('Read only', style: TextStyle(fontSize: 14)),
              value: field.readOnly,
              onChanged: (v) =>
                  widget.onUpdate(field.copyWith(readOnly: v)),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),

            SwitchListTile(
              title: const Text('Hidden', style: TextStyle(fontSize: 14)),
              value: field.hidden,
              onChanged: (v) =>
                  widget.onUpdate(field.copyWith(hidden: v)),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),

            // Options for dropdown/radio/multiselect
            if (field.type == FormFieldType.dropdown ||
                field.type == FormFieldType.multiselect ||
                field.type == FormFieldType.radio) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Options',
                      style: Theme.of(context).textTheme.labelLarge),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add'),
                    onPressed: () {
                      const uuid = Uuid();
                      final options = List<FormFieldOption>.from(field.options)
                        ..add(FormFieldOption(
                          value: uuid.v4().substring(0, 8),
                          label: 'Option ${field.options.length + 1}',
                        ));
                      widget.onUpdate(field.copyWith(options: options));
                    },
                  ),
                ],
              ),
              ...field.options.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: e.value.label,
                          decoration: InputDecoration(
                            hintText: 'Option ${e.key + 1}',
                            isDense: true,
                          ),
                          onChanged: (v) {
                            final opts = List<FormFieldOption>.from(field.options);
                            opts[e.key] = FormFieldOption(
                                value: e.value.value, label: v);
                            widget.onUpdate(field.copyWith(options: opts));
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          final opts = List<FormFieldOption>.from(field.options)
                            ..removeAt(e.key);
                          widget.onUpdate(field.copyWith(options: opts));
                        },
                        child: const Icon(Icons.remove_circle_outline,
                            size: 16, color: AppColors.error),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
