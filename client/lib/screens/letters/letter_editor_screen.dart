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
const double _kTablet = 600.0;
const double _kDesktop = 980.0;

// ─── id generator ───────────────────────────────────────────────────────────
int _idCounter = 0;
String _newBlockId() =>
    'b${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_idCounter++).toRadixString(36)}';

// ─── system variables ────────────────────────────────────────────────────────
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

// ─── block types ────────────────────────────────────────────────────────────
enum _BlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  bullet,
  numbered,
  todo,
  quote,
  code,
  callout,
  divider,
}

extension _BlockTypeMeta on _BlockType {
  String get label {
    switch (this) {
      case _BlockType.paragraph:
        return 'Text';
      case _BlockType.heading1:
        return 'Heading 1';
      case _BlockType.heading2:
        return 'Heading 2';
      case _BlockType.heading3:
        return 'Heading 3';
      case _BlockType.bullet:
        return 'Bulleted list';
      case _BlockType.numbered:
        return 'Numbered list';
      case _BlockType.todo:
        return 'To-do';
      case _BlockType.quote:
        return 'Quote';
      case _BlockType.code:
        return 'Code';
      case _BlockType.callout:
        return 'Callout';
      case _BlockType.divider:
        return 'Divider';
    }
  }

  IconData get icon {
    switch (this) {
      case _BlockType.paragraph:
        return Icons.notes_rounded;
      case _BlockType.heading1:
        return Icons.title_rounded;
      case _BlockType.heading2:
        return Icons.text_fields_rounded;
      case _BlockType.heading3:
        return Icons.short_text_rounded;
      case _BlockType.bullet:
        return Icons.format_list_bulleted_rounded;
      case _BlockType.numbered:
        return Icons.format_list_numbered_rounded;
      case _BlockType.todo:
        return Icons.check_box_outlined;
      case _BlockType.quote:
        return Icons.format_quote_rounded;
      case _BlockType.code:
        return Icons.code_rounded;
      case _BlockType.callout:
        return Icons.lightbulb_outline_rounded;
      case _BlockType.divider:
        return Icons.horizontal_rule_rounded;
    }
  }

  bool get hasText => this != _BlockType.divider;
}

// ─── block model ────────────────────────────────────────────────────────────
class _Block {
  String id;
  _BlockType type;
  String text;
  bool checked;
  String emoji;

  _Block({
    required this.id,
    required this.type,
    this.text = '',
    this.checked = false,
    this.emoji = '💡',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'text': text,
        if (type == _BlockType.todo) 'checked': checked,
        if (type == _BlockType.callout) 'emoji': emoji,
      };

  factory _Block.fromJson(Map<String, dynamic> j) => _Block(
        id: (j['id'] as String?) ?? _newBlockId(),
        type: _BlockType.values.firstWhere(
          (t) => t.name == (j['type'] as String?),
          orElse: () => _BlockType.paragraph,
        ),
        text: (j['text'] as String?) ?? '',
        checked: (j['checked'] as bool?) ?? false,
        emoji: (j['emoji'] as String?) ?? '💡',
      );
}

// ─── screen ─────────────────────────────────────────────────────────────────
class LetterEditorScreen extends ConsumerStatefulWidget {
  final String letterId;
  const LetterEditorScreen({super.key, required this.letterId});

  @override
  ConsumerState<LetterEditorScreen> createState() => _LetterEditorScreenState();
}

class _LetterEditorScreenState extends ConsumerState<LetterEditorScreen> {
  // Title / description
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Block state
  List<_Block> _blocks = [
    _Block(id: _newBlockId(), type: _BlockType.paragraph),
  ];
  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, FocusNode> _focuses = {};
  String? _activeBlockId;

  bool _loading = true;
  bool _saving = false;
  bool _varsPanelOpen = false;

  String? _letterId;
  List<String> _letterVariables = [];
  final List<PlatformFile> _attachments = [];

  // ── lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLetter());
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    for (final f in _focuses.values) {
      f.dispose();
    }
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── controller / focus management ────────────────────────────────────────
  TextEditingController _ctrlFor(_Block block) {
    return _ctrls.putIfAbsent(block.id, () {
      final c = TextEditingController(text: block.text);
      c.addListener(() {
        // keep model in sync with editor (cheap)
        block.text = c.text;
      });
      return c;
    });
  }

  FocusNode _focusFor(_Block block) {
    return _focuses.putIfAbsent(block.id, () {
      final f = FocusNode();
      f.addListener(() {
        if (f.hasFocus && _activeBlockId != block.id) {
          // Defer to next frame; focus events can fire mid-layout.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _activeBlockId = block.id);
          });
        }
      });
      return f;
    });
  }

  void _disposeBlock(String id) {
    _ctrls.remove(id)?.dispose();
    _focuses.remove(id)?.dispose();
  }

  // ── data load ────────────────────────────────────────────────────────────
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
        letter = await ref
            .read(letterRepositoryProvider)
            .getLetter(widget.letterId);
      }

      _nameCtrl.text = letter.name;
      _descCtrl.text = letter.description ?? '';
      _letterId = letter.id;
      _letterVariables = letter.variables;

      final loaded = _blocksFromLetter(letter);

      // Reset existing controllers/focuses so we don't leak state across loads.
      for (final c in _ctrls.values) {
        c.dispose();
      }
      for (final f in _focuses.values) {
        f.dispose();
      }
      _ctrls.clear();
      _focuses.clear();
      _blocks = loaded;
      _activeBlockId = null;
    } catch (_) {/* silent: keep default empty block */}

    if (mounted) setState(() => _loading = false);
  }

  List<_Block> _blocksFromLetter(LetterTemplate letter) {
    // 1. New format: deltaContent['blocks'] = [...]
    try {
      final raw = letter.deltaContent['blocks'] as List<dynamic>?;
      if (raw != null && raw.isNotEmpty) {
        final out = raw
            .whereType<Map<String, dynamic>>()
            .map(_Block.fromJson)
            .toList();
        if (out.isNotEmpty) return out;
      }
    } catch (_) {/* fall through */}

    // 2. Plain-text fallback: split letter.content into paragraph blocks.
    if (letter.content.isNotEmpty) {
      final lines = letter.content.split('\n');
      final out = <_Block>[];
      for (final line in lines) {
        out.add(_Block(
          id: _newBlockId(),
          type: _BlockType.paragraph,
          text: line,
        ));
      }
      if (out.isNotEmpty) return out;
    }

    // 3. Empty document.
    return [_Block(id: _newBlockId(), type: _BlockType.paragraph)];
  }

  // ── data save ────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(letterRepositoryProvider);

      // Build plain-text representation for search / legacy consumers.
      final plain = StringBuffer();
      for (final b in _blocks) {
        switch (b.type) {
          case _BlockType.divider:
            plain.writeln('---');
            break;
          case _BlockType.bullet:
            plain.writeln('• ${b.text}');
            break;
          case _BlockType.numbered:
            plain.writeln(b.text);
            break;
          case _BlockType.todo:
            plain.writeln('${b.checked ? "[x]" : "[ ]"} ${b.text}');
            break;
          case _BlockType.quote:
            plain.writeln('> ${b.text}');
            break;
          case _BlockType.callout:
            plain.writeln('${b.emoji} ${b.text}');
            break;
          default:
            plain.writeln(b.text);
        }
      }

      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
        'content': plain.toString().trimRight(),
        UiText.deltacontent: {
          'version': 2,
          'blocks': _blocks.map((b) => b.toJson()).toList(),
        },
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

  // ── block mutations ──────────────────────────────────────────────────────
  void _addBlock({
    String? afterId,
    _BlockType type = _BlockType.paragraph,
    String text = '',
  }) {
    final newBlock = _Block(id: _newBlockId(), type: type, text: text);
    setState(() {
      if (afterId == null) {
        _blocks.add(newBlock);
      } else {
        final idx = _blocks.indexWhere((b) => b.id == afterId);
        if (idx == -1) {
          _blocks.add(newBlock);
        } else {
          _blocks.insert(idx + 1, newBlock);
        }
      }
    });
    if (type.hasText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusFor(newBlock).requestFocus();
        // Caret at start of new block — matches Enter/split behavior.
        final c = _ctrlFor(newBlock);
        c.selection = const TextSelection.collapsed(offset: 0);
      });
    }
  }

  void _deleteBlock(String id) {
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    if (_blocks.length == 1) {
      // Don't drop the last block; just reset it to an empty paragraph.
      setState(() {
        final b = _blocks[0];
        b.type = _BlockType.paragraph;
        b.text = '';
        b.checked = false;
        _ctrls[b.id]?.text = '';
      });
      return;
    }
    setState(() {
      _blocks.removeAt(idx);
      _disposeBlock(id);
      if (_activeBlockId == id) _activeBlockId = null;
    });
    // Focus previous text block.
    final prevIdx = (idx - 1).clamp(0, _blocks.length - 1);
    final target = _blocks[prevIdx];
    if (target.type.hasText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusFor(target).requestFocus();
        final c = _ctrlFor(target);
        c.selection = TextSelection.collapsed(offset: c.text.length);
      });
    }
  }

  void _duplicateBlock(String id) {
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    final src = _blocks[idx];
    final copy = _Block(
      id: _newBlockId(),
      type: src.type,
      text: src.text,
      checked: src.checked,
      emoji: src.emoji,
    );
    setState(() => _blocks.insert(idx + 1, copy));
  }

  void _changeType(String id, _BlockType newType) {
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    setState(() {
      _blocks[idx].type = newType;
    });
    // Keep focus on this block if it still has text.
    if (newType.hasText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final cur = _blocks.indexWhere((b) => b.id == id);
        if (cur == -1) return;
        _focusFor(_blocks[cur]).requestFocus();
      });
    }
  }

  void _toggleTodo(String id) {
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    setState(() => _blocks[idx].checked = !_blocks[idx].checked);
  }

  void _reorderBlocks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      if (oldIndex < 0 ||
          oldIndex >= _blocks.length ||
          newIndex < 0 ||
          newIndex >= _blocks.length) {
        return;
      }
      final b = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, b);
    });
  }

  // Triggered by the newline-split formatter on text blocks. Splits the
  // tail (`afterText`) into one paragraph block per line so that pasting
  // multi-line text fans out into multiple structured blocks.
  void _splitBlock(String id, String afterText) {
    final parts = afterText.split('\n');
    final anchorIdx = _blocks.indexWhere((b) => b.id == id);
    if (anchorIdx == -1) return;

    final inserted = <_Block>[];
    setState(() {
      for (var i = 0; i < parts.length; i++) {
        final nb = _Block(
          id: _newBlockId(),
          type: _BlockType.paragraph,
          text: parts[i],
        );
        _blocks.insert(anchorIdx + 1 + i, nb);
        inserted.add(nb);
      }
    });

    if (inserted.isEmpty) return;
    // Focus the last new block, caret at start (matches standard Enter UX).
    final target = inserted.last;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusFor(target).requestFocus();
      _ctrlFor(target).selection = const TextSelection.collapsed(offset: 0);
    });
  }

  // ── attachments ──────────────────────────────────────────────────────────
  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && mounted) {
      setState(() => _attachments.addAll(result.files));
    }
  }

  void _removeAttachment(int index) =>
      setState(() => _attachments.removeAt(index));

  // ── variables ────────────────────────────────────────────────────────────
  void _insertVariable(String token) {
    // Prefer the last-focused text block; otherwise append a new paragraph.
    String? targetId = _activeBlockId;
    if (targetId != null) {
      final idx = _blocks.indexWhere((b) => b.id == targetId);
      if (idx == -1 || !_blocks[idx].type.hasText) targetId = null;
    }
    targetId ??= _blocks.lastWhere(
      (b) => b.type.hasText,
      orElse: () {
        final p = _Block(id: _newBlockId(), type: _BlockType.paragraph);
        setState(() => _blocks.add(p));
        return p;
      },
    ).id;

    final block = _blocks.firstWhere((b) => b.id == targetId);
    final c = _ctrlFor(block);
    final sel = c.selection;
    final start = sel.isValid ? sel.start : c.text.length;
    final end = sel.isValid ? sel.end : c.text.length;
    final newText = c.text.replaceRange(start, end, token);
    c.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
    block.text = newText;
    _focusFor(block).requestFocus();
  }

  Future<void> _showVarsBottomSheet() async {
    await showModalBottomSheet(
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

  Future<void> _showAddBlockSheet({String? afterId}) async {
    final picked = await showModalBottomSheet<_BlockType>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _BlockTypePicker(),
    );
    if (picked == null || !mounted) return;
    _addBlock(afterId: afterId, type: picked);
  }

  // ── build ────────────────────────────────────────────────────────────────
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
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF0F2FA),
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(context, isDark, isMobile),
        body: SizedBox.expand(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_attachments.isNotEmpty)
                _AttachmentStrip(
                  attachments: _attachments,
                  isDark: isDark,
                  onAdd: _pickAttachment,
                  onRemove: _removeAttachment,
                ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _PageSurface(
                        isDark: isDark,
                        isMobile: isMobile,
                        child: _BlockList(
                          blocks: _blocks,
                          isDark: isDark,
                          isMobile: isMobile,
                          controllerFor: _ctrlFor,
                          focusNodeFor: _focusFor,
                          onChangeType: _changeType,
                          onDelete: _deleteBlock,
                          onDuplicate: _duplicateBlock,
                          onToggleTodo: _toggleTodo,
                          onSplit: _splitBlock,
                          onReorder: _reorderBlocks,
                          onAddBlock: () =>
                              _showAddBlockSheet(afterId: _blocks.last.id),
                          onCalloutEmoji: (id) => _editCalloutEmoji(id),
                        ),
                      ),
                    ),
                    if (isDesktop && _varsPanelOpen)
                      _VarsSidePanel(
                        isDark: isDark,
                        letterVariables: _letterVariables,
                        onInsert: _insertVariable,
                        onClose: () =>
                            setState(() => _varsPanelOpen = false),
                      ),
                  ],
                ),
              ),
              if (isMobile && keyboardOpen)
                _MobileQuickBar(
                  isDark: isDark,
                  activeType: _activeBlockId == null
                      ? null
                      : _blocks
                          .firstWhere(
                            (b) => b.id == _activeBlockId,
                            orElse: () => _blocks.first,
                          )
                          .type,
                  onPickType: (type) {
                    final id = _activeBlockId;
                    if (id != null) _changeType(id, type);
                  },
                  onAddBlock: () =>
                      _showAddBlockSheet(afterId: _activeBlockId),
                  onInsertVar: _showVarsBottomSheet,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editCalloutEmoji(String id) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _EmojiPicker(),
    );
    if (picked == null || !mounted) return;
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    setState(() => _blocks[idx].emoji = picked);
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

// ─── page surface (the white "document" card) ───────────────────────────────
//
// Centers the card horizontally with a max width of 880, while passing
// TIGHT constraints all the way down so the inner CustomScrollView has
// bounded height. We use LayoutBuilder + asymmetric Padding rather than
// Center+ConstrainedBox because Center passes loose vertical constraints
// and any unbounded ScrollView below it crashes.
class _PageSurface extends StatelessWidget {
  final bool isDark;
  final bool isMobile;
  final Widget child;

  const _PageSurface({
    required this.isDark,
    required this.isMobile,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const maxCardWidth = 880.0;
    final outerH = isMobile ? 8.0 : 24.0;
    final outerV = isMobile ? 8.0 : 24.0;

    return Container(
      color: isDark ? AppColors.darkBg : const Color(0xFFF0F2FA),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available =
              (constraints.maxWidth - outerH * 2).clamp(0.0, double.infinity);
          final cardW = available.clamp(0.0, maxCardWidth);
          final sideExtra =
              ((available - cardW) / 2).clamp(0.0, double.infinity);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              outerH + sideExtra,
              outerV,
              outerH + sideExtra,
              outerV,
            ),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.24 : 0.06),
                    blurRadius: isMobile ? 8 : 22,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// ─── block list ─────────────────────────────────────────────────────────────
class _BlockList extends StatelessWidget {
  final List<_Block> blocks;
  final bool isDark;
  final bool isMobile;
  final TextEditingController Function(_Block) controllerFor;
  final FocusNode Function(_Block) focusNodeFor;
  final void Function(String id, _BlockType type) onChangeType;
  final void Function(String id) onDelete;
  final void Function(String id) onDuplicate;
  final void Function(String id) onToggleTodo;
  final void Function(String id, String afterText) onSplit;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onAddBlock;
  final void Function(String id) onCalloutEmoji;

  const _BlockList({
    required this.blocks,
    required this.isDark,
    required this.isMobile,
    required this.controllerFor,
    required this.focusNodeFor,
    required this.onChangeType,
    required this.onDelete,
    required this.onDuplicate,
    required this.onToggleTodo,
    required this.onSplit,
    required this.onReorder,
    required this.onAddBlock,
    required this.onCalloutEmoji,
  });

  // Compute the ordinal number for a numbered-list block by counting
  // consecutive numbered blocks above it (a fresh group restarts at 1).
  int _numberedOrdinal(int idx) {
    var n = 1;
    for (var i = idx - 1; i >= 0; i--) {
      if (blocks[i].type == _BlockType.numbered) {
        n++;
      } else {
        break;
      }
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final pageHPad = isMobile ? 12.0 : 56.0;
    final pageVPad = isMobile ? 18.0 : 36.0;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pageHPad, pageVPad, pageHPad, 0),
          sliver: SliverReorderableList(
            itemCount: blocks.length,
            onReorder: onReorder,
            itemBuilder: (context, idx) {
              final block = blocks[idx];
              return _BlockTile(
                key: ValueKey('block-${block.id}'),
                block: block,
                index: idx,
                isDark: isDark,
                isMobile: isMobile,
                controller:
                    block.type.hasText ? controllerFor(block) : null,
                focusNode: block.type.hasText ? focusNodeFor(block) : null,
                numberedOrdinal: block.type == _BlockType.numbered
                    ? _numberedOrdinal(idx)
                    : null,
                onChangeType: (type) => onChangeType(block.id, type),
                onDelete: () => onDelete(block.id),
                onDuplicate: () => onDuplicate(block.id),
                onToggleTodo: () => onToggleTodo(block.id),
                onSplit: (afterText) => onSplit(block.id, afterText),
                onCalloutEmoji: () => onCalloutEmoji(block.id),
              );
            },
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pageHPad, 8, pageHPad, pageVPad),
          sliver: SliverToBoxAdapter(
            child: _AddBlockTile(
              isDark: isDark,
              isMobile: isMobile,
              onTap: onAddBlock,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── block tile ─────────────────────────────────────────────────────────────
class _BlockTile extends StatelessWidget {
  final _Block block;
  final int index;
  final bool isDark;
  final bool isMobile;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final int? numberedOrdinal;
  final void Function(_BlockType) onChangeType;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleTodo;
  final void Function(String afterText) onSplit;
  final VoidCallback onCalloutEmoji;

  const _BlockTile({
    required Key key,
    required this.block,
    required this.index,
    required this.isDark,
    required this.isMobile,
    required this.controller,
    required this.focusNode,
    required this.numberedOrdinal,
    required this.onChangeType,
    required this.onDelete,
    required this.onDuplicate,
    required this.onToggleTodo,
    required this.onSplit,
    required this.onCalloutEmoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle — long-press on mobile, immediate on desktop
          _DragHandle(index: index, isDark: isDark, isMobile: isMobile),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _content(context),
            ),
          ),
          // Actions
          _BlockActions(
            block: block,
            isDark: isDark,
            onChangeType: onChangeType,
            onDelete: onDelete,
            onDuplicate: onDuplicate,
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    switch (block.type) {
      case _BlockType.paragraph:
        return _BlockEditor(
          controller: controller!,
          focusNode: focusNode!,
          isDark: isDark,
          fontSize: isMobile ? 15 : 16,
          height: 1.55,
          hint: UiText.startWritingYourLetterTemplate,
          allowsHardNewlines: false,
          onSplit: onSplit,
        );
      case _BlockType.heading1:
        return _BlockEditor(
          controller: controller!,
          focusNode: focusNode!,
          isDark: isDark,
          fontSize: isMobile ? 26 : 32,
          fontWeight: FontWeight.w800,
          height: 1.25,
          hint: 'Heading 1',
          allowsHardNewlines: false,
          onSplit: onSplit,
        );
      case _BlockType.heading2:
        return _BlockEditor(
          controller: controller!,
          focusNode: focusNode!,
          isDark: isDark,
          fontSize: isMobile ? 21 : 25,
          fontWeight: FontWeight.w700,
          height: 1.3,
          hint: 'Heading 2',
          allowsHardNewlines: false,
          onSplit: onSplit,
        );
      case _BlockType.heading3:
        return _BlockEditor(
          controller: controller!,
          focusNode: focusNode!,
          isDark: isDark,
          fontSize: isMobile ? 17 : 19,
          fontWeight: FontWeight.w700,
          height: 1.35,
          hint: 'Heading 3',
          allowsHardNewlines: false,
          onSplit: onSplit,
        );
      case _BlockType.bullet:
        return _MarkedRow(
          marker: Text(
            '•',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
              height: 1.4,
            ),
          ),
          child: _BlockEditor(
            controller: controller!,
            focusNode: focusNode!,
            isDark: isDark,
            fontSize: isMobile ? 15 : 16,
            height: 1.55,
            hint: 'List item',
            allowsHardNewlines: false,
            onSplit: onSplit,
          ),
        );
      case _BlockType.numbered:
        return _MarkedRow(
          marker: Text(
            '${numberedOrdinal ?? 1}.',
            style: TextStyle(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
              height: 1.55,
            ),
          ),
          child: _BlockEditor(
            controller: controller!,
            focusNode: focusNode!,
            isDark: isDark,
            fontSize: isMobile ? 15 : 16,
            height: 1.55,
            hint: 'List item',
            allowsHardNewlines: false,
            onSplit: onSplit,
          ),
        );
      case _BlockType.todo:
        return _MarkedRow(
          markerWidth: 28,
          marker: GestureDetector(
            onTap: onToggleTodo,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: block.checked
                      ? (isDark
                          ? AppColors.primaryLight
                          : AppColors.primary)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: block.checked
                        ? Colors.transparent
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    width: 1.5,
                  ),
                ),
                child: block.checked
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
          ),
          child: _BlockEditor(
            controller: controller!,
            focusNode: focusNode!,
            isDark: isDark,
            fontSize: isMobile ? 15 : 16,
            height: 1.55,
            hint: 'To-do',
            allowsHardNewlines: false,
            decoration: block.checked ? TextDecoration.lineThrough : null,
            decorationColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            textColor: block.checked
                ? (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary)
                : null,
            onSplit: onSplit,
          ),
        );
      case _BlockType.quote:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsetsDirectional.only(start: 14, top: 4, bottom: 4),
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(
                color: isDark ? AppColors.primaryLight : AppColors.primary,
                width: 3,
              ),
            ),
          ),
          child: _BlockEditor(
            controller: controller!,
            focusNode: focusNode!,
            isDark: isDark,
            fontSize: isMobile ? 15 : 16,
            fontStyle: FontStyle.italic,
            height: 1.55,
            hint: 'Quote',
            allowsHardNewlines: false,
            onSplit: onSplit,
            textColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        );
      case _BlockType.code:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0B1326)
                : const Color(0xFFF4F5FB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: _BlockEditor(
            controller: controller!,
            focusNode: focusNode!,
            isDark: isDark,
            fontSize: isMobile ? 13 : 14,
            height: 1.5,
            fontFamily: 'monospace',
            hint: 'Code',
            allowsHardNewlines: true,
            onSplit: onSplit,
          ),
        );
      case _BlockType.callout:
        final bg = isDark
            ? AppColors.primaryLight.withValues(alpha: 0.10)
            : AppColors.primarySurface;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? AppColors.primaryLight.withValues(alpha: 0.25)
                  : AppColors.primarySurface,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onCalloutEmoji,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  child: Text(
                    block.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BlockEditor(
                  controller: controller!,
                  focusNode: focusNode!,
                  isDark: isDark,
                  fontSize: isMobile ? 14 : 15,
                  height: 1.5,
                  hint: 'Callout',
                  allowsHardNewlines: false,
                  onSplit: onSplit,
                ),
              ),
            ],
          ),
        );
      case _BlockType.divider:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        );
    }
  }
}

class _MarkedRow extends StatelessWidget {
  final Widget marker;
  final Widget child;
  final double markerWidth;
  const _MarkedRow({
    required this.marker,
    required this.child,
    this.markerWidth = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: markerWidth,
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: marker,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  final int index;
  final bool isDark;
  final bool isMobile;
  const _DragHandle({
    required this.index,
    required this.isDark,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = (isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary)
        .withValues(alpha: 0.55);

    final inner = Icon(
      Icons.drag_indicator_rounded,
      size: 16,
      color: iconColor,
    );
    final wrapped = Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(width: 22, child: inner),
    );

    return isMobile
        ? ReorderableDelayedDragStartListener(index: index, child: wrapped)
        : ReorderableDragStartListener(index: index, child: wrapped);
  }
}

// ─── block editor (TextField with split-on-newline) ─────────────────────────
class _BlockEditor extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final double fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final double height;
  final String? fontFamily;
  final String hint;
  final bool allowsHardNewlines;
  final void Function(String afterText) onSplit;
  final TextDecoration? decoration;
  final Color? decorationColor;
  final Color? textColor;

  const _BlockEditor({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.fontSize,
    this.fontWeight,
    this.fontStyle,
    required this.height,
    this.fontFamily,
    required this.hint,
    required this.allowsHardNewlines,
    required this.onSplit,
    this.decoration,
    this.decorationColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: null,
      minLines: 1,
      // multiline keyboard type guarantees the soft-keyboard Enter key
      // emits "\n", which our formatter then converts to a block split.
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: allowsHardNewlines
          ? TextCapitalization.none
          : TextCapitalization.sentences,
      inputFormatters: allowsHardNewlines
          ? null
          : [_SplitOnNewlineFormatter(onSplit)],
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        height: height,
        fontFamily: fontFamily,
        decoration: decoration,
        decorationColor: decorationColor,
        color: textColor ??
            (isDark ? AppColors.darkText : AppColors.lightText),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: (isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary)
              .withValues(alpha: 0.6),
          fontWeight: fontWeight,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
        isDense: true,
      ),
    );
  }
}

// Input formatter that intercepts a single newline and turns it into a
// "split this block" callback, with everything after the newline becoming
// the text of a new block below this one.
class _SplitOnNewlineFormatter extends TextInputFormatter {
  final void Function(String afterText) onSplit;
  _SplitOnNewlineFormatter(this.onSplit);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final idx = newValue.text.indexOf('\n');
    if (idx == -1) return newValue;

    final before = newValue.text.substring(0, idx);
    final after = newValue.text.substring(idx + 1);

    // Defer the structural change until after the input system has finished
    // applying this edit; modifying the widget tree during formatEditUpdate
    // is not safe.
    WidgetsBinding.instance.addPostFrameCallback((_) => onSplit(after));

    return TextEditingValue(
      text: before,
      selection: TextSelection.collapsed(offset: before.length),
    );
  }
}

// ─── block actions menu ─────────────────────────────────────────────────────
class _BlockActions extends StatelessWidget {
  final _Block block;
  final bool isDark;
  final void Function(_BlockType) onChangeType;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _BlockActions({
    required this.block,
    required this.isDark,
    required this.onChangeType,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final color = (isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary)
        .withValues(alpha: 0.7);

    return PopupMenuButton<String>(
      tooltip: 'Block menu',
      icon: Icon(Icons.more_horiz_rounded, size: 18, color: color),
      padding: EdgeInsets.zero,
      splashRadius: 18,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      itemBuilder: (ctx) => [
        const PopupMenuItem<String>(
          enabled: false,
          height: 28,
          child: Text(
            'Turn into',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        ..._BlockType.values.map(
          (t) => PopupMenuItem<String>(
            value: 'type:${t.name}',
            height: 36,
            child: Row(
              children: [
                Icon(t.icon, size: 16),
                const SizedBox(width: 10),
                Text(t.label, style: const TextStyle(fontSize: 13)),
                if (t == block.type) ...[
                  const Spacer(),
                  const Icon(Icons.check_rounded, size: 14),
                ],
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'duplicate',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.content_copy_rounded, size: 16),
              SizedBox(width: 10),
              Text('Duplicate', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 16, color: AppColors.error),
              SizedBox(width: 10),
              Text('Delete',
                  style: TextStyle(fontSize: 13, color: AppColors.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'delete') {
          onDelete();
        } else if (value == 'duplicate') {
          onDuplicate();
        } else if (value.startsWith('type:')) {
          final typeName = value.substring('type:'.length);
          final type = _BlockType.values
              .firstWhere((t) => t.name == typeName, orElse: () => block.type);
          onChangeType(type);
        }
      },
    );
  }
}

// ─── add-block tile ─────────────────────────────────────────────────────────
class _AddBlockTile extends StatelessWidget {
  final bool isDark;
  final bool isMobile;
  final VoidCallback onTap;

  const _AddBlockTile({
    required this.isDark,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.primaryLight : AppColors.primary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isMobile ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: border.withValues(alpha: 0.6),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.add_rounded, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              'Add block',
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              'Choose a type',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── block-type picker sheet ────────────────────────────────────────────────
class _BlockTypePicker extends StatelessWidget {
  const _BlockTypePicker();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final groups = <(_BlockType, String)>[
      (_BlockType.paragraph, 'Plain text paragraph'),
      (_BlockType.heading1, 'Largest section header'),
      (_BlockType.heading2, 'Medium section header'),
      (_BlockType.heading3, 'Small section header'),
      (_BlockType.bullet, 'Bulleted list'),
      (_BlockType.numbered, 'Numbered list'),
      (_BlockType.todo, 'Track tasks with checkboxes'),
      (_BlockType.quote, 'Set apart a quote'),
      (_BlockType.code, 'Monospaced code block'),
      (_BlockType.callout, 'Emphasised note with emoji'),
      (_BlockType.divider, 'Horizontal rule'),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.add_box_outlined, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  'Add block',
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
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: groups.length,
              itemBuilder: (ctx, i) {
                final (type, desc) = groups[i];
                return ListTile(
                  leading: Icon(type.icon, color: accent),
                  title: Text(
                    type.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── emoji picker ───────────────────────────────────────────────────────────
class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker();

  static const _emojis = [
    '💡', '⭐', '🔥', '✅', '⚠️', '❗', '📝', '📌',
    '🎯', '🚀', '🧠', '❤️', '👀', '📣', '🛎️', '🪄',
    '💬', '📊', '📅', '🔍', '💼', '🎉', '🌟', '🧩',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Pick an icon',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis
                  .map((e) => InkWell(
                        onTap: () => Navigator.pop(context, e),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(e,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── mobile quick action bar (above keyboard) ───────────────────────────────
class _MobileQuickBar extends StatelessWidget {
  final bool isDark;
  final _BlockType? activeType;
  final void Function(_BlockType) onPickType;
  final VoidCallback onAddBlock;
  final VoidCallback onInsertVar;

  const _MobileQuickBar({
    required this.isDark,
    required this.activeType,
    required this.onPickType,
    required this.onAddBlock,
    required this.onInsertVar,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final fade = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final quickTypes = [
      _BlockType.heading1,
      _BlockType.heading2,
      _BlockType.heading3,
      _BlockType.bullet,
      _BlockType.numbered,
      _BlockType.todo,
      _BlockType.quote,
      _BlockType.code,
      _BlockType.callout,
      _BlockType.divider,
    ];

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: border)),
        ),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              _BarIconButton(
                icon: Icons.data_object_rounded,
                tooltip: UiText.variables,
                color: accent,
                onTap: onInsertVar,
              ),
              VerticalDivider(width: 1, color: border),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: quickTypes.map((t) {
                    final selected = t == activeType;
                    return _BarChipButton(
                      icon: t.icon,
                      selected: selected,
                      color: selected ? accent : fade,
                      onTap: () => onPickType(t),
                    );
                  }).toList(),
                ),
              ),
              VerticalDivider(width: 1, color: border),
              _BarIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Add block',
                color: accent,
                onTap: onAddBlock,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  const _BarIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: IconButton(
        icon: Icon(icon, size: 19),
        color: color,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }
}

class _BarChipButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _BarChipButton({
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ─── attachment strip ───────────────────────────────────────────────────────
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

// ─── variables side panel (desktop) ─────────────────────────────────────────
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

// ─── variables bottom sheet (mobile / tablet) ──────────────────────────────
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
