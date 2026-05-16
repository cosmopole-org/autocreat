import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/form_definition.dart';
import '../../providers/form_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/form_field_widgets.dart';
import '../../data/ui_text.dart';

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
          SnackBar(
              content: Text(UiText.formSaved),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(UiText.error(e)),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addField(FormFieldType type) {
    const uuid = Uuid();
    final field = AppFormField(
      id: uuid.v4(),
      type: type,
      label: type.displayName,
      order: ref.read(formEditorProvider).fields.length,
    );
    ref.read(formEditorProvider.notifier).addField(field);
    ref.read(formEditorProvider.notifier).selectField(field.id);
  }

  void _showFieldPaletteSheet(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => Consumer(
        builder: (ctx, ref, _) {
          final glassMode = ref.watch(glassModeProvider);
          final cs = Theme.of(ctx).colorScheme;

          final sheetContent = SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 14, bottom: 6),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    UiText.fieldTypes,
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Divider(
                  height: 1,
                  color: cs.onSurface.withValues(
                      alpha: glassMode ? 0.12 : 0.10),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    children: FormFieldType.values
                        .map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: FieldPaletteItem(
                                type: t,
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _addField(t);
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          );

          const sheetRadius =
              BorderRadius.vertical(top: Radius.circular(24));

          if (glassMode) {
            return ClipRRect(
              borderRadius: sheetRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.68),
                    borderRadius: sheetRadius,
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(
                            alpha: isDark ? 0.14 : 0.60),
                      ),
                    ),
                  ),
                  child: sheetContent,
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: sheetRadius,
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: sheetContent,
          );
        },
      ),
    );
  }

  void _showPropertiesSheet(
      BuildContext context, AppFormField field, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetCtx) => Consumer(
        builder: (ctx, ref, _) {
          final glassMode = ref.watch(glassModeProvider);
          final cs = Theme.of(ctx).colorScheme;

          const sheetRadius =
              BorderRadius.vertical(top: Radius.circular(24));

          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.4, 0.65, 0.92],
            expand: false,
            builder: (innerCtx, scrollController) {
              final sheetInner = Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 14, bottom: 6),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
                    child: Row(
                      children: [
                        Text(
                          UiText.fieldProperties,
                          style: Theme.of(ctx)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color:
                                  cs.onSurface.withValues(alpha: 0.5)),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: cs.onSurface.withValues(
                        alpha: glassMode ? 0.12 : 0.10),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom:
                            MediaQuery.of(innerCtx).viewInsets.bottom + 16,
                      ),
                      child: _FieldPropertiesPanel(
                        field: field,
                        transparent: true,
                        onUpdate: (updated) => ref
                            .read(formEditorProvider.notifier)
                            .updateField(updated),
                      ),
                    ),
                  ),
                ],
              );

              if (glassMode) {
                return ClipRRect(
                  borderRadius: sheetRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.white.withValues(alpha: 0.68),
                        borderRadius: sheetRadius,
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(
                                alpha: isDark ? 0.14 : 0.60),
                          ),
                        ),
                      ),
                      child: sheetInner,
                    ),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: sheetRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.45 : 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: sheetInner,
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(formEditorProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;
    final isMobile = width < 700;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(onPressed: () => context.pop()),
        title: Row(
          children: [
            Expanded(
              child: Text(
                editorState.form?.name ?? UiText.formEditor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (editorState.isDirty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(UiText.unsaved,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.warning)),
              ),
            ],
          ],
        ),
        actions: [
          if (isMobile)
            AppBarIconButton(
              icon: Icons.add_box_outlined,
              tooltip: UiText.fieldTypes,
              onPressed: () => _showFieldPaletteSheet(context, isDark),
            ),
          AppBarActionButton(
            label: UiText.save,
            icon: Icons.save_outlined,
            loading: _saving,
            onPressed: _save,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          // Field palette — hidden on mobile (use AppBar icon + bottom sheet)
          if (!isMobile)
            Container(
              width: isDesktop ? 220 : 160,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  right: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      UiText.fieldTypes,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextFormField(
                    initialValue: editorState.form?.name ?? '',
                    decoration: InputDecoration(
                      hintText: UiText.formName,
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
                              Icon(
                                Icons.add_box_outlined,
                                size: 48,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                UiText.clickAFieldTypeToAddIt,
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView(
                          padding: const EdgeInsets.all(16),
                          onReorder: (oldIndex, newIndex) {
                            ref.read(formEditorProvider.notifier).reorderFields(
                                oldIndex,
                                newIndex > oldIndex
                                    ? newIndex - 1
                                    : newIndex);
                          },
                          children: editorState.fields
                              .asMap()
                              .entries
                              .map(
                                (e) => _FieldCard(
                                  key: ValueKey(e.value.id),
                                  field: e.value,
                                  isSelected: editorState.selectedFieldId ==
                                      e.value.id,
                                  onSelect: () {
                                    ref
                                        .read(formEditorProvider.notifier)
                                        .selectField(e.value.id);
                                    if (isMobile) {
                                      _showPropertiesSheet(
                                          context, e.value, isDark);
                                    }
                                  },
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

          // Field properties panel — inline on tablet/desktop only
          if (!isMobile && editorState.selectedField != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isDesktop ? 280 : 240,
              child: _FieldPropertiesPanel(
                field: editorState.selectedField!,
                onUpdate: (field) =>
                    ref.read(formEditorProvider.notifier).updateField(field),
              ),
            ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final AppFormField field;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onSelect,
        selected: isSelected,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.drag_indicator,
              size: 18,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                        (field.required ? UiText.requiredText3 : ''),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
  final AppFormField field;
  final ValueChanged<AppFormField> onUpdate;
  final bool transparent;

  const _FieldPropertiesPanel({
    required this.field,
    required this.onUpdate,
    this.transparent = false,
  });

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

    final scrollContent = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(UiText.fieldProperties,
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
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
              decoration: InputDecoration(labelText: UiText.label),
              onChanged: (v) => widget.onUpdate(field.copyWith(label: v)),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _placeholderController,
              decoration: InputDecoration(labelText: UiText.placeholder),
              onChanged: (v) => widget.onUpdate(field.copyWith(placeholder: v)),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _helpTextController,
              decoration: InputDecoration(labelText: UiText.helpText),
              onChanged: (v) => widget.onUpdate(field.copyWith(helpText: v)),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title:
                  Text(UiText.requiredText, style: const TextStyle(fontSize: 14)),
              value: field.required,
              onChanged: (v) => widget.onUpdate(field.copyWith(required: v)),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),

            SwitchListTile(
              title: Text(UiText.readOnly, style: const TextStyle(fontSize: 14)),
              value: field.readOnly,
              onChanged: (v) => widget.onUpdate(field.copyWith(readOnly: v)),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),

            SwitchListTile(
              title: Text(UiText.hidden, style: const TextStyle(fontSize: 14)),
              value: field.hidden,
              onChanged: (v) => widget.onUpdate(field.copyWith(hidden: v)),
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
                  Text(UiText.options,
                      style: Theme.of(context).textTheme.labelLarge),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 14),
                    label: Text(UiText.add),
                    onPressed: () {
                      const uuid = Uuid();
                      final options = List<FormFieldOption>.from(field.options)
                        ..add(FormFieldOption(
                          value: uuid.v4().substring(0, 8),
                          label:
                              UiText.optionNumber(field.options.length + 1),
                        ));
                      widget.onUpdate(field.copyWith(options: options));
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
              ...field.options.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: e.value.label,
                          decoration: InputDecoration(
                            hintText: UiText.optionNumber(e.key + 1),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            final opts =
                                List<FormFieldOption>.from(field.options);
                            opts[e.key] =
                                FormFieldOption(value: e.value.value, label: v);
                            widget.onUpdate(field.copyWith(options: opts));
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          final opts = List<FormFieldOption>.from(field.options)
                            ..removeAt(e.key);
                          widget.onUpdate(field.copyWith(options: opts));
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 16),
                        color: AppColors.error,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
    );

    if (widget.transparent) {
      return Material(color: Colors.transparent, child: scrollContent);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: scrollContent,
    );
  }
}
