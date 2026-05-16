import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import 'models.dart';

class ElementRenderer extends StatelessWidget {
  final DesignElement element;
  final double zoom;
  final bool isDark;
  final bool selected;
  final void Function(DesignElement) onChanged;
  final VoidCallback onActivate;

  const ElementRenderer({
    super.key,
    required this.element,
    required this.zoom,
    required this.isDark,
    required this.selected,
    required this.onChanged,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    switch (element.kind) {
      case ElementKind.text:
      case ElementKind.heading1:
      case ElementKind.heading2:
      case ElementKind.heading3:
        return _TextElement(
          el: element,
          zoom: zoom,
          isDark: isDark,
          onChanged: onChanged,
        );
      case ElementKind.quote:
        return _QuoteElement(el: element, zoom: zoom, isDark: isDark, onChanged: onChanged);
      case ElementKind.callout:
        return _CalloutElement(el: element, zoom: zoom, isDark: isDark, onChanged: onChanged);
      case ElementKind.code:
        return _CodeElement(el: element, zoom: zoom, isDark: isDark, onChanged: onChanged);
      case ElementKind.bulletList:
      case ElementKind.numberedList:
        return _ListElement(el: element, zoom: zoom, isDark: isDark, onChanged: onChanged);
      case ElementKind.wordArt:
        return _WordArtElement(el: element, zoom: zoom, isDark: isDark, onChanged: onChanged);
      case ElementKind.image:
        return _ImageElement(el: element, zoom: zoom, isDark: isDark);
      case ElementKind.divider:
        return _DividerElement(el: element, zoom: zoom, isDark: isDark);
      case ElementKind.shapeRect:
      case ElementKind.shapeOval:
        return _ShapeElement(el: element, zoom: zoom, isDark: isDark);
      case ElementKind.signature:
        return _SignatureElement(el: element, zoom: zoom, isDark: isDark, onChanged: onChanged);
      case ElementKind.table:
        return _TableElement(el: element, zoom: zoom, isDark: isDark, onChanged: onChanged);
      case ElementKind.barChart:
        return _BarChartElement(el: element, zoom: zoom, isDark: isDark);
      case ElementKind.lineChart:
        return _LineChartElement(el: element, zoom: zoom, isDark: isDark);
      case ElementKind.pieChart:
        return _PieChartElement(el: element, zoom: zoom, isDark: isDark);
      case ElementKind.kpi:
        return _KpiElement(el: element, zoom: zoom, isDark: isDark);
      case ElementKind.attachment:
        return _AttachmentElement(el: element, zoom: zoom, isDark: isDark);
      case ElementKind.columns:
        return _ColumnsElement(el: element, zoom: zoom, isDark: isDark, onChanged: onChanged);
      case ElementKind.qrCode:
        return _QrElement(el: element, zoom: zoom, isDark: isDark);
    }
  }
}

// ─── helpers ───────────────────────────────────────────────────────────────
TextStyle _styleFor(DesignElement el, bool isDark, double zoom,
    {double? overrideSize, FontWeight? overrideWeight, Color? overrideColor}) {
  double size = overrideSize ?? el.fontSize;
  switch (el.kind) {
    case ElementKind.heading1:
      size = overrideSize ?? math.max(el.fontSize, 30);
      break;
    case ElementKind.heading2:
      size = overrideSize ?? math.max(el.fontSize, 24);
      break;
    case ElementKind.heading3:
      size = overrideSize ?? math.max(el.fontSize, 19);
      break;
    default:
      break;
  }
  final isHeading = el.kind == ElementKind.heading1 ||
      el.kind == ElementKind.heading2 ||
      el.kind == ElementKind.heading3;
  final color = overrideColor ??
      hexToColor(
        el.colorHex,
        isDark ? AppColors.darkText : AppColors.lightText,
      );
  final weight = overrideWeight ??
      (el.bold || isHeading ? FontWeight.w700 : FontWeight.w400);
  TextStyle base;
  try {
    base = GoogleFonts.getFont(
      el.fontFamily,
      fontSize: size * zoom,
      fontWeight: weight,
      fontStyle: el.italic ? FontStyle.italic : FontStyle.normal,
      color: color,
      decoration:
          el.underline ? TextDecoration.underline : TextDecoration.none,
      height: el.lineHeight,
    );
  } catch (_) {
    base = TextStyle(
      fontSize: size * zoom,
      fontWeight: weight,
      fontStyle: el.italic ? FontStyle.italic : FontStyle.normal,
      color: color,
      decoration:
          el.underline ? TextDecoration.underline : TextDecoration.none,
      height: el.lineHeight,
    );
  }
  return base;
}

TextAlign _alignFor(DesignElement el) {
  switch (el.align) {
    case 'center':
      return TextAlign.center;
    case 'right':
      return TextAlign.right;
    case 'justify':
      return TextAlign.justify;
    default:
      return TextAlign.left;
  }
}

// ─── text element ─────────────────────────────────────────────────────────
class _TextElement extends StatefulWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;
  final void Function(DesignElement) onChanged;

  const _TextElement(
      {required this.el,
      required this.zoom,
      required this.isDark,
      required this.onChanged});

  @override
  State<_TextElement> createState() => _TextElementState();
}

class _TextElementState extends State<_TextElement> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.el.text);
    _ctrl.addListener(() {
      widget.el.text = _ctrl.text;
    });
  }

  @override
  void didUpdateWidget(covariant _TextElement old) {
    super.didUpdateWidget(old);
    if (_ctrl.text != widget.el.text) {
      _ctrl.value = TextEditingValue(
        text: widget.el.text,
        selection: _ctrl.selection,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final el = widget.el;
    final hint = el.kind.label;
    return Container(
      color: hexToColor(el.bgHex, Colors.transparent),
      padding: EdgeInsets.all(8 * widget.zoom),
      child: TextField(
        controller: _ctrl,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: _styleFor(el, widget.isDark, widget.zoom),
        textAlign: _alignFor(el),
        cursorColor:
            widget.isDark ? AppColors.primaryLight : AppColors.primary,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: hint,
          hintStyle: _styleFor(el, widget.isDark, widget.zoom,
              overrideColor: (widget.isDark
                      ? AppColors.darkTextHint
                      : AppColors.lightTextHint)
                  .withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}

// ─── quote ────────────────────────────────────────────────────────────────
class _QuoteElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;
  final void Function(DesignElement) onChanged;

  const _QuoteElement(
      {required this.el,
      required this.zoom,
      required this.isDark,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(
            left: BorderSide(color: accent, width: 4 * zoom)),
      ),
      padding: EdgeInsets.fromLTRB(
          16 * zoom, 12 * zoom, 12 * zoom, 12 * zoom),
      child: _InlineEditor(
        el: el,
        zoom: zoom,
        isDark: isDark,
        onChanged: onChanged,
        styleOverride: _styleFor(el, isDark, zoom,
            overrideSize: el.fontSize > 0 ? el.fontSize : 15)
            .copyWith(fontStyle: FontStyle.italic),
        hint: 'Quote text…',
      ),
    );
  }
}

// ─── callout ──────────────────────────────────────────────────────────────
class _CalloutElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;
  final void Function(DesignElement) onChanged;

  const _CalloutElement(
      {required this.el,
      required this.zoom,
      required this.isDark,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final emoji = (el.data['emoji'] as String?) ?? '💡';
    final color = hexToColor(el.bgHex, const Color(0xFFFFF7E0));
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : const Color(0xFFEED48A),
        ),
      ),
      padding: EdgeInsets.all(12 * zoom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 22 * zoom)),
          SizedBox(width: 10 * zoom),
          Expanded(
            child: _InlineEditor(
              el: el,
              zoom: zoom,
              isDark: isDark,
              onChanged: onChanged,
              hint: 'Callout…',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── code ─────────────────────────────────────────────────────────────────
class _CodeElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;
  final void Function(DesignElement) onChanged;

  const _CodeElement(
      {required this.el,
      required this.zoom,
      required this.isDark,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0B1224) : const Color(0xFFF6F8FB);
    final fg = isDark ? const Color(0xFFCDE3FF) : const Color(0xFF1F2A44);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: EdgeInsets.all(12 * zoom),
      child: _InlineEditor(
        el: el,
        zoom: zoom,
        isDark: isDark,
        onChanged: onChanged,
        styleOverride: TextStyle(
          fontFamily: 'monospace',
          fontSize: (el.fontSize > 0 ? el.fontSize : 13) * zoom,
          color: fg,
          height: 1.5,
        ),
        hint: '// code',
      ),
    );
  }
}

// ─── list (bullet / numbered) ─────────────────────────────────────────────
class _ListElement extends StatefulWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;
  final void Function(DesignElement) onChanged;

  const _ListElement(
      {required this.el,
      required this.zoom,
      required this.isDark,
      required this.onChanged});

  @override
  State<_ListElement> createState() => _ListElementState();
}

class _ListElementState extends State<_ListElement> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final initial = widget.el.text.isEmpty
        ? (widget.el.kind == ElementKind.bulletList
            ? 'First item\nSecond item\nThird item'
            : 'First item\nSecond item\nThird item')
        : widget.el.text;
    _ctrl = TextEditingController(text: initial);
    _ctrl.addListener(() {
      widget.el.text = _ctrl.text;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final el = widget.el;
    final isNumbered = el.kind == ElementKind.numberedList;
    final lines = _ctrl.text.split('\n');
    return Container(
      padding: EdgeInsets.all(8 * widget.zoom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4 * widget.zoom, right: 8 * widget.zoom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < lines.length; i++)
                  SizedBox(
                    height: (el.fontSize > 0 ? el.fontSize : 14) *
                        widget.zoom *
                        el.lineHeight,
                    child: Text(
                      isNumbered ? '${i + 1}.' : '•',
                      style: _styleFor(el, widget.isDark, widget.zoom),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: _styleFor(el, widget.isDark, widget.zoom),
              textAlign: _alignFor(el),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── word art ─────────────────────────────────────────────────────────────
class _WordArtElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;
  final void Function(DesignElement) onChanged;

  const _WordArtElement(
      {required this.el,
      required this.zoom,
      required this.isDark,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final text = el.text.isEmpty ? 'Word Art' : el.text;
    final colorA = hexToColor(
        el.data['gradStart'] as String?, AppColors.primary);
    final colorB =
        hexToColor(el.data['gradEnd'] as String?, AppColors.accent);
    return Container(
      alignment: Alignment.center,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => LinearGradient(
          colors: [colorA, colorB],
        ).createShader(rect),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: _styleFor(el, isDark, zoom,
                overrideSize: math.max(el.fontSize, 38),
                overrideWeight: FontWeight.w900,
                overrideColor: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ─── image ────────────────────────────────────────────────────────────────
class _ImageElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;

  const _ImageElement(
      {required this.el, required this.zoom, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final url = (el.data['url'] as String?) ?? '';
    final fit = (el.data['fit'] as String?) ?? 'cover';
    final boxFit = switch (fit) {
      'contain' => BoxFit.contain,
      'fill' => BoxFit.fill,
      _ => BoxFit.cover,
    };
    final borderColor = hexToColor(
        el.borderHex, isDark ? AppColors.darkBorder : AppColors.lightBorder);

    Widget child;
    if (url.isEmpty) {
      child = _ImagePlaceholder(isDark: isDark);
    } else if (url.startsWith('http')) {
      child = CachedNetworkImage(
        imageUrl: url,
        fit: boxFit,
        placeholder: (_, __) => _ImagePlaceholder(isDark: isDark, loading: true),
        errorWidget: (_, __, ___) => _ImagePlaceholder(isDark: isDark, error: true),
      );
    } else {
      child = _ImagePlaceholder(isDark: isDark);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(el.borderRadius),
        border: el.borderWidth > 0
            ? Border.all(color: borderColor, width: el.borderWidth)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final bool isDark;
  final bool loading;
  final bool error;
  const _ImagePlaceholder(
      {required this.isDark, this.loading = false, this.error = false});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.darkSurface : const Color(0xFFF1F4FB);
    return Container(
      color: color,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error
                  ? Icons.broken_image_outlined
                  : (loading
                      ? Icons.hourglass_top_rounded
                      : Icons.image_outlined),
              size: 32,
              color: isDark
                  ? AppColors.darkTextHint
                  : AppColors.lightTextHint,
            ),
            const SizedBox(height: 6),
            Text(
              error
                  ? 'Failed to load'
                  : (loading ? 'Loading…' : 'Image — set URL'),
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextHint
                    : AppColors.lightTextHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── divider ──────────────────────────────────────────────────────────────
class _DividerElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;

  const _DividerElement(
      {required this.el, required this.zoom, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(
        el.colorHex, isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final style = (el.data['style'] as String?) ?? 'solid';
    return Center(
      child: SizedBox(
        height: math.max(2, el.borderWidth) * zoom,
        child: CustomPaint(
          painter: _DividerPainter(color: color, style: style),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DividerPainter extends CustomPainter {
  final Color color;
  final String style;
  _DividerPainter({required this.color, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (style == 'dashed') {
      const dash = 8.0;
      const gap = 6.0;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
        x += dash + gap;
      }
    } else if (style == 'dotted') {
      double x = 0;
      while (x < size.width) {
        canvas.drawCircle(Offset(x, y), size.height / 2, paint);
        x += size.height * 2.5;
      }
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DividerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.style != style;
}

// ─── shape ────────────────────────────────────────────────────────────────
class _ShapeElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;

  const _ShapeElement(
      {required this.el, required this.zoom, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = hexToColor(el.bgHex, AppColors.primary.withValues(alpha: 0.18));
    final border = hexToColor(
        el.borderHex, isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final isOval = el.kind == ElementKind.shapeOval;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        shape: isOval ? BoxShape.circle : BoxShape.rectangle,
        borderRadius:
            isOval ? null : BorderRadius.circular(el.borderRadius),
        border: el.borderWidth > 0
            ? Border.all(color: border, width: el.borderWidth)
            : null,
      ),
    );
  }
}

// ─── signature ────────────────────────────────────────────────────────────
class _SignatureElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;
  final void Function(DesignElement) onChanged;

  const _SignatureElement(
      {required this.el,
      required this.zoom,
      required this.isDark,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final name = (el.data['name'] as String?) ?? el.text;
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkTextSecondary : Colors.black54,
            width: 1.4,
          ),
        ),
      ),
      padding: EdgeInsets.all(8 * zoom),
      alignment: Alignment.bottomLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? 'Signature' : name,
            style: GoogleFonts.dancingScript(
              fontSize: 26 * zoom,
              color: isDark
                  ? AppColors.darkText
                  : AppColors.lightText,
            ),
          ),
          SizedBox(height: 2 * zoom),
          Text(
            (el.data['caption'] as String?) ?? 'Signed',
            style: TextStyle(
              fontSize: 10 * zoom,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── table ────────────────────────────────────────────────────────────────
class _TableElement extends StatefulWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;
  final void Function(DesignElement) onChanged;

  const _TableElement(
      {required this.el,
      required this.zoom,
      required this.isDark,
      required this.onChanged});

  @override
  State<_TableElement> createState() => _TableElementState();
}

class _TableElementState extends State<_TableElement> {
  List<List<String>> get _rows {
    final raw = widget.el.data['rows'];
    if (raw is List) {
      return raw
          .whereType<List>()
          .map((r) => r.map((c) => c?.toString() ?? '').toList())
          .toList();
    }
    return _defaultRows();
  }

  List<List<String>> _defaultRows() => [
        ['Name', 'Quantity', 'Price'],
        ['Item A', '2', '10.00'],
        ['Item B', '1', '24.50'],
        ['Item C', '5', '6.20'],
      ];

  void _save(List<List<String>> rows) {
    widget.el.data['rows'] = rows;
    widget.onChanged(widget.el);
  }

  @override
  Widget build(BuildContext context) {
    var rows = _rows;
    if (rows.isEmpty) rows = _defaultRows();
    final cols = rows.first.length;
    final headerBg = hexToColor(widget.el.bgHex,
        AppColors.primary.withValues(alpha: widget.isDark ? 0.18 : 0.10));
    final border = hexToColor(
        widget.el.borderHex,
        widget.isDark
            ? AppColors.darkBorder
            : AppColors.lightBorder);
    final stripe = (widget.el.data['stripe'] as bool?) ?? true;
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++)
            Expanded(
              child: Container(
                color: r == 0
                    ? headerBg
                    : (stripe && r.isOdd
                        ? (widget.isDark
                            ? Colors.white.withValues(alpha: 0.025)
                            : const Color(0xFFF8FAFF))
                        : Colors.transparent),
                child: Row(
                  children: [
                    for (var c = 0; c < cols; c++) ...[
                      if (c > 0)
                        Container(
                          width: 1,
                          color: border.withValues(alpha: 0.4),
                        ),
                      Expanded(
                        child: _TableCell(
                          text: c < rows[r].length ? rows[r][c] : '',
                          isHeader: r == 0,
                          isDark: widget.isDark,
                          zoom: widget.zoom,
                          fontSize: widget.el.fontSize,
                          fontFamily: widget.el.fontFamily,
                          onChanged: (v) {
                            final next = rows
                                .map((row) => [...row])
                                .toList();
                            while (next[r].length <= c) {
                              next[r].add('');
                            }
                            next[r][c] = v;
                            _save(next);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TableCell extends StatefulWidget {
  final String text;
  final bool isHeader;
  final bool isDark;
  final double zoom;
  final double fontSize;
  final String fontFamily;
  final ValueChanged<String> onChanged;

  const _TableCell({
    required this.text,
    required this.isHeader,
    required this.isDark,
    required this.zoom,
    required this.fontSize,
    required this.fontFamily,
    required this.onChanged,
  });

  @override
  State<_TableCell> createState() => _TableCellState();
}

class _TableCellState extends State<_TableCell> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(covariant _TableCell old) {
    super.didUpdateWidget(old);
    if (widget.text != _ctrl.text) _ctrl.text = widget.text;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.fontSize > 0 ? widget.fontSize : 13;
    final color = widget.isDark
        ? AppColors.darkText
        : AppColors.lightText;
    TextStyle style;
    try {
      style = GoogleFonts.getFont(
        widget.fontFamily,
        fontSize: base * widget.zoom,
        fontWeight: widget.isHeader ? FontWeight.w700 : FontWeight.w400,
        color: color,
      );
    } catch (_) {
      style = TextStyle(
        fontSize: base * widget.zoom,
        fontWeight: widget.isHeader ? FontWeight.w700 : FontWeight.w400,
        color: color,
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10 * widget.zoom, vertical: 6 * widget.zoom),
      child: TextField(
        controller: _ctrl,
        style: style,
        maxLines: 1,
        onChanged: widget.onChanged,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ─── bar chart ────────────────────────────────────────────────────────────
List<double> _chartValues(DesignElement el) {
  final raw = el.data['values'];
  if (raw is List && raw.isNotEmpty) {
    return raw
        .map((e) => (e as num?)?.toDouble() ?? 0.0)
        .toList();
  }
  return const [12, 28, 19, 34, 22, 41, 30];
}

List<String> _chartLabels(DesignElement el, int count) {
  final raw = el.data['labels'];
  if (raw is List && raw.isNotEmpty) {
    return raw.map((e) => e?.toString() ?? '').toList();
  }
  return List.generate(count, (i) => 'L${i + 1}');
}

class _BarChartElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;

  const _BarChartElement(
      {required this.el, required this.zoom, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final values = _chartValues(el);
    final labels = _chartLabels(el, values.length);
    final maxV = values.isEmpty
        ? 1.0
        : values.reduce(math.max) * 1.2;
    final accent = hexToColor(el.colorHex, AppColors.primary);
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: EdgeInsets.all(12 * zoom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (el.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 6 * zoom),
              child: Text(
                el.text,
                style: TextStyle(
                  fontSize: 13 * zoom,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxV,
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.06),
                          strokeWidth: 1,
                        )),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style:
                            TextStyle(fontSize: 9 * zoom, color: textColor),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 9 * zoom,
                              color: textColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          width: 12 * zoom,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accent,
                              accent.withValues(alpha: 0.55),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── line chart ───────────────────────────────────────────────────────────
class _LineChartElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;

  const _LineChartElement(
      {required this.el, required this.zoom, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final values = _chartValues(el);
    final maxV = values.isEmpty
        ? 1.0
        : values.reduce(math.max) * 1.2;
    final accent = hexToColor(el.colorHex, AppColors.primary);
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: EdgeInsets.all(12 * zoom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (el.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 6 * zoom),
              child: Text(
                el.text,
                style: TextStyle(
                  fontSize: 13 * zoom,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxV,
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.06),
                          strokeWidth: 1,
                        )),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style:
                            TextStyle(fontSize: 9 * zoom, color: textColor),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    curveSmoothness: 0.32,
                    spots: [
                      for (var i = 0; i < values.length; i++)
                        FlSpot(i.toDouble(), values[i]),
                    ],
                    color: accent,
                    barWidth: 2.5 * zoom,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                        radius: 3 * zoom,
                        color: Colors.white,
                        strokeColor: accent,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.30),
                          accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── pie chart ────────────────────────────────────────────────────────────
class _PieChartElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;

  const _PieChartElement(
      {required this.el, required this.zoom, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final values = _chartValues(el);
    final labels = _chartLabels(el, values.length);
    final palette = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      AppColors.error,
      AppColors.primaryLight,
    ];
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: EdgeInsets.all(12 * zoom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (el.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 6 * zoom),
              child: Text(
                el.text,
                style: TextStyle(
                  fontSize: 13 * zoom,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 28 * zoom,
                      sections: [
                        for (var i = 0; i < values.length; i++)
                          PieChartSectionData(
                            value: values[i],
                            color: palette[i % palette.length],
                            title: '',
                            radius: 46 * zoom,
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8 * zoom),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < values.length && i < labels.length; i++)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2 * zoom),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10 * zoom,
                                height: 10 * zoom,
                                decoration: BoxDecoration(
                                  color: palette[i % palette.length],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              SizedBox(width: 6 * zoom),
                              Flexible(
                                child: Text(
                                  labels[i],
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10 * zoom,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KPI card ─────────────────────────────────────────────────────────────
class _KpiElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;

  const _KpiElement(
      {required this.el, required this.zoom, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(el.colorHex, AppColors.primary);
    final value = (el.data['value'] as String?) ?? '128';
    final label = (el.data['label'] as String?) ??
        (el.text.isEmpty ? 'Total' : el.text);
    final delta = (el.data['delta'] as String?) ?? '+12.4%';
    final positive = !delta.startsWith('-');
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? accent.withValues(alpha: 0.14)
            : accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.30),
        ),
      ),
      padding: EdgeInsets.all(12 * zoom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11 * zoom,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 4 * zoom),
          Text(
            value,
            style: TextStyle(
              fontSize: 28 * zoom,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : AppColors.lightText,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4 * zoom),
          Row(
            children: [
              Icon(
                positive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 14 * zoom,
                color: positive ? AppColors.success : AppColors.error,
              ),
              SizedBox(width: 4 * zoom),
              Text(
                delta,
                style: TextStyle(
                  fontSize: 11 * zoom,
                  fontWeight: FontWeight.w700,
                  color: positive ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── attachment ───────────────────────────────────────────────────────────
class _AttachmentElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;

  const _AttachmentElement(
      {required this.el, required this.zoom, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name =
        (el.data['name'] as String?) ?? (el.text.isEmpty ? 'document.pdf' : el.text);
    final ext = name.split('.').last.toLowerCase();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: 10 * zoom, vertical: 8 * zoom),
      child: Row(
        children: [
          Container(
            width: 36 * zoom,
            height: 44 * zoom,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              ext.toUpperCase().substring(0, math.min(3, ext.length)),
              style: TextStyle(
                fontSize: 10 * zoom,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 10 * zoom),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13 * zoom,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                SizedBox(height: 2 * zoom),
                Text(
                  (el.data['caption'] as String?) ?? 'Attached file',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10 * zoom,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.download_rounded,
            size: 18 * zoom,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ],
      ),
    );
  }
}

// ─── columns ──────────────────────────────────────────────────────────────
class _ColumnsElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;
  final void Function(DesignElement) onChanged;

  const _ColumnsElement(
      {required this.el,
      required this.zoom,
      required this.isDark,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final count = (el.data['count'] as int?) ?? 2;
    final texts = (el.data['texts'] as List?)?.cast<String>() ??
        List.generate(count, (i) => '');
    final border = hexToColor(
        el.borderHex,
        isDark
            ? AppColors.darkBorder.withValues(alpha: 0.5)
            : AppColors.lightBorder);
    return Container(
      padding: EdgeInsets.all(6 * zoom),
      decoration: BoxDecoration(
        color: hexToColor(el.bgHex, Colors.transparent),
        borderRadius: BorderRadius.circular(el.borderRadius),
        border: el.borderWidth > 0
            ? Border.all(color: border, width: el.borderWidth)
            : null,
      ),
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(width: 8 * zoom),
            Expanded(
              child: _ColumnEditor(
                text: i < texts.length ? texts[i] : '',
                isDark: isDark,
                zoom: zoom,
                fontSize: el.fontSize,
                fontFamily: el.fontFamily,
                onChanged: (v) {
                  final next = [...texts];
                  while (next.length < count) {
                    next.add('');
                  }
                  next[i] = v;
                  el.data['texts'] = next;
                  el.data['count'] = count;
                  onChanged(el);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ColumnEditor extends StatefulWidget {
  final String text;
  final bool isDark;
  final double zoom;
  final double fontSize;
  final String fontFamily;
  final ValueChanged<String> onChanged;

  const _ColumnEditor({
    required this.text,
    required this.isDark,
    required this.zoom,
    required this.fontSize,
    required this.fontFamily,
    required this.onChanged,
  });

  @override
  State<_ColumnEditor> createState() => _ColumnEditorState();
}

class _ColumnEditorState extends State<_ColumnEditor> {
  late TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.text);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.fontSize > 0 ? widget.fontSize : 13;
    TextStyle style;
    try {
      style = GoogleFonts.getFont(
        widget.fontFamily,
        fontSize: size * widget.zoom,
        color: widget.isDark
            ? AppColors.darkText
            : AppColors.lightText,
        height: 1.5,
      );
    } catch (_) {
      style = TextStyle(
        fontSize: size * widget.zoom,
        color: widget.isDark
            ? AppColors.darkText
            : AppColors.lightText,
        height: 1.5,
      );
    }
    return Container(
      padding: EdgeInsets.all(10 * widget.zoom),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.02)
            : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        controller: _c,
        maxLines: null,
        expands: true,
        style: style,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'Column…',
          hintStyle: style.copyWith(
            color: widget.isDark
                ? AppColors.darkTextHint
                : AppColors.lightTextHint,
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ─── QR code (visual placeholder) ─────────────────────────────────────────
class _QrElement extends StatelessWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;

  const _QrElement(
      {required this.el, required this.zoom, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final value = (el.data['value'] as String?) ?? 'https://example.com';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      padding: EdgeInsets.all(8 * zoom),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _QrLikePainter(seed: value.hashCode),
              size: Size.infinite,
            ),
          ),
          SizedBox(height: 4 * zoom),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9 * zoom,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrLikePainter extends CustomPainter {
  final int seed;
  _QrLikePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    const cells = 21;
    final cell = size.shortestSide / cells;
    final rand = math.Random(seed);
    final paint = Paint()..color = Colors.black;
    for (var i = 0; i < cells; i++) {
      for (var j = 0; j < cells; j++) {
        final isFinder = (i < 7 && j < 7) ||
            (i < 7 && j >= cells - 7) ||
            (i >= cells - 7 && j < 7);
        final draw = isFinder
            ? _finderCell(i, j, cells)
            : rand.nextDouble() > 0.55;
        if (draw) {
          canvas.drawRect(
            Rect.fromLTWH(i * cell, j * cell, cell, cell),
            paint,
          );
        }
      }
    }
  }

  bool _finderCell(int i, int j, int total) {
    int ri = i, rj = j;
    if (i >= total - 7) ri = i - (total - 7);
    if (j >= total - 7) rj = j - (total - 7);
    final onBorder = ri == 0 || ri == 6 || rj == 0 || rj == 6;
    final inCore = ri >= 2 && ri <= 4 && rj >= 2 && rj <= 4;
    return onBorder || inCore;
  }

  @override
  bool shouldRepaint(covariant _QrLikePainter oldDelegate) =>
      oldDelegate.seed != seed;
}

// ─── inline editor (used by quote/code/callout) ────────────────────────────
class _InlineEditor extends StatefulWidget {
  final DesignElement el;
  final double zoom;
  final bool isDark;
  final void Function(DesignElement) onChanged;
  final TextStyle? styleOverride;
  final String hint;

  const _InlineEditor({
    required this.el,
    required this.zoom,
    required this.isDark,
    required this.onChanged,
    required this.hint,
    this.styleOverride,
  });

  @override
  State<_InlineEditor> createState() => _InlineEditorState();
}

class _InlineEditorState extends State<_InlineEditor> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.el.text);
    _ctrl.addListener(() => widget.el.text = _ctrl.text);
  }

  @override
  void didUpdateWidget(covariant _InlineEditor old) {
    super.didUpdateWidget(old);
    if (_ctrl.text != widget.el.text) {
      _ctrl.value = TextEditingValue(
        text: widget.el.text,
        selection: _ctrl.selection,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: widget.styleOverride ??
          _styleFor(widget.el, widget.isDark, widget.zoom),
      textAlign: _alignFor(widget.el),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: widget.hint,
        hintStyle: (widget.styleOverride ??
                _styleFor(widget.el, widget.isDark, widget.zoom))
            .copyWith(
          color: (widget.isDark
                  ? AppColors.darkTextHint
                  : AppColors.lightTextHint)
              .withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
