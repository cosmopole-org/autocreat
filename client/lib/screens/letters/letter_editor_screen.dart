import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/demo_data.dart';
import '../../data/ui_text.dart';
import '../../models/letter_template.dart';
import '../../providers/demo_provider.dart';
import '../../providers/letter_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'designer/canvas.dart';
import 'designer/models.dart';
import 'designer/properties_panel.dart';
import 'designer/side_panel.dart';
import 'designer/toolbar.dart';

// ─── breakpoints ───────────────────────────────────────────────────────────
const double _kTablet = 720.0;
const double _kDesktop = 1180.0;

class LetterEditorScreen extends ConsumerStatefulWidget {
  final String letterId;
  const LetterEditorScreen({super.key, required this.letterId});

  @override
  ConsumerState<LetterEditorScreen> createState() => _LetterEditorScreenState();
}

class _LetterEditorScreenState extends ConsumerState<LetterEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // designer state
  final List<DesignElement> _elements = [];
  String? _selectedId;
  PageSize _pageSize = PageSize.a4Portrait;
  double _zoom = 0.85;
  bool _showGrid = true;
  bool _snapToGrid = true;
  final double _gridSize = 8;
  bool _zoomInitialized = false;

  bool _loading = true;
  bool _saving = false;

  String? _letterId;
  List<String> _letterVariables = [];
  final List<PlatformFile> _attachments = [];

  // panel state
  bool _toolbarCollapsed = false;
  bool _sidePanelOpen = false;
  bool _propsPanelOpen = true;

  // undo / redo
  final List<List<DesignElement>> _undoStack = [];
  final List<List<DesignElement>> _redoStack = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLetter());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─── load / save ─────────────────────────────────────────────────────────
  Future<void> _loadLetter() async {
    if (widget.letterId == 'new') {
      _seedNewDocument();
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
      _elements
        ..clear()
        ..addAll(_elementsFromLetter(letter));
      if (_elements.isEmpty) _seedNewDocument();
    } catch (_) {
      _seedNewDocument();
    }
    _pushUndo(initial: true);
    if (mounted) setState(() => _loading = false);
  }

  void _seedNewDocument() {
    final page = _pageSize.pixels;
    _elements
      ..clear()
      ..add(DesignElement(
        id: newElementId(),
        kind: ElementKind.heading1,
        x: 64,
        y: 64,
        width: page.width - 128,
        height: 70,
        text: 'Untitled letter',
        z: 0,
      ))
      ..add(DesignElement(
        id: newElementId(),
        kind: ElementKind.text,
        x: 64,
        y: 156,
        width: page.width - 128,
        height: 120,
        text:
            'Start typing or drag any block from the left toolbar onto the page.\n\nElements snap to a grid by default. Toggle freeform mode from the top bar to position anything anywhere.',
        z: 1,
        fontSize: 14,
      ));
  }

  List<DesignElement> _elementsFromLetter(LetterTemplate letter) {
    final out = <DesignElement>[];
    try {
      final raw = letter.deltaContent['elements'] as List<dynamic>?;
      if (raw != null && raw.isNotEmpty) {
        for (final e in raw.whereType<Map<String, dynamic>>()) {
          out.add(DesignElement.fromJson(e));
        }
        return out;
      }
    } catch (_) {/* fall through */}

    try {
      final blocks = letter.deltaContent['blocks'] as List<dynamic>?;
      if (blocks != null && blocks.isNotEmpty) {
        return _migrateLegacyBlocks(
            blocks.whereType<Map<String, dynamic>>().toList());
      }
    } catch (_) {/* fall through */}

    if (letter.content.isNotEmpty) {
      final page = _pageSize.pixels;
      out.add(DesignElement(
        id: newElementId(),
        kind: ElementKind.text,
        x: 64,
        y: 64,
        width: page.width - 128,
        height: 400,
        text: letter.content,
      ));
    }
    return out;
  }

  List<DesignElement> _migrateLegacyBlocks(List<Map<String, dynamic>> blocks) {
    final page = _pageSize.pixels;
    final out = <DesignElement>[];
    double y = 64.0;
    const x = 64.0;
    final w = page.width - 128;
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final type = (b['type'] as String?) ?? 'paragraph';
      final text = (b['text'] as String?) ?? '';
      ElementKind kind;
      double h;
      double fs;
      switch (type) {
        case 'heading1':
          kind = ElementKind.heading1;
          h = 70;
          fs = 30;
          break;
        case 'heading2':
          kind = ElementKind.heading2;
          h = 56;
          fs = 24;
          break;
        case 'heading3':
          kind = ElementKind.heading3;
          h = 48;
          fs = 19;
          break;
        case 'bullet':
          kind = ElementKind.bulletList;
          h = 100;
          fs = 14;
          break;
        case 'numbered':
          kind = ElementKind.numberedList;
          h = 100;
          fs = 14;
          break;
        case 'quote':
          kind = ElementKind.quote;
          h = 90;
          fs = 15;
          break;
        case 'code':
          kind = ElementKind.code;
          h = 120;
          fs = 13;
          break;
        case 'callout':
          kind = ElementKind.callout;
          h = 100;
          fs = 14;
          break;
        case 'divider':
          kind = ElementKind.divider;
          h = 24;
          fs = 14;
          break;
        case 'todo':
          kind = ElementKind.bulletList;
          h = 50;
          fs = 14;
          break;
        case 'paragraph':
        default:
          kind = ElementKind.text;
          h = 90;
          fs = 14;
          break;
      }
      final el = DesignElement(
        id: (b['id'] as String?) ?? newElementId(),
        kind: kind,
        x: x,
        y: y,
        width: w,
        height: h,
        text: text,
        fontSize: fs,
        z: i,
      );
      if (kind == ElementKind.callout && b['emoji'] is String) {
        el.data['emoji'] = b['emoji'];
      }
      out.add(el);
      y += h + 12;
    }
    return out;
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(UiText.templateName),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(letterRepositoryProvider);
      final plain = StringBuffer();
      for (final el in _elements) {
        if (el.text.trim().isNotEmpty) plain.writeln(el.text);
      }
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
        'content': plain.toString().trimRight(),
        UiText.deltacontent: {
          'version': 3,
          'pageSize': _pageSize.name,
          'elements': _elements.map((e) => e.toJson()).toList(),
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

  // ─── undo / redo ─────────────────────────────────────────────────────────
  List<DesignElement> _snapshot() {
    return _elements
        .map((e) => DesignElement.fromJson(e.toJson()..['id'] = e.id))
        .toList();
  }

  void _pushUndo({bool initial = false}) {
    _undoStack.add(_snapshot());
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    if (!initial) _redoStack.clear();
  }

  void _restore(List<DesignElement> snap) {
    _elements
      ..clear()
      ..addAll(snap);
    if (_selectedId != null &&
        _elements.indexWhere((e) => e.id == _selectedId) == -1) {
      _selectedId = null;
    }
  }

  void _undo() {
    if (_undoStack.length < 2) return;
    final current = _undoStack.removeLast();
    _redoStack.add(current);
    setState(() => _restore(_undoStack.last));
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(next);
    setState(() => _restore(next));
  }

  // ─── element actions ─────────────────────────────────────────────────────
  int _nextZ() {
    if (_elements.isEmpty) return 0;
    return _elements.map((e) => e.z).reduce((a, b) => a > b ? a : b) + 1;
  }

  void _insertElement(ElementKind kind, {Offset? at}) {
    final size = kind.defaultSize;
    final page = _pageSize.pixels;
    double x = at?.dx ?? 64;
    double y = at?.dy ?? _findNextY();
    if (x + size.width > page.width) x = page.width - size.width;
    if (y + size.height > page.height) y = page.height - size.height;
    final el = DesignElement(
      id: newElementId(),
      kind: kind,
      x: x.clamp(0, page.width - size.width).toDouble(),
      y: y.clamp(0, page.height - size.height).toDouble(),
      width: size.width,
      height: size.height,
      z: _nextZ(),
    );
    _seedKindData(el);
    setState(() {
      _elements.add(el);
      _selectedId = el.id;
    });
    _pushUndo();
  }

  void _seedKindData(DesignElement el) {
    switch (el.kind) {
      case ElementKind.heading1:
        el.text = 'Heading 1';
        el.fontSize = 30;
        break;
      case ElementKind.heading2:
        el.text = 'Heading 2';
        el.fontSize = 24;
        break;
      case ElementKind.heading3:
        el.text = 'Heading 3';
        el.fontSize = 19;
        break;
      case ElementKind.text:
        el.text = '';
        el.fontSize = 14;
        break;
      case ElementKind.quote:
        el.text = 'A memorable quote goes here.';
        el.fontSize = 15;
        break;
      case ElementKind.code:
        el.text = '// code snippet';
        break;
      case ElementKind.callout:
        el.text = 'Important — read this carefully.';
        el.data['emoji'] = '💡';
        break;
      case ElementKind.bulletList:
      case ElementKind.numberedList:
        el.text = 'First item\nSecond item\nThird item';
        break;
      case ElementKind.wordArt:
        el.text = 'Headline';
        el.fontSize = 46;
        break;
      case ElementKind.table:
        el.data['rows'] = [
          ['Name', 'Quantity', 'Price'],
          ['Item A', '2', '10.00'],
          ['Item B', '1', '24.50'],
          ['Item C', '5', '6.20'],
        ];
        el.data['stripe'] = true;
        break;
      case ElementKind.barChart:
      case ElementKind.lineChart:
      case ElementKind.pieChart:
        el.text = 'Chart title';
        el.data['values'] = [12, 28, 19, 34, 22, 41, 30];
        el.data['labels'] = ['L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7'];
        break;
      case ElementKind.kpi:
        el.data['label'] = 'Revenue';
        el.data['value'] = '\$128k';
        el.data['delta'] = '+12.4%';
        break;
      case ElementKind.attachment:
        el.data['name'] = 'document.pdf';
        el.data['caption'] = 'Attached file';
        break;
      case ElementKind.columns:
        el.data['count'] = 2;
        el.data['texts'] = ['Left column…', 'Right column…'];
        break;
      case ElementKind.qrCode:
        el.data['value'] = 'https://example.com';
        break;
      case ElementKind.image:
        el.data['fit'] = 'cover';
        break;
      case ElementKind.divider:
        el.data['style'] = 'solid';
        el.borderWidth = 1.5;
        break;
      case ElementKind.signature:
        el.data['name'] = 'Jane Doe';
        el.data['caption'] = 'Authorized signature';
        break;
      case ElementKind.shapeRect:
      case ElementKind.shapeOval:
        break;
    }
  }

  double _findNextY() {
    if (_elements.isEmpty) return 64;
    double maxBottom = 0;
    for (final e in _elements) {
      if (e.y + e.height > maxBottom) maxBottom = e.y + e.height;
    }
    return maxBottom + 16;
  }

  void _deleteSelected() {
    if (_selectedId == null) return;
    setState(() {
      _elements.removeWhere((e) => e.id == _selectedId);
      _selectedId = null;
    });
    _pushUndo();
  }

  void _duplicateSelected() {
    final src = _selectedElement;
    if (src == null) return;
    final copy = src.copy()
      ..x = (src.x + 16)
      ..y = (src.y + 16)
      ..z = _nextZ();
    setState(() {
      _elements.add(copy);
      _selectedId = copy.id;
    });
    _pushUndo();
  }

  void _bringForward() {
    final el = _selectedElement;
    if (el == null) return;
    setState(() => el.z = _nextZ());
  }

  void _sendBackward() {
    final el = _selectedElement;
    if (el == null) return;
    setState(() => el.z = (el.z - 1));
  }

  DesignElement? get _selectedElement {
    if (_selectedId == null) return null;
    try {
      return _elements.firstWhere((e) => e.id == _selectedId);
    } catch (_) {
      return null;
    }
  }

  // ─── attachments ─────────────────────────────────────────────────────────
  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && mounted) {
      setState(() => _attachments.addAll(result.files));
    }
  }

  void _insertAttachmentElement(PlatformFile f) {
    final size = ElementKind.attachment.defaultSize;
    final el = DesignElement(
      id: newElementId(),
      kind: ElementKind.attachment,
      x: 64,
      y: _findNextY(),
      width: size.width,
      height: size.height,
      z: _nextZ(),
    );
    el.data['name'] = f.name;
    el.data['caption'] = '${(f.size / 1024).toStringAsFixed(1)} KB';
    setState(() {
      _elements.add(el);
      _selectedId = el.id;
    });
    _pushUndo();
  }

  // ─── variables ───────────────────────────────────────────────────────────
  void _insertVariableIntoSelected(String token) {
    final el = _selectedElement;
    if (el == null || !el.kind.isTextual) {
      _insertElement(ElementKind.text);
      final created = _selectedElement;
      if (created != null) {
        setState(() => created.text = token);
      }
      return;
    }
    setState(() => el.text = '${el.text}$token');
  }

  // ─── build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final isMobile = w < _kTablet;
    final isCompact = w < _kDesktop;
    final isRtl = UiText.isRtl;

    // auto-fit initial zoom on mobile so the page fits the viewport
    if (!_zoomInitialized && isMobile) {
      final page = _pageSize.pixels;
      // estimate canvas viewport height: full height minus app bar (56),
      // secondary toolbar (44), bottom bar (56) and safe area
      final viewportH = media.size.height -
          56 -
          44 -
          56 -
          media.padding.top -
          media.padding.bottom;
      final usableW = (w - 32).clamp(60.0, double.infinity);
      final usableH = (viewportH - 32).clamp(60.0, double.infinity);
      final fitW = usableW / page.width;
      final fitH = usableH / page.height;
      final fit =
          (fitW < fitH ? fitW : fitH).clamp(0.25, 1.0).toDouble();
      _zoom = fit;
      _zoomInitialized = true;
    } else if (!_zoomInitialized) {
      _zoomInitialized = true;
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFECEFF8),
        appBar: _appBar(context, isDark, isMobile),
        body: Column(
          children: [
            _SecondaryToolbar(
              isDark: isDark,
              pageSize: _pageSize,
              showGrid: _showGrid,
              snapToGrid: _snapToGrid,
              hasSelection: _selectedId != null,
              canUndo: _undoStack.length > 1,
              canRedo: _redoStack.isNotEmpty,
              onPageSize: (p) => setState(() {
                _pageSize = p;
                _selectedId = null;
              }),
              onToggleGrid: () => setState(() => _showGrid = !_showGrid),
              onToggleSnap: () => setState(() => _snapToGrid = !_snapToGrid),
              onUndo: _undo,
              onRedo: _redo,
              onDuplicate: _duplicateSelected,
              onDelete: _deleteSelected,
              onShowVariables: () =>
                  setState(() => _sidePanelOpen = !_sidePanelOpen),
              onShowProperties: () =>
                  setState(() => _propsPanelOpen = !_propsPanelOpen),
              isMobile: isMobile,
            ),
            Expanded(
              child: Row(
                children: [
                  if (!isMobile)
                    DesignerToolbar(
                      isDark: isDark,
                      collapsed: _toolbarCollapsed || isCompact,
                      onToggleCollapse: isCompact
                          ? null
                          : () => setState(
                              () => _toolbarCollapsed = !_toolbarCollapsed),
                      onPick: (k) => _insertElement(k),
                    ),
                  Expanded(
                    child: DesignerCanvas(
                      elements: _elements,
                      selectedId: _selectedId,
                      pageSize: _pageSize,
                      zoom: _zoom,
                      showGrid: _showGrid,
                      snapToGrid: _snapToGrid,
                      gridSize: _gridSize,
                      isDark: isDark,
                      onSelect: (id) => setState(() => _selectedId = id),
                      onActivate: (id) =>
                          setState(() => _selectedId = id),
                      onChanged: (_) => setState(() {}),
                      onDeleteSelected: _deleteSelected,
                      onZoom: (z) => setState(() => _zoom = z),
                    ),
                  ),
                  if (!isMobile && !isCompact && _propsPanelOpen)
                    PropertiesPanel(
                      element: _selectedElement,
                      isDark: isDark,
                      onChanged: (_) => setState(() {}),
                      onDelete: _deleteSelected,
                      onDuplicate: _duplicateSelected,
                      onBringForward: _bringForward,
                      onSendBackward: _sendBackward,
                    ),
                  if (!isMobile && _sidePanelOpen)
                    SidePanel(
                      isDark: isDark,
                      letterVariables: _letterVariables,
                      attachments: _attachments,
                      onInsertVariable: _insertVariableIntoSelected,
                      onInsertAttachment: _insertAttachmentElement,
                      onPickAttachment: _pickAttachment,
                      onRemoveAttachment: (i) =>
                          setState(() => _attachments.removeAt(i)),
                      onClose: () =>
                          setState(() => _sidePanelOpen = false),
                    ),
                ],
              ),
            ),
            if (isMobile)
              _MobileBottomBar(
                isDark: isDark,
                selected: _selectedElement,
                onInsert: () => _showMobileInsertSheet(context, isDark),
                onProperties: () =>
                    _showMobilePropertiesSheet(context, isDark),
                onVariables: () => _showMobileSidePanel(context, isDark),
                onDuplicate:
                    _selectedId == null ? null : _duplicateSelected,
                onDelete: _selectedId == null ? null : _deleteSelected,
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, bool isDark, bool isMobile) {
    return AppBar(
      leading: AppBarBackButton(onPressed: () => context.pop()),
      titleSpacing: 4,
      title: TextField(
        controller: _nameCtrl,
        decoration: InputDecoration(
          hintText: UiText.templateName,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          hintStyle: TextStyle(
            color: isDark
                ? AppColors.darkTextHint
                : AppColors.lightTextHint,
          ),
        ),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
      ),
      actions: [
        if (!isMobile)
          AppBarIconButton(
            icon: Icons.attach_file_rounded,
            tooltip: UiText.attach,
            onPressed: _pickAttachment,
          ),
        AppBarIconButton(
          icon: Icons.data_object_rounded,
          tooltip: UiText.variables,
          onPressed: () =>
              setState(() => _sidePanelOpen = !_sidePanelOpen),
        ),
        const SizedBox(width: 4),
        AppBarActionButton(
          label: isMobile ? '' : UiText.save,
          loading: _saving,
          onPressed: _save,
          icon: Icons.save_outlined,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─── mobile sheets ───────────────────────────────────────────────────────
  Future<void> _showMobileInsertSheet(
      BuildContext context, bool isDark) async {
    final picked = await showModalBottomSheet<ElementKind>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => _MobileInsertSheet(isDark: isDark),
    );
    if (picked != null) _insertElement(picked);
  }

  Future<void> _showMobilePropertiesSheet(
      BuildContext context, bool isDark) async {
    if (_selectedElement == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          return _MobileSheet(
            isDark: isDark,
            child: PropertiesPanel(
              element: _selectedElement,
              isDark: isDark,
              compact: true,
              onChanged: (_) {
                setSt(() {});
                setState(() {});
              },
              onDelete: () {
                Navigator.pop(ctx);
                _deleteSelected();
              },
              onDuplicate: () {
                Navigator.pop(ctx);
                _duplicateSelected();
              },
              onBringForward: _bringForward,
              onSendBackward: _sendBackward,
              onClose: () => Navigator.pop(ctx),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showMobileSidePanel(
      BuildContext context, bool isDark) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MobileSheet(
        isDark: isDark,
        child: SidePanel(
          isDark: isDark,
          compact: true,
          letterVariables: _letterVariables,
          attachments: _attachments,
          onInsertVariable: (t) {
            Navigator.pop(ctx);
            _insertVariableIntoSelected(t);
          },
          onInsertAttachment: (f) {
            Navigator.pop(ctx);
            _insertAttachmentElement(f);
          },
          onPickAttachment: _pickAttachment,
          onRemoveAttachment: (i) =>
              setState(() => _attachments.removeAt(i)),
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }
}

// ─── mobile sheet wrapper ─────────────────────────────────────────────────
class _MobileSheet extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _MobileSheet({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.82,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint)
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── secondary toolbar ─────────────────────────────────────────────────────
class _SecondaryToolbar extends StatelessWidget {
  final bool isDark;
  final PageSize pageSize;
  final bool showGrid;
  final bool snapToGrid;
  final bool hasSelection;
  final bool canUndo;
  final bool canRedo;
  final bool isMobile;
  final ValueChanged<PageSize> onPageSize;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleSnap;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onShowVariables;
  final VoidCallback onShowProperties;

  const _SecondaryToolbar({
    required this.isDark,
    required this.pageSize,
    required this.showGrid,
    required this.snapToGrid,
    required this.hasSelection,
    required this.canUndo,
    required this.canRedo,
    required this.isMobile,
    required this.onPageSize,
    required this.onToggleGrid,
    required this.onToggleSnap,
    required this.onUndo,
    required this.onRedo,
    required this.onDuplicate,
    required this.onDelete,
    required this.onShowVariables,
    required this.onShowProperties,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final height = isMobile ? 42.0 : 44.0;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
        boxShadow: isMobile
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _ToolbarBtn(
              icon: Icons.undo_rounded,
              tooltip: 'Undo',
              isDark: isDark,
              enabled: canUndo,
              onTap: onUndo,
            ),
            _ToolbarBtn(
              icon: Icons.redo_rounded,
              tooltip: 'Redo',
              isDark: isDark,
              enabled: canRedo,
              onTap: onRedo,
            ),
            _div(border),
            _ToolbarBtn(
              icon: Icons.grid_on_rounded,
              tooltip: 'Toggle grid',
              isDark: isDark,
              active: showGrid,
              onTap: onToggleGrid,
            ),
            _ToolbarBtn(
              icon: Icons.straighten_rounded,
              tooltip: snapToGrid ? 'Snap on' : 'Freeform',
              isDark: isDark,
              active: snapToGrid,
              onTap: onToggleSnap,
            ),
            _div(border),
            _pageSizeChip(context),
            if (hasSelection) ...[
              _div(border),
              _ToolbarBtn(
                icon: Icons.copy_rounded,
                tooltip: 'Duplicate',
                isDark: isDark,
                onTap: onDuplicate,
              ),
              _ToolbarBtn(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete',
                isDark: isDark,
                destructive: true,
                onTap: onDelete,
              ),
            ],
            if (!isMobile) ...[
              const SizedBox(width: 28),
              _ToolbarBtn(
                icon: Icons.tune_rounded,
                tooltip: 'Properties',
                isDark: isDark,
                onTap: onShowProperties,
              ),
              _ToolbarBtn(
                icon: Icons.data_object_rounded,
                tooltip: 'Variables & files',
                isDark: isDark,
                onTap: onShowVariables,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _div(Color border) => Container(
        width: 1,
        height: 22,
        color: border,
        margin: const EdgeInsets.symmetric(horizontal: 6),
      );

  Widget _pageSizeChip(BuildContext context) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final compact = isMobile;
    final shortLabel = pageSize.shortLabel;
    return PopupMenuButton<PageSize>(
      tooltip: 'Page size',
      onSelected: onPageSize,
      offset: const Offset(0, 38),
      itemBuilder: (ctx) => [
        for (final p in PageSize.values)
          PopupMenuItem(
            value: p,
            child: Row(
              children: [
                Icon(
                  pageSize == p
                      ? Icons.check_rounded
                      : Icons.crop_portrait_rounded,
                  size: 16,
                  color: pageSize == p ? accent : null,
                ),
                const SizedBox(width: 8),
                Text(p.label),
              ],
            ),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pageSize.isLandscape
                  ? Icons.crop_landscape_rounded
                  : Icons.crop_portrait_rounded,
              size: 14,
              color: accent,
            ),
            const SizedBox(width: 6),
            Text(
              compact ? shortLabel : pageSize.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: accent),
          ],
        ),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final bool active;
  final bool enabled;
  final bool destructive;
  final VoidCallback onTap;

  const _ToolbarBtn({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
    this.active = false,
    this.enabled = true,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final fg = destructive
        ? AppColors.error
        : active
            ? accent
            : (enabled
                ? (isDark
                    ? AppColors.darkText
                    : AppColors.lightText)
                : (isDark
                    ? AppColors.darkTextHint
                    : AppColors.lightTextHint));
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 34,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: isDark ? 0.18 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 17, color: fg),
        ),
      ),
    );
  }
}

// ─── mobile bottom bar ─────────────────────────────────────────────────────
class _MobileBottomBar extends StatelessWidget {
  final bool isDark;
  final DesignElement? selected;
  final VoidCallback onInsert;
  final VoidCallback onProperties;
  final VoidCallback onVariables;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const _MobileBottomBar({
    required this.isDark,
    required this.selected,
    required this.onInsert,
    required this.onProperties,
    required this.onVariables,
    this.onDuplicate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final hasSelection = selected != null;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasSelection)
              _selectionRow(context, accent, border),
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  _bottomBtn(
                    icon: Icons.add_rounded,
                    label: 'Insert',
                    onTap: onInsert,
                    isPrimary: true,
                    accent: accent,
                  ),
                  _bottomBtn(
                    icon: Icons.tune_rounded,
                    label: 'Style',
                    onTap: hasSelection ? onProperties : null,
                    accent: accent,
                  ),
                  _bottomBtn(
                    icon: Icons.auto_awesome_mosaic_outlined,
                    label: 'Library',
                    onTap: onVariables,
                    accent: accent,
                  ),
                  _bottomBtn(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    onTap: onDelete,
                    destructive: true,
                    accent: accent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionRow(BuildContext context, Color accent, Color border) {
    final el = selected!;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.10 : 0.06),
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.22 : 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(el.kind.icon, size: 13, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              el.kind.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          Text(
            '${el.width.round()} × ${el.height.round()}',
            style: TextStyle(
              fontSize: 10.5,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(width: 8),
          if (onDuplicate != null)
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onDuplicate,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 4),
                child: Icon(Icons.copy_rounded, size: 14, color: accent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomBtn({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color accent,
    bool isPrimary = false,
    bool destructive = false,
  }) {
    final disabled = onTap == null;
    final fg = destructive
        ? (disabled
            ? AppColors.error.withValues(alpha: 0.35)
            : AppColors.error)
        : isPrimary
            ? Colors.white
            : (disabled
                ? (isDark
                    ? AppColors.darkTextHint
                    : AppColors.lightTextHint)
                : (isDark
                    ? AppColors.darkText
                    : AppColors.lightText));
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPrimary)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent,
                        accent.withValues(alpha: 0.78),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 20, color: fg),
                )
              else
                SizedBox(
                  width: 36,
                  height: 28,
                  child: Icon(icon, size: 22, color: fg),
                ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isPrimary
                      ? (isDark
                          ? AppColors.darkText
                          : AppColors.lightText)
                      : fg,
                  fontWeight:
                      isPrimary ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── mobile insert sheet ───────────────────────────────────────────────────
class _MobileInsertSheet extends StatefulWidget {
  final bool isDark;
  const _MobileInsertSheet({required this.isDark});

  @override
  State<_MobileInsertSheet> createState() => _MobileInsertSheetState();
}

class _MobileInsertSheetState extends State<_MobileInsertSheet> {
  String _cat = 'Text';
  String _query = '';
  static const _cats = ['Text', 'Visuals', 'Data', 'Misc'];

  IconData _catIcon(String c) {
    switch (c) {
      case 'Text':
        return Icons.text_fields_rounded;
      case 'Visuals':
        return Icons.image_outlined;
      case 'Data':
        return Icons.bar_chart_rounded;
      case 'Misc':
      default:
        return Icons.widgets_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final media = MediaQuery.of(context);
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? ElementKind.values.where((k) => k.category == _cat).toList()
        : ElementKind.values
            .where((k) => k.label.toLowerCase().contains(q))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.72,
        child: Column(
          children: [
            // ─── grip ─────────────────────────────────────────────
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: (isDark
                        ? AppColors.darkTextHint
                        : AppColors.lightTextHint)
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ─── header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent,
                          accent.withValues(alpha: 0.75),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add element',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                        Text(
                          'Tap to insert · drag to position',
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
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // ─── search ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Icon(Icons.search_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextHint
                            : AppColors.lightTextHint),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Search elements',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ─── category chips ───────────────────────────────────
            if (q.isEmpty)
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final c in _cats)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => _cat = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: _cat == c
                                  ? accent.withValues(
                                      alpha: isDark ? 0.22 : 0.14)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _cat == c
                                    ? accent
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder),
                                width: _cat == c ? 1.4 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _catIcon(c),
                                  size: 13,
                                  color: _cat == c
                                      ? accent
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  c,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _cat == c
                                        ? accent
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors
                                                .lightTextSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            // ─── element grid ─────────────────────────────────────
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 28,
                              color: isDark
                                  ? AppColors.darkTextHint
                                  : AppColors.lightTextHint),
                          const SizedBox(height: 6),
                          Text(
                            'No matches',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.92,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final k = items[i];
                        return _ElementGridTile(
                          kind: k,
                          isDark: isDark,
                          onTap: () => Navigator.pop(context, k),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ElementGridTile extends StatefulWidget {
  final ElementKind kind;
  final bool isDark;
  final VoidCallback onTap;
  const _ElementGridTile({
    required this.kind,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ElementGridTile> createState() => _ElementGridTileState();
}

class _ElementGridTileState extends State<_ElementGridTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
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
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: isDark ? 0.22 : 0.16),
                      accent.withValues(alpha: isDark ? 0.10 : 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.kind.icon, color: accent, size: 20),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.kind.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkText
                        : AppColors.lightText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
