import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/form_definition.dart';
import '../theme/app_colors.dart';

class FormFieldRenderer extends StatefulWidget {
  final AppFormField field;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;
  final bool readOnly;

  const FormFieldRenderer({
    super.key,
    required this.field,
    this.value,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<FormFieldRenderer> createState() => _FormFieldRendererState();
}

class _FormFieldRendererState extends State<FormFieldRenderer> {
  late TextEditingController _textController;
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.field.type != FormFieldType.checkbox &&
            widget.field.type != FormFieldType.switchField)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  widget.field.label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (widget.field.required) ...[
                  const SizedBox(width: 4),
                  const Text('*',
                      style: TextStyle(color: AppColors.error, fontSize: 14)),
                ],
              ],
            ),
          ),
        _buildFieldWidget(context),
        if (widget.field.helpText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.field.helpText!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.lightTextSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldWidget(BuildContext context) {
    switch (widget.field.type) {
      case FormFieldType.text:
        return TextFormField(
          controller: _textController,
          readOnly: widget.readOnly,
          decoration: InputDecoration(hintText: widget.field.placeholder),
          onChanged: widget.onChanged,
        );

      case FormFieldType.number:
        return TextFormField(
          controller: _textController,
          readOnly: widget.readOnly,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: widget.field.placeholder ?? '0',
          ),
          onChanged: (v) => widget.onChanged?.call(double.tryParse(v)),
        );

      case FormFieldType.textarea:
        return TextFormField(
          controller: _textController,
          readOnly: widget.readOnly,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: widget.field.placeholder,
            alignLabelWithHint: true,
          ),
          onChanged: widget.onChanged,
        );

      case FormFieldType.dropdown:
        return DropdownButtonFormField<String>(
          value: widget.value as String?,
          items: widget.field.options
              .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
              .toList(),
          onChanged: widget.readOnly ? null : (v) => widget.onChanged?.call(v),
          decoration: InputDecoration(
            hintText: widget.field.placeholder ?? 'Select...',
          ),
        );

      case FormFieldType.multiselect:
        final selected = (widget.value as List<String>?) ?? [];
        return Column(
          children: widget.field.options
              .map((o) => CheckboxListTile(
                    title: Text(o.label),
                    value: selected.contains(o.value),
                    onChanged: widget.readOnly
                        ? null
                        : (checked) {
                            final list = List<String>.from(selected);
                            if (checked == true) {
                              list.add(o.value);
                            } else {
                              list.remove(o.value);
                            }
                            widget.onChanged?.call(list);
                          },
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ))
              .toList(),
        );

      case FormFieldType.checkbox:
        return CheckboxListTile(
          title: Text(widget.field.label),
          subtitle:
              widget.field.helpText != null ? Text(widget.field.helpText!) : null,
          value: widget.value as bool? ?? false,
          onChanged: widget.readOnly ? null : (v) => widget.onChanged?.call(v),
          contentPadding: EdgeInsets.zero,
        );

      case FormFieldType.radio:
        final selected = widget.value as String?;
        return Column(
          children: widget.field.options
              .map((o) => RadioListTile<String>(
                    title: Text(o.label),
                    value: o.value,
                    groupValue: selected,
                    onChanged:
                        widget.readOnly ? null : (v) => widget.onChanged?.call(v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ))
              .toList(),
        );

      case FormFieldType.date:
        return InkWell(
          onTap: widget.readOnly
              ? null
              : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  widget.onChanged?.call(date?.toIso8601String());
                },
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: widget.field.placeholder ?? 'Select date',
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
            ),
            child: Text(
              widget.value?.toString() ??
                  widget.field.placeholder ??
                  'Select date',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );

      case FormFieldType.time:
        return InkWell(
          onTap: widget.readOnly
              ? null
              : () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  widget.onChanged?.call(time?.format(context));
                },
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: widget.field.placeholder ?? 'Select time',
              suffixIcon: const Icon(Icons.access_time, size: 18),
            ),
            child: Text(
              widget.value?.toString() ??
                  widget.field.placeholder ??
                  'Select time',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );

      case FormFieldType.file:
        final fileName = widget.value?.toString();
        return DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          color: AppColors.primary.withOpacity(0.4),
          strokeWidth: 1.5,
          dashPattern: const [6, 3],
          child: InkWell(
            onTap: widget.readOnly
                ? null
                : () async {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: false,
                      withData: false,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      widget.onChanged?.call(result.files.single.name);
                    }
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    fileName != null
                        ? Icons.insert_drive_file_outlined
                        : Icons.upload_file,
                    size: 36,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fileName ?? 'Click to upload file',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: fileName != null
                              ? AppColors.primary
                              : AppColors.lightTextSecondary,
                          fontWeight: fileName != null ? FontWeight.w500 : null,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (fileName == null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Any file type supported',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.lightTextHint),
                    ),
                  ],
                  if (fileName != null && !widget.readOnly) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => widget.onChanged?.call(null),
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );

      case FormFieldType.image:
        final imagePath = widget.value?.toString();
        return DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          color: AppColors.accent.withOpacity(0.4),
          strokeWidth: 1.5,
          dashPattern: const [6, 3],
          child: InkWell(
            onTap: widget.readOnly
                ? null
                : () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      widget.onChanged?.call(picked.path);
                    }
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 140,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: imagePath != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined,
                                size: 40, color: AppColors.lightTextSecondary),
                          ),
                        ),
                        if (!widget.readOnly)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => widget.onChanged?.call(null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: AppColors.accent.withOpacity(0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click to upload image',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.lightTextSecondary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PNG, JPG, GIF supported',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.lightTextHint),
                        ),
                      ],
                    ),
            ),
          ),
        );

      case FormFieldType.color:
        final color = widget.value is int
            ? Color(widget.value as int)
            : _selectedColor;
        return GestureDetector(
          onTap: widget.readOnly
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Pick a color'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: color,
                          onColorChanged: (c) {
                            setState(() => _selectedColor = c);
                            widget.onChanged?.call(c.value);
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  );
                },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Center(
              child: Text(
                '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 4)]),
              ),
            ),
          ),
        );

      case FormFieldType.switchField:
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.field.label,
                      style: Theme.of(context).textTheme.labelLarge),
                  if (widget.field.helpText != null)
                    Text(widget.field.helpText!,
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Switch(
              value: widget.value as bool? ?? false,
              onChanged: widget.readOnly ? null : (v) => widget.onChanged?.call(v),
            ),
          ],
        );

      case FormFieldType.rating:
        final rating = (widget.value as int?) ?? 0;
        return Row(
          children: List.generate(
            5,
            (i) => IconButton(
              onPressed:
                  widget.readOnly ? null : () => widget.onChanged?.call(i + 1),
              icon: Icon(
                i < rating ? Icons.star : Icons.star_border,
                color: AppColors.warning,
                size: 28,
              ),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 2),
            ),
          ),
        );

      case FormFieldType.signature:
        return Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.draw_outlined,
                    size: 32, color: AppColors.lightTextSecondary),
                SizedBox(height: 8),
                Text('Sign here',
                    style: TextStyle(color: AppColors.lightTextSecondary)),
              ],
            ),
          ),
        );

      case FormFieldType.table:
        return _TableField(
          field: widget.field,
          value: widget.value,
          onChanged: widget.onChanged,
          readOnly: widget.readOnly,
        );
    }
  }
}

class _TableField extends StatefulWidget {
  final AppFormField field;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;
  final bool readOnly;

  const _TableField({
    required this.field,
    this.value,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<_TableField> createState() => _TableFieldState();
}

class _TableFieldState extends State<_TableField> {
  List<List<String>> _rows = [];
  final List<String> _headers = ['Column 1', 'Column 2', 'Column 3'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: _headers
                  .map((h) => Expanded(
                        child: Text(h,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12)),
                      ))
                  .toList(),
            ),
          ),
          ..._rows.map((row) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: row
                      .asMap()
                      .entries
                      .map((e) => Expanded(
                            child: TextFormField(
                              initialValue: e.value,
                              readOnly: widget.readOnly,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              )),
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _rows.add(List.filled(_headers.length, ''));
                  });
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Row'),
              ),
            ),
        ],
      ),
    );
  }
}

class FieldPaletteItem extends StatelessWidget {
  final FormFieldType type;
  final VoidCallback? onTap;

  const FieldPaletteItem({super.key, required this.type, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(
            children: [
              Icon(_getIcon(type), size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.drag_indicator,
                  size: 14, color: AppColors.lightTextHint),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(FormFieldType t) {
    switch (t) {
      case FormFieldType.text:
        return Icons.text_fields;
      case FormFieldType.number:
        return Icons.pin;
      case FormFieldType.textarea:
        return Icons.notes;
      case FormFieldType.dropdown:
        return Icons.arrow_drop_down_circle_outlined;
      case FormFieldType.multiselect:
        return Icons.checklist;
      case FormFieldType.checkbox:
        return Icons.check_box_outlined;
      case FormFieldType.radio:
        return Icons.radio_button_checked;
      case FormFieldType.date:
        return Icons.calendar_today;
      case FormFieldType.time:
        return Icons.access_time;
      case FormFieldType.file:
        return Icons.attach_file;
      case FormFieldType.image:
        return Icons.image_outlined;
      case FormFieldType.color:
        return Icons.color_lens_outlined;
      case FormFieldType.switchField:
        return Icons.toggle_on_outlined;
      case FormFieldType.table:
        return Icons.table_chart_outlined;
      case FormFieldType.rating:
        return Icons.star_outline;
      case FormFieldType.signature:
        return Icons.draw_outlined;
    }
  }
}
