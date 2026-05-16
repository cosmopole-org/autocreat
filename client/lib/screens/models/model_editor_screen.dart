import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/model_definition.dart';
import '../../providers/model_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../data/ui_text.dart';

class ModelEditorScreen extends ConsumerStatefulWidget {
  final String modelId;

  const ModelEditorScreen({super.key, required this.modelId});

  @override
  ConsumerState<ModelEditorScreen> createState() => _ModelEditorScreenState();
}

class _ModelEditorScreenState extends ConsumerState<ModelEditorScreen> {
  bool _loading = true;
  bool _saving = false;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    final repo = ref.read(modelRepositoryProvider);
    try {
      if (widget.modelId != 'new') {
        final model = await repo.getModel(widget.modelId);
        ref.read(modelEditorProvider.notifier).loadModel(model);
        _nameController.text = model.name;
        _descController.text = model.description ?? '';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      ref.read(modelEditorProvider.notifier).updateModelMeta(
            _nameController.text,
            _descController.text.isNotEmpty ? _descController.text : null,
          );
      final repo = ref.read(modelRepositoryProvider);
      await ref.read(modelEditorProvider.notifier).save(repo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(UiText.modelSaved),
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

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(modelEditorProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(onPressed: () => context.pop()),
        title: Text(editorState.model?.name ?? UiText.modelEditor),
        actions: [
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
          // Main panel
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditorHeroHeader(
                    title: _nameController.text.isNotEmpty
                        ? _nameController.text
                        : (editorState.model?.name ?? UiText.modelEditor),
                    subtitle: _descController.text.isNotEmpty
                        ? _descController.text
                        : UiText.modelInfo,
                    icon: Icons.dataset_outlined,
                    chips: [
                      EditorHeroChip(
                        icon: Icons.view_column_outlined,
                        label: UiText.fieldsTitle(editorState.fields.length),
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(UiText.modelInfo,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                              labelText: UiText.modelNameRequired),
                          onChanged: (_) {
                            ref
                                .read(modelEditorProvider.notifier)
                                .updateModelMeta(
                                  _nameController.text,
                                  _descController.text,
                                );
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descController,
                          decoration: InputDecoration(
                              labelText: UiText.description),
                          maxLines: 2,
                          onChanged: (_) {
                            ref
                                .read(modelEditorProvider.notifier)
                                .updateModelMeta(
                                  _nameController.text,
                                  _descController.text,
                                );
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fields
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(UiText.fieldsTitle(editorState.fields.length),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        AppButton(
                          label: UiText.addField,
                          icon: Icons.add,
                          onPressed: () => _showAddFieldDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (editorState.fields.isEmpty)
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.add_box_outlined,
                                    size: 28, color: AppColors.primary),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                UiText.noFieldsYetAddYourFirstField,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...editorState.fields.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ModelFieldRow(
                              field: e.value,
                              allModels: const [],
                              onUpdate: (f) => ref
                                  .read(modelEditorProvider.notifier)
                                  .updateField(f),
                              onDelete: () => ref
                                  .read(modelEditorProvider.notifier)
                                  .deleteField(e.value.id),
                            ).animate().fadeIn(
                                delay: Duration(milliseconds: e.key * 50)),
                          ),
                        ),
                ],
              ),
            ),
          ),

          // Schema preview
          if (isDesktop)
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  left: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.code_rounded,
                            size: 15, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(UiText.jsonSchemaPreview,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBg
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _buildSchemaPreview(editorState),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            height: 1.5,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _buildSchemaPreview(ModelEditorState state) {
    if (state.model == null) return UiText.emptyJsonObject;
    final fields = state.fields.map((f) {
      return UiText.schemaField(f.name, f.type.displayName, f.required);
    }).join(UiText.schemaSeparator);
    return UiText.schemaObject(fields);
  }

  void _showAddFieldDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddFieldDialog(
        onAdd: (field) =>
            ref.read(modelEditorProvider.notifier).addField(field),
      ),
    );
  }
}

class _ModelFieldRow extends StatelessWidget {
  final ModelField field;
  final List<ModelDefinition> allModels;
  final ValueChanged<ModelField> onUpdate;
  final VoidCallback onDelete;

  const _ModelFieldRow({
    required this.field,
    required this.allModels,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child:
                Icon(_getTypeIcon(field.type), size: 16, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  field.type.displayName +
                      (field.required ? UiText.requiredText3 : '') +
                      (field.unique ? UiText.unique : ''),
                  style: TextStyle(
                      fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (field.required)
                Tooltip(
                  message: UiText.requiredText,
                  child: const Icon(Icons.star, size: 12, color: AppColors.error),
                ),
              if (field.unique)
                Tooltip(
                  message: UiText.unique3,
                  child: const Icon(Icons.key, size: 12, color: AppColors.warning),
                ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 16, color: AppColors.error),
            onPressed: onDelete,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.all(6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(28, 28),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(ModelFieldType type) {
    switch (type) {
      case ModelFieldType.string:
        return Icons.text_fields;
      case ModelFieldType.integer:
        return Icons.pin;
      case ModelFieldType.float:
        return Icons.numbers;
      case ModelFieldType.boolean:
        return Icons.toggle_on_outlined;
      case ModelFieldType.date:
        return Icons.calendar_today;
      case ModelFieldType.dateTime:
        return Icons.access_time;
      case ModelFieldType.file:
        return Icons.attach_file;
      case ModelFieldType.reference:
        return Icons.link;
    }
  }
}

class _AddFieldDialog extends StatefulWidget {
  final ValueChanged<ModelField> onAdd;

  const _AddFieldDialog({required this.onAdd});

  @override
  State<_AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<_AddFieldDialog> {
  final _nameController = TextEditingController();
  ModelFieldType _type = ModelFieldType.string;
  bool _required = false;
  bool _unique = false;

  @override
  Widget build(BuildContext context) {
    return GlassAlertDialog(
      title: Text(UiText.addField),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration:
                  InputDecoration(labelText: UiText.fieldNameRequired),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ModelFieldType>(
              value: _type,
              items: ModelFieldType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
              decoration: InputDecoration(labelText: UiText.fieldType),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: Text(UiText.requiredText),
              value: _required,
              onChanged: (v) => setState(() => _required = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            CheckboxListTile(
              title: Text(UiText.unique3),
              value: _unique,
              onChanged: (v) => setState(() => _unique = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(UiText.cancel),
        ),
        AppButton(
          label: UiText.add,
          onPressed: () {
            if (_nameController.text.isEmpty) return;
            const uuid = Uuid();
            widget.onAdd(ModelField(
              id: uuid.v4(),
              name: _nameController.text.trim(),
              type: _type,
              required: _required,
              unique: _unique,
            ));
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
