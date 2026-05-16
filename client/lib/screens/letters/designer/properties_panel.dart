import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../theme/app_colors.dart';
import 'models.dart';

class PropertiesPanel extends StatelessWidget {
  final DesignElement? element;
  final bool isDark;
  final bool compact;
  final void Function(DesignElement) onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onBringForward;
  final VoidCallback onSendBackward;
  final VoidCallback? onClose;

  const PropertiesPanel({
    super.key,
    required this.element,
    required this.isDark,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
    required this.onBringForward,
    required this.onSendBackward,
    this.compact = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final body = element == null
        ? _Empty(isDark: isDark)
        : _Body(
            element: element!,
            isDark: isDark,
            compact: compact,
            onChanged: onChanged,
            onDelete: onDelete,
            onDuplicate: onDuplicate,
            onBringForward: onBringForward,
            onSendBackward: onSendBackward,
            onClose: onClose,
          );

    if (compact) {
      return Container(color: bg, child: body);
    }
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: bg,
        border: Border(left: BorderSide(color: border)),
      ),
      child: body,
    );
  }
}

class _Empty extends StatelessWidget {
  final bool isDark;
  const _Empty({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.tune_rounded, size: 28, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            'Properties',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select an element to edit its style, layout, and content.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final DesignElement element;
  final bool isDark;
  final bool compact;
  final void Function(DesignElement) onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onBringForward;
  final VoidCallback onSendBackward;
  final VoidCallback? onClose;

  const _Body({
    required this.element,
    required this.isDark,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
    required this.onBringForward,
    required this.onSendBackward,
    this.compact = false,
    this.onClose,
  });

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body>
    with SingleTickerProviderStateMixin {
  TabController? _tabs;

  @override
  void initState() {
    super.initState();
    if (widget.compact) {
      _tabs = TabController(length: 3, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  void _setState(void Function() apply) {
    setState(apply);
    widget.onChanged(widget.element);
  }

  @override
  Widget build(BuildContext context) {
    return widget.compact ? _buildCompact() : _buildExpanded();
  }

  Widget _buildExpanded() {
    final el = widget.element;
    final isDark = widget.isDark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: Row(
            children: [
              Icon(el.kind.icon,
                  size: 18,
                  color: isDark
                      ? AppColors.primaryLight
                      : AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  el.kind.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkText
                        : AppColors.lightText,
                  ),
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 32, minHeight: 32),
                  onPressed: widget.onClose,
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            children: [
              _toolbarRow(),
              const SizedBox(height: 14),
              ..._layoutSection(),
              if (widget.element.kind.isTextual) ..._typographySection(),
              const SizedBox(height: 18),
              ..._appearanceSection(),
              ..._kindSpecific(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompact() {
    final el = widget.element;
    final isDark = widget.isDark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final showsTypography = el.kind.isTextual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // gradient header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: isDark ? 0.18 : 0.12),
                accent.withValues(alpha: isDark ? 0.06 : 0.03),
              ],
            ),
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: Row(
            children: [
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
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(el.kind.icon, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      el.kind.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                    ),
                    Text(
                      '${el.x.round()}, ${el.y.round()} · ${el.width.round()} × ${el.height.round()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _miniBtn(Icons.flip_to_back_rounded, 'Back',
                  widget.onSendBackward),
              const SizedBox(width: 4),
              _miniBtn(Icons.flip_to_front_rounded, 'Forward',
                  widget.onBringForward),
              const SizedBox(width: 4),
              _miniBtn(Icons.copy_rounded, 'Duplicate', widget.onDuplicate),
              const SizedBox(width: 4),
              _miniBtn(Icons.delete_outline_rounded, 'Delete',
                  widget.onDelete,
                  destructive: true),
              if (widget.onClose != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: widget.onClose,
                ),
              ],
            ],
          ),
        ),
        // tabs
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: TabBar(
            controller: _tabs,
            labelColor: accent,
            unselectedLabelColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            indicatorColor: accent,
            indicatorWeight: 2.4,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800),
            tabs: [
              const Tab(text: 'Layout'),
              Tab(text: showsTypography ? 'Type' : 'Style'),
              const Tab(text: 'Effects'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _padded(_layoutSection()),
              _padded(
                showsTypography
                    ? _typographySection(headerless: true)
                    : _appearanceSection(headerless: true),
              ),
              _padded([
                if (showsTypography) ..._appearanceSection(),
                ..._kindSpecific(),
                if (!showsTypography && _kindSpecific().isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No additional effects',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _padded(List<Widget> children) => ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        children: children,
      );

  List<Widget> _layoutSection() => [
        _section('Position & Size'),
        _xyRow(),
        const SizedBox(height: 8),
        _whRow(),
        const SizedBox(height: 10),
        _rotationRow(),
        const SizedBox(height: 10),
        _opacityRow(),
      ];

  List<Widget> _typographySection({bool headerless = false}) => [
        if (!headerless) const SizedBox(height: 18),
        if (!headerless) _section('Typography'),
        _fontPicker(),
        const SizedBox(height: 8),
        _fontSizeRow(),
        const SizedBox(height: 10),
        _stylePillsRow(),
        const SizedBox(height: 10),
        _alignmentRow(),
        const SizedBox(height: 10),
        _lineHeightRow(),
      ];

  List<Widget> _appearanceSection({bool headerless = false}) => [
        if (!headerless) _section('Appearance'),
        _colorRow('Text', widget.element.colorHex,
            (h) => _setState(() => widget.element.colorHex = h)),
        _colorRow('Background', widget.element.bgHex,
            (h) => _setState(() => widget.element.bgHex = h)),
        _colorRow('Border', widget.element.borderHex,
            (h) => _setState(() => widget.element.borderHex = h)),
        const SizedBox(height: 8),
        _sliderRow(
          label: 'Border width',
          value: widget.element.borderWidth,
          min: 0,
          max: 8,
          onChanged: (v) =>
              _setState(() => widget.element.borderWidth = v),
        ),
        _sliderRow(
          label: 'Corner radius',
          value: widget.element.borderRadius,
          min: 0,
          max: 40,
          onChanged: (v) =>
              _setState(() => widget.element.borderRadius = v),
        ),
      ];

  // ─── header toolbar ──────────────────────────────────────────────────────
  Widget _toolbarRow() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _miniBtn(Icons.flip_to_front_rounded, 'Bring forward',
            widget.onBringForward),
        _miniBtn(Icons.flip_to_back_rounded, 'Send backward',
            widget.onSendBackward),
        _miniBtn(Icons.copy_rounded, 'Duplicate', widget.onDuplicate),
        _miniBtn(Icons.delete_outline_rounded, 'Delete', widget.onDelete,
            destructive: true),
      ],
    );
  }

  Widget _miniBtn(IconData icon, String tooltip, VoidCallback onTap,
      {bool destructive = false}) {
    final isDark = widget.isDark;
    final fg = destructive
        ? AppColors.error
        : (isDark ? AppColors.darkText : AppColors.lightText);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 32,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkCard : Colors.white)
                .withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Icon(icon, size: 16, color: fg),
        ),
      ),
    );
  }

  // ─── sections ────────────────────────────────────────────────────────────
  Widget _section(String label) {
    final isDark = widget.isDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  // ─── position rows ───────────────────────────────────────────────────────
  Widget _xyRow() {
    return Row(
      children: [
        Expanded(
          child: _numField('X', widget.element.x,
              (v) => _setState(() => widget.element.x = v)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _numField('Y', widget.element.y,
              (v) => _setState(() => widget.element.y = v)),
        ),
      ],
    );
  }

  Widget _whRow() {
    return Row(
      children: [
        Expanded(
          child: _numField('W', widget.element.width,
              (v) => _setState(() => widget.element.width = v)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _numField('H', widget.element.height,
              (v) => _setState(() => widget.element.height = v)),
        ),
      ],
    );
  }

  Widget _rotationRow() => _sliderRow(
        label: 'Rotation',
        value: widget.element.rotation,
        min: -180,
        max: 180,
        onChanged: (v) => _setState(() => widget.element.rotation = v),
        unit: '°',
      );

  Widget _opacityRow() => _sliderRow(
        label: 'Opacity',
        value: widget.element.opacity * 100,
        min: 5,
        max: 100,
        onChanged: (v) =>
            _setState(() => widget.element.opacity = v / 100),
        unit: '%',
      );

  // ─── typography ──────────────────────────────────────────────────────────
  Widget _fontPicker() {
    final isDark = widget.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: kFontFamilies.contains(widget.element.fontFamily)
              ? widget.element.fontFamily
              : kFontFamilies.first,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
          items: [
            for (final f in kFontFamilies)
              DropdownMenuItem(value: f, child: Text(f)),
          ],
          onChanged: (v) {
            if (v != null) {
              _setState(() => widget.element.fontFamily = v);
            }
          },
        ),
      ),
    );
  }

  Widget _fontSizeRow() => _sliderRow(
        label: 'Font size',
        value: widget.element.fontSize,
        min: 8,
        max: 72,
        onChanged: (v) => _setState(() => widget.element.fontSize = v),
      );

  Widget _stylePillsRow() {
    return Row(
      children: [
        _stylePill(Icons.format_bold_rounded, widget.element.bold,
            () => _setState(() => widget.element.bold = !widget.element.bold)),
        const SizedBox(width: 6),
        _stylePill(Icons.format_italic_rounded, widget.element.italic,
            () => _setState(() => widget.element.italic = !widget.element.italic)),
        const SizedBox(width: 6),
        _stylePill(
            Icons.format_underline_rounded,
            widget.element.underline,
            () => _setState(
                () => widget.element.underline = !widget.element.underline)),
      ],
    );
  }

  Widget _stylePill(IconData icon, bool active, VoidCallback onTap) {
    final isDark = widget.isDark;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 30,
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: active
                ? accent
                : (isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active
              ? accent
              : (isDark
                  ? AppColors.darkText
                  : AppColors.lightText),
        ),
      ),
    );
  }

  Widget _alignmentRow() {
    const aligns = ['left', 'center', 'right', 'justify'];
    const icons = [
      Icons.format_align_left_rounded,
      Icons.format_align_center_rounded,
      Icons.format_align_right_rounded,
      Icons.format_align_justify_rounded,
    ];
    return Row(
      children: [
        for (var i = 0; i < aligns.length; i++) ...[
          _stylePill(
              icons[i],
              widget.element.align == aligns[i],
              () =>
                  _setState(() => widget.element.align = aligns[i])),
          if (i < aligns.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _lineHeightRow() => _sliderRow(
        label: 'Line height',
        value: widget.element.lineHeight,
        min: 1,
        max: 2.4,
        onChanged: (v) => _setState(() => widget.element.lineHeight = v),
        precision: 2,
      );

  // ─── color row ────────────────────────────────────────────────────────────
  Widget _colorRow(String label, String? hex, ValueChanged<String?> set) {
    final isDark = widget.isDark;
    final color = hexToColor(
      hex,
      isDark ? Colors.transparent : Colors.transparent,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          if (hex != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 14),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 22, minHeight: 22),
              onPressed: () => set(null),
            ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () async {
              final picked = await _showColorPicker(context, color);
              if (picked != null) set(designColorToHex(picked));
            },
            child: Container(
              width: 36,
              height: 26,
              decoration: BoxDecoration(
                color: hex == null ? null : color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
                gradient: hex == null
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFEBEFFA), Color(0xFFCDD3E8)],
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: hex == null
                  ? Icon(Icons.block_rounded,
                      size: 12,
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<Color?> _showColorPicker(BuildContext context, Color current) async {
    Color picked = current;
    return showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: current,
            onColorChanged: (c) => picked = c,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(picked),
              child: const Text('Apply')),
        ],
      ),
    );
  }

  // ─── kind-specific ───────────────────────────────────────────────────────
  List<Widget> _kindSpecific() {
    final el = widget.element;
    switch (el.kind) {
      case ElementKind.image:
        return [
          const SizedBox(height: 18),
          _section('Image'),
          _textField('URL',
              (el.data['url'] as String?) ?? '',
              (v) => _setState(() => el.data['url'] = v)),
          const SizedBox(height: 6),
          _dropdownField('Fit', (el.data['fit'] as String?) ?? 'cover',
              const ['cover', 'contain', 'fill'],
              (v) => _setState(() => el.data['fit'] = v)),
        ];
      case ElementKind.divider:
        return [
          const SizedBox(height: 18),
          _section('Divider'),
          _dropdownField('Style', (el.data['style'] as String?) ?? 'solid',
              const ['solid', 'dashed', 'dotted'],
              (v) => _setState(() => el.data['style'] = v)),
        ];
      case ElementKind.callout:
        return [
          const SizedBox(height: 18),
          _section('Callout'),
          _textField('Emoji', (el.data['emoji'] as String?) ?? '💡',
              (v) => _setState(() => el.data['emoji'] = v)),
        ];
      case ElementKind.signature:
        return [
          const SizedBox(height: 18),
          _section('Signature'),
          _textField('Name',
              (el.data['name'] as String?) ?? '',
              (v) => _setState(() => el.data['name'] = v)),
          const SizedBox(height: 6),
          _textField('Caption',
              (el.data['caption'] as String?) ?? '',
              (v) => _setState(() => el.data['caption'] = v)),
        ];
      case ElementKind.table:
        return [
          const SizedBox(height: 18),
          _section('Table'),
          _tableEditor(),
        ];
      case ElementKind.barChart:
      case ElementKind.lineChart:
      case ElementKind.pieChart:
        return [
          const SizedBox(height: 18),
          _section('Chart data'),
          _chartEditor(),
        ];
      case ElementKind.kpi:
        return [
          const SizedBox(height: 18),
          _section('KPI'),
          _textField('Label',
              (el.data['label'] as String?) ?? '',
              (v) => _setState(() => el.data['label'] = v)),
          const SizedBox(height: 6),
          _textField('Value',
              (el.data['value'] as String?) ?? '',
              (v) => _setState(() => el.data['value'] = v)),
          const SizedBox(height: 6),
          _textField('Delta',
              (el.data['delta'] as String?) ?? '',
              (v) => _setState(() => el.data['delta'] = v)),
        ];
      case ElementKind.attachment:
        return [
          const SizedBox(height: 18),
          _section('Attachment'),
          _textField('Name',
              (el.data['name'] as String?) ?? '',
              (v) => _setState(() => el.data['name'] = v)),
          const SizedBox(height: 6),
          _textField('Caption',
              (el.data['caption'] as String?) ?? '',
              (v) => _setState(() => el.data['caption'] = v)),
        ];
      case ElementKind.qrCode:
        return [
          const SizedBox(height: 18),
          _section('QR code'),
          _textField('Value',
              (el.data['value'] as String?) ?? '',
              (v) => _setState(() => el.data['value'] = v)),
        ];
      case ElementKind.columns:
        return [
          const SizedBox(height: 18),
          _section('Columns'),
          _sliderRow(
            label: 'Count',
            value: ((el.data['count'] as int?) ?? 2).toDouble(),
            min: 1,
            max: 4,
            onChanged: (v) => _setState(() {
              final c = v.round();
              el.data['count'] = c;
              final texts =
                  (el.data['texts'] as List?)?.cast<String>() ?? <String>[];
              while (texts.length < c) {
                texts.add('');
              }
              el.data['texts'] = texts;
            }),
            precision: 0,
          ),
        ];
      case ElementKind.wordArt:
        return [
          const SizedBox(height: 18),
          _section('Word art'),
          _colorRow(
              'Gradient start',
              (el.data['gradStart'] as String?),
              (h) => _setState(() => el.data['gradStart'] = h)),
          _colorRow(
              'Gradient end',
              (el.data['gradEnd'] as String?),
              (h) => _setState(() => el.data['gradEnd'] = h)),
        ];
      default:
        return [];
    }
  }

  Widget _tableEditor() {
    final el = widget.element;
    final rows = ((el.data['rows'] as List?) ?? [])
        .whereType<List>()
        .map<List<String>>(
            (r) => r.map((c) => c?.toString() ?? '').toList())
        .toList();
    final rowCount = rows.length.clamp(1, 50);
    final colCount = rows.isEmpty ? 3 : rows.first.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _miniSquareBtn(
                  Icons.add_rounded, 'Add row',
                  () => _setState(() {
                    final next = rows
                        .map((r) => [...r])
                        .toList();
                    next.add(List.filled(colCount, ''));
                    el.data['rows'] = next;
                  })),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _miniSquareBtn(
                  Icons.remove_rounded, 'Remove row',
                  () => _setState(() {
                    if (rowCount <= 1) return;
                    el.data['rows'] = rows.sublist(0, rows.length - 1);
                  })),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _miniSquareBtn(
                  Icons.swap_horiz_rounded, 'Add column',
                  () => _setState(() {
                    el.data['rows'] = rows
                        .map((r) => [...r, ''])
                        .toList();
                  })),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _miniSquareBtn(
                  Icons.swap_horiz_outlined, 'Remove column',
                  () => _setState(() {
                    if (colCount <= 1) return;
                    el.data['rows'] = rows
                        .map((r) => r.sublist(0, r.length - 1))
                        .toList();
                  })),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Switch.adaptive(
              value: (el.data['stripe'] as bool?) ?? true,
              onChanged: (v) => _setState(() => el.data['stripe'] = v),
            ),
            const SizedBox(width: 8),
            Text('Striped rows',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                )),
          ],
        ),
      ],
    );
  }

  Widget _chartEditor() {
    final el = widget.element;
    final values =
        ((el.data['values'] as List?) ?? const <double>[12, 28, 19, 34, 22])
            .map((e) => (e as num?)?.toDouble() ?? 0)
            .toList();
    final labels =
        ((el.data['labels'] as List?) ?? const <String>[])
            .map((e) => e?.toString() ?? '')
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _textField('Title', el.text, (v) => _setState(() => el.text = v)),
        const SizedBox(height: 8),
        _textField(
            'Values (comma-separated)',
            values.map((v) => v.toStringAsFixed(0)).join(', '),
            (v) {
              final parsed = v
                  .split(',')
                  .map((s) => double.tryParse(s.trim()) ?? 0.0)
                  .toList();
              _setState(() => el.data['values'] = parsed);
            }),
        const SizedBox(height: 8),
        _textField('Labels (comma-separated)', labels.join(', '), (v) {
          final parsed =
              v.split(',').map((s) => s.trim()).toList();
          _setState(() => el.data['labels'] = parsed);
        }),
      ],
    );
  }

  Widget _miniSquareBtn(IconData icon, String tooltip, VoidCallback onTap) {
    final isDark = widget.isDark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 14),
        ),
      ),
    );
  }

  // ─── number field with stepper-like behavior ─────────────────────────────
  Widget _numField(
      String label, double value, ValueChanged<double> onChanged) {
    final isDark = widget.isDark;
    return _LabeledField(
      label: label,
      isDark: isDark,
      child: TextFormField(
        key: ValueKey('${widget.element.id}_$label'),
        initialValue: value.toStringAsFixed(0),
        keyboardType:
            const TextInputType.numberWithOptions(signed: true, decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.\-]')),
        ],
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onFieldSubmitted: (v) {
          final parsed = double.tryParse(v);
          if (parsed != null) onChanged(parsed);
        },
        onChanged: (v) {
          final parsed = double.tryParse(v);
          if (parsed != null) onChanged(parsed);
        },
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    String? unit,
    int precision = 0,
  }) {
    final isDark = widget.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              Text(
                '${value.toStringAsFixed(precision)}${unit ?? ''}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark
                      ? AppColors.darkText
                      : AppColors.lightText,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 12),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField(
      String label, String value, ValueChanged<String> onChanged) {
    final isDark = widget.isDark;
    return _LabeledField(
      label: label,
      isDark: isDark,
      child: TextFormField(
        key: ValueKey('${widget.element.id}_${label}_t'),
        initialValue: value,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdownField(String label, String value, List<String> options,
      ValueChanged<String> onChanged) {
    final isDark = widget.isDark;
    return _LabeledField(
      label: label,
      isDark: isDark,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final bool isDark;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
