import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/letter_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../data/ui_text.dart';

class LetterEditorScreen extends ConsumerStatefulWidget {
  final String letterId;

  const LetterEditorScreen({super.key, required this.letterId});

  @override
  ConsumerState<LetterEditorScreen> createState() => _LetterEditorScreenState();
}

class _LetterEditorScreenState extends ConsumerState<LetterEditorScreen> {
  final QuillController _quillController = QuillController.basic();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _loading = true;
  bool _saving = false;
  String? _letterId;
  final List<PlatformFile> _attachments = [];

  @override
  void initState() {
    super.initState();
    _loadLetter();
  }

  Future<void> _loadLetter() async {
    if (widget.letterId != 'new') {
      try {
        final repo = ref.read(letterRepositoryProvider);
        final letter = await repo.getLetter(widget.letterId);
        _nameController.text = letter.name;
        _descController.text = letter.description ?? '';
        _letterId = letter.id;

        if (letter.deltaContent.isNotEmpty) {
          try {
            final doc = Document.fromJson(
                letter.deltaContent['ops'] as List<dynamic>? ?? []);
            _quillController.document = doc;
          } catch (_) {
            // ignore parse error, start with empty doc
          }
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(letterRepositoryProvider);
      final delta = _quillController.document.toDelta();
      final plainText = _quillController.document.toPlainText();

      final data = {
        'name': _nameController.text,
        'description':
            _descController.text.isNotEmpty ? _descController.text : null,
        'content': plainText,
        UiText.deltacontent: {'ops': delta.toJson()},
        'status': 'draft',
      };

      if (_letterId == null || widget.letterId == 'new') {
        final letter = await repo.createLetter(data);
        _letterId = letter.id;
        ref.read(letterNotifierProvider.notifier).refresh();
      } else {
        await repo.updateLetter(_letterId!, data);
        ref.read(letterNotifierProvider.notifier).refresh();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(UiText.templateSaved),
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

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && mounted) {
      setState(() => _attachments.addAll(result.files));
    }
  }

  void _removeAttachment(int index) {
    setState(() => _attachments.removeAt(index));
  }

  @override
  void dispose() {
    _quillController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(onPressed: () => context.pop()),
        title: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: UiText.templateName,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          // Attach files
          TextButton.icon(
            icon: const Icon(Icons.attach_file, size: 16),
            label: Text(_attachments.isEmpty
                ? UiText.attach
                : UiText.fileCount(_attachments.length)),
            onPressed: _pickAttachment,
          ),
          // Variable chip
          TextButton.icon(
            icon: const Icon(Icons.data_object, size: 16),
            label: Text(UiText.variables),
            onPressed: _showVariablesPanel,
          ),
          AppButton(
            label: UiText.save,
            loading: _saving,
            onPressed: _save,
            icon: Icons.save_outlined,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Quill toolbar
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: QuillSimpleToolbar(
              controller: _quillController,
              configurations: const QuillSimpleToolbarConfigurations(
                showFontSize: true,
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: true,
                showColorButton: true,
                showBackgroundColorButton: true,
                showListNumbers: true,
                showListBullets: true,
                showClearFormat: true,
                showAlignmentButtons: true,
                showIndent: true,
                showLink: true,
                multiRowsDisplay: false,
              ),
            ),
          ),

          // Attachments strip
          if (_attachments.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.primarySurface,
                border: Border(
                  bottom: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Icon(Icons.attach_file,
                        size: 14, color: AppColors.lightTextSecondary),
                    const SizedBox(width: 4),
                    ..._attachments.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: Chip(
                              label: Text(
                                e.value.name,
                                style: const TextStyle(fontSize: 11),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => _removeAttachment(e.key),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                    TextButton.icon(
                      onPressed: _pickAttachment,
                      icon: const Icon(Icons.add, size: 14),
                      label: Text(UiText.addMore,
                          style: const TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Editor body
          Expanded(
            child: Container(
              color: isDark ? AppColors.darkBg : const Color(0xFFFAFBFF),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: QuillEditor(
                    controller: _quillController,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    configurations: QuillEditorConfigurations(
                      placeholder: UiText.startWritingYourLetterTemplate,
                      padding: EdgeInsets.zero,
                      autoFocus: false,
                      expands: false,
                      scrollable: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVariablesPanel() {
    showDialog(
      context: context,
      builder: (_) => GlassAlertDialog(
        title: Text(UiText.availableVariables),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                UiText
                    .useTheseVariablesInYourTemplateTheyWillBeReplacedWithActualV,
              ),
              const SizedBox(height: 16),
              ...[
                (r'{{user.name}}', UiText.userSFullName),
                (r'{{user.email}}', UiText.userSEmail),
                (r'{{company.name}}', UiText.companyName),
                (r'{{date}}', UiText.currentDate),
                (r'{{flow.name}}', UiText.flowName),
              ].map(
                (v) => ListTile(
                  title: Text(v.$1,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 13)),
                  subtitle: Text(v.$2, style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      _quillController.document.insert(
                        _quillController.selection.extentOffset,
                        v.$1,
                      );
                      Navigator.pop(context);
                    },
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(UiText.close),
          ),
        ],
      ),
    );
  }
}
