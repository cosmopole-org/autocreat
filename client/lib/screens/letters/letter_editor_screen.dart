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
          } catch (_) {}
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: _buildAppBar(context, isDark, isMobile),
      body: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildToolbar(context, isDark, isMobile),
            if (_attachments.isNotEmpty)
              _buildAttachmentStrip(context, isDark, isMobile),
            _buildEditorBody(context, isDark, isMobile),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, bool isDark, bool isMobile) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    return AppBar(
      leading: AppBarBackButton(onPressed: () => context.pop()),
      titleSpacing: 8,
      title: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          hintText: UiText.templateName,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
      ),
      actions: [
        // Attach — badge shows count when attachments present
        SizedBox(
          width: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AppBarIconButton(
                icon: Icons.attach_file,
                tooltip: UiText.attach,
                onPressed: _pickAttachment,
              ),
              if (_attachments.isNotEmpty)
                Positioned(
                  top: 9,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${_attachments.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        AppBarIconButton(
          icon: Icons.data_object,
          tooltip: UiText.variables,
          onPressed: _showVariablesPanel,
        ),
        const SizedBox(width: 4),
        AppBarActionButton(
          label: isMobile ? '' : UiText.save,
          loading: _saving,
          onPressed: _save,
          icon: Icons.save_outlined,
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildToolbar(
      BuildContext context, bool isDark, bool isMobile) {
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: QuillSimpleToolbar(
        controller: _quillController,
        config: QuillSimpleToolbarConfig(
          showFontSize: !isMobile,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: !isMobile,
          showColorButton: true,
          showBackgroundColorButton: !isMobile,
          showListNumbers: true,
          showListBullets: true,
          showClearFormat: true,
          showAlignmentButtons: true,
          showIndent: !isMobile,
          showLink: true,
          multiRowsDisplay: isMobile,
        ),
      ),
    );
  }

  Widget _buildAttachmentStrip(
      BuildContext context, bool isDark, bool isMobile) {
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor =
        isDark ? AppColors.darkCard : AppColors.primarySurface;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(Icons.attach_file,
                size: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
            const SizedBox(width: 6),
            ..._attachments.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: Chip(
                      label: Text(e.value.name,
                          style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 13),
                      onDeleted: () => _removeAttachment(e.key),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorBody(
      BuildContext context, bool isDark, bool isMobile) {
    final edgeMargin = isMobile ? 10.0 : 24.0;
    final innerPadding = isMobile ? 16.0 : 32.0;

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Guard against infinite constraints which can occur on web.
          final safeMaxW = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : (isMobile ? 400.0 : 900.0);
          final safeMaxH = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 600.0;

          final editorWidth =
              (safeMaxW - edgeMargin * 2).clamp(200.0, 800.0);
          final editorHeight =
              (safeMaxH - edgeMargin * 2).clamp(300.0, double.infinity);

          return Container(
            width: safeMaxW,
            height: safeMaxH,
            color: isDark ? AppColors.darkBg : const Color(0xFFF5F7FF),
            child: Center(
              child: SizedBox(
                width: editorWidth,
                height: editorHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.20)
                            : Colors.black.withValues(alpha: 0.05),
                        blurRadius: isMobile ? 8 : 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(innerPadding),
                  child: QuillEditor(
                    controller: _quillController,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    config: QuillEditorConfig(
                      placeholder: UiText.startWritingYourLetterTemplate,
                      padding: EdgeInsets.zero,
                      autoFocus: false,
                      expands: true,
                      scrollable: true,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
                  subtitle:
                      Text(v.$2, style: const TextStyle(fontSize: 12)),
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

