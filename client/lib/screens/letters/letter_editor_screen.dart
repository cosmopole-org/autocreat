import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/demo_data.dart';
import '../../data/ui_text.dart';
import '../../models/letter_template.dart';
import '../../providers/demo_provider.dart';
import '../../providers/letter_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

// ─── breakpoints ────────────────────────────────────────────────────────────
const _kTablet = 600.0;
const _kDesktop = 900.0;

// ─── system variables always available in every template ─────────────────────
List<_Var> get _systemVars => [
      _Var(r'{{user.name}}', UiText.userSFullName),
      _Var(r'{{user.email}}', UiText.userSEmail),
      _Var(r'{{company.name}}', UiText.companyName),
      _Var(r'{{date}}', UiText.currentDate),
      _Var(r'{{flow.name}}', UiText.flowName),
    ];

class _Var {
  final String token;
  final String label;
  const _Var(this.token, this.label);
}

// ─── screen ──────────────────────────────────────────────────────────────────

class LetterEditorScreen extends ConsumerStatefulWidget {
  final String letterId;
  const LetterEditorScreen({super.key, required this.letterId});

  @override
  ConsumerState<LetterEditorScreen> createState() => _LetterEditorScreenState();
}

class _LetterEditorScreenState extends ConsumerState<LetterEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _bodyFocus = FocusNode();

  bool _loading = true;
  bool _saving = false;
  bool _varsPanelOpen = false;

  String? _letterId;
  List<String> _letterVariables = [];
  final List<PlatformFile> _attachments = [];

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLetter());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _bodyCtrl.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  // ── data ──────────────────────────────────────────────────────────────────

  Future<void> _loadLetter() async {
    if (widget.letterId == 'new') {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      LetterTemplate letter;

      final isDemo = ref.read(isDemoModeProvider);
      if (isDemo) {
        final raw = DemoData.letters.firstWhere(
          (l) => l['id'] == widget.letterId,
          orElse: () => DemoData.letters.first,
        );
        letter = LetterTemplate.fromJson(raw);
      } else {
        letter =
            await ref.read(letterRepositoryProvider).getLetter(widget.letterId);
      }

      _nameCtrl.text = letter.name;
      _descCtrl.text = letter.description ?? '';
      _bodyCtrl.text = letter.content;
      _letterId = letter.id;
      _letterVariables = letter.variables;
    } catch (_) {
      // silently fall through to an empty editor on error
    }

    if (mounted) setState(() => _loading = false);
  }

  // ── save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(letterRepositoryProvider);
      final plainText = _bodyCtrl.text;

      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
        'content': plainText,
        'status': 'draft',
      };

      if (_letterId == null || widget.letterId == 'new') {
        final created = await repo.createLetter(data);
        _letterId = created.id;
      } else {
        await repo.updateLetter(_letterId!, data);
      }
      ref.read(letterNotifierProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(UiText.templateSaved),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(UiText.error(e)),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── attachments ────────────────────────────────────────────────────────────

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && mounted) {
      setState(() => _attachments.addAll(result.files));
    }
  }

  void _removeAttachment(int index) =>
      setState(() => _attachments.removeAt(index));

  // ── variables ─────────────────────────────────────────────────────────────

  void _insertVariable(String token) {
    final sel = _bodyCtrl.selection;
    final text = _bodyCtrl.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final newText = text.replaceRange(start, end, token);
    _bodyCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
    _bodyFocus.requestFocus();
  }

  void _showVarsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _VarsSheet(
        letterVariables: _letterVariables,
        onInsert: (token) {
          Navigator.pop(ctx);
          _insertVariable(token);
        },
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < _kTablet;
    final isDesktop = w >= _kDesktop;
    final isRtl = UiText.isRtl;
    final textDir = isRtl ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDir,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF0F2FA),
        appBar: _buildAppBar(context, isDark, isMobile),
        body: SizedBox.expand(
          child: Row(
            children: [
              Expanded(
                child: _EditorPane(
                  controller: _bodyCtrl,
                  focusNode: _bodyFocus,
                  isDark: isDark,
                  isMobile: isMobile,
                  attachments: _attachments,
                  onAddAttachment: _pickAttachment,
                  onRemoveAttachment: _removeAttachment,
                ),
              ),
              if (isDesktop && _varsPanelOpen)
                _VarsSidePanel(
                  isDark: isDark,
                  letterVariables: _letterVariables,
                  onInsert: _insertVariable,
                  onClose: () => setState(() => _varsPanelOpen = false),
                ),
            ],
          ),
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
        controller: _nameCtrl,
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
        // Attachment button with count badge
        SizedBox(
          width: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AppBarIconButton(
                icon: Icons.attach_file_rounded,
                tooltip: UiText.attach,
                onPressed: _pickAttachment,
              ),
              if (_attachments.isNotEmpty)
                PositionedDirectional(
                  top: 9,
                  end: 2,
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
        // Variables — bottom sheet on mobile, toggle side panel on desktop
        AppBarIconButton(
          icon: Icons.data_object_rounded,
          tooltip: UiText.variables,
          onPressed: () {
            final w = MediaQuery.sizeOf(context).width;
            if (w >= _kDesktop) {
              setState(() => _varsPanelOpen = !_varsPanelOpen);
            } else {
              _showVarsBottomSheet();
            }
          },
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
}

// ─── editor pane ─────────────────────────────────────────────────────────────

class _EditorPane extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final bool isMobile;
  final List<PlatformFile> attachments;
  final VoidCallback onAddAttachment;
  final void Function(int) onRemoveAttachment;

  const _EditorPane({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.isMobile,
    required this.attachments,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final edgeMargin = isMobile ? 10.0 : 24.0;
    final innerPad = isMobile ? 14.0 : 28.0;

    return Container(
      color: isDark ? AppColors.darkBg : const Color(0xFFF0F2FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (attachments.isNotEmpty)
            _AttachmentStrip(
              attachments: attachments,
              isDark: isDark,
              onAdd: onAddAttachment,
              onRemove: onRemoveAttachment,
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(edgeMargin),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.22 : 0.06),
                      blurRadius: isMobile ? 8 : 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(innerPad),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    height: 1.55,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    hintText: UiText.startWritingYourLetterTemplate,
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── attachment strip ─────────────────────────────────────────────────────────

class _AttachmentStrip extends StatelessWidget {
  final List<PlatformFile> attachments;
  final bool isDark;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _AttachmentStrip({
    required this.attachments,
    required this.isDark,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.primarySurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(
              Icons.attach_file_rounded,
              size: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            ...attachments.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: Chip(
                      label: Text(e.value.name,
                          style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 13),
                      onDeleted: () => onRemove(e.key),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 14),
              label:
                  Text(UiText.addMore, style: const TextStyle(fontSize: 11)),
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
}

// ─── desktop side panel ───────────────────────────────────────────────────────

class _VarsSidePanel extends StatelessWidget {
  final bool isDark;
  final List<String> letterVariables;
  final void Function(String) onInsert;
  final VoidCallback onClose;

  const _VarsSidePanel({
    required this.isDark,
    required this.letterVariables,
    required this.onInsert,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: bg,
        border: Border(left: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.data_object_rounded, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    UiText.availableVariables,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                _VarGroupHeader(label: 'System', isDark: isDark),
                ..._systemVars.map((v) =>
                    _VarTile(v: v, isDark: isDark, onInsert: onInsert)),
                if (letterVariables.isNotEmpty) ...[
                  _VarGroupHeader(label: UiText.variables, isDark: isDark),
                  ...letterVariables.map(
                    (name) => _VarTile(
                      v: _Var('{{$name}}', name),
                      isDark: isDark,
                      onInsert: onInsert,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VarGroupHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _VarGroupHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

class _VarTile extends StatelessWidget {
  final _Var v;
  final bool isDark;
  final void Function(String) onInsert;
  const _VarTile(
      {required this.v, required this.isDark, required this.onInsert});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Text(
        v.token,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        v.label,
        style: TextStyle(
          fontSize: 11,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.copy_rounded,
              size: 15,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Copy',
            onPressed: () => Clipboard.setData(ClipboardData(text: v.token)),
          ),
          IconButton(
            icon: Icon(Icons.keyboard_return_rounded,
                size: 15, color: accent),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Insert',
            onPressed: () => onInsert(v.token),
          ),
        ],
      ),
    );
  }
}

// ─── bottom sheet (tablet / mobile) ──────────────────────────────────────────

class _VarsSheet extends StatelessWidget {
  final List<String> letterVariables;
  final void Function(String) onInsert;

  const _VarsSheet({
    required this.letterVariables,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.data_object_rounded, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    UiText.availableVariables,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _SheetGroupHeader(label: 'System', isDark: isDark),
                  ..._systemVars.map((v) => _SheetVarTile(
                        v: v,
                        isDark: isDark,
                        onInsert: onInsert,
                      )),
                  if (letterVariables.isNotEmpty) ...[
                    _SheetGroupHeader(
                        label: UiText.variables, isDark: isDark),
                    ...letterVariables.map(
                      (name) => _SheetVarTile(
                        v: _Var('{{$name}}', name),
                        isDark: isDark,
                        onInsert: onInsert,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetGroupHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SheetGroupHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

class _SheetVarTile extends StatelessWidget {
  final _Var v;
  final bool isDark;
  final void Function(String) onInsert;
  const _SheetVarTile(
      {required this.v, required this.isDark, required this.onInsert});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(
        v.token,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        v.label,
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.copy_rounded, size: 18, color: accent),
            onPressed: () => Clipboard.setData(ClipboardData(text: v.token)),
            tooltip: 'Copy',
          ),
          FilledButton.tonal(
            onPressed: () => onInsert(v.token),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Insert', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
