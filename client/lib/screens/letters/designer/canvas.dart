import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import 'element_renderer.dart';
import 'models.dart';

class DesignerCanvas extends StatefulWidget {
  final List<DesignElement> elements;
  final String? selectedId;
  final PageSize pageSize;
  final double zoom;
  final bool showGrid;
  final bool snapToGrid;
  final double gridSize;
  final bool isDark;
  final ValueChanged<String?> onSelect;
  final void Function(DesignElement el) onChanged;
  final VoidCallback? onDeleteSelected;
  final void Function(String id) onActivate;
  final ValueChanged<double> onZoom;

  const DesignerCanvas({
    super.key,
    required this.elements,
    required this.selectedId,
    required this.pageSize,
    required this.zoom,
    required this.showGrid,
    required this.snapToGrid,
    required this.gridSize,
    required this.isDark,
    required this.onSelect,
    required this.onChanged,
    required this.onActivate,
    required this.onZoom,
    this.onDeleteSelected,
  });

  @override
  State<DesignerCanvas> createState() => _DesignerCanvasState();
}

class _DesignerCanvasState extends State<DesignerCanvas> {
  final _hController = ScrollController();
  final _vController = ScrollController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _hController.dispose();
    _vController.dispose();
    _focus.dispose();
    super.dispose();
  }

  double _snap(double v) {
    if (!widget.snapToGrid) return v;
    final g = widget.gridSize;
    return (v / g).round() * g;
  }

  @override
  Widget build(BuildContext context) {
    final pageSize = widget.pageSize.pixels;
    final scaled = pageSize * widget.zoom;
    final canvasBg = widget.isDark ? AppColors.darkBg : const Color(0xFFE7EAF5);

    return KeyboardListener(
      focusNode: _focus,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.delete ||
                event.logicalKey == LogicalKeyboardKey.backspace) &&
            widget.selectedId != null) {
          widget.onDeleteSelected?.call();
        }
      },
      child: Container(
        color: canvasBg,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _vController,
              child: SingleChildScrollView(
                controller: _hController,
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: SizedBox(
                    width: scaled.width,
                    height: scaled.height,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onSelect(null),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _PageBackground(
                            width: scaled.width,
                            height: scaled.height,
                            showGrid: widget.showGrid,
                            gridSize: widget.gridSize * widget.zoom,
                            isDark: widget.isDark,
                          ),
                          for (final el in _sorted())
                            _PositionedElement(
                              key: ValueKey(el.id),
                              element: el,
                              zoom: widget.zoom,
                              isSelected: widget.selectedId == el.id,
                              isDark: widget.isDark,
                              pageBounds: pageSize,
                              snap: _snap,
                              onSelect: () => widget.onSelect(el.id),
                              onActivate: () => widget.onActivate(el.id),
                              onChanged: widget.onChanged,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: _ZoomBadge(
                zoom: widget.zoom,
                onZoom: widget.onZoom,
                isDark: widget.isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DesignElement> _sorted() {
    final list = [...widget.elements];
    list.sort((a, b) => a.z.compareTo(b.z));
    return list;
  }
}

// ─── page background ───────────────────────────────────────────────────────
class _PageBackground extends StatelessWidget {
  final double width;
  final double height;
  final bool showGrid;
  final double gridSize;
  final bool isDark;

  const _PageBackground({
    required this.width,
    required this.height,
    required this.showGrid,
    required this.gridSize,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: showGrid
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CustomPaint(
                painter: _GridPainter(
                  gridSize: gridSize,
                  isDark: isDark,
                ),
                size: Size(width, height),
              ),
            )
          : null,
    );
  }
}

class _GridPainter extends CustomPainter {
  final double gridSize;
  final bool isDark;
  _GridPainter({required this.gridSize, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (gridSize < 4) return;
    final minor = Paint()
      ..color = (isDark ? Colors.white : Colors.black)
          .withValues(alpha: isDark ? 0.06 : 0.05)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = (isDark ? Colors.white : Colors.black)
          .withValues(alpha: isDark ? 0.10 : 0.10)
      ..strokeWidth = 1;
    const majorEvery = 5;
    int i = 0;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i % majorEvery == 0 ? major : minor,
      );
      i++;
    }
    i = 0;
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i % majorEvery == 0 ? major : minor,
      );
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.gridSize != gridSize || oldDelegate.isDark != isDark;
}

// ─── positioned element wrapper ───────────────────────────────────────────
class _PositionedElement extends StatefulWidget {
  final DesignElement element;
  final double zoom;
  final bool isSelected;
  final bool isDark;
  final Size pageBounds;
  final double Function(double) snap;
  final VoidCallback onSelect;
  final VoidCallback onActivate;
  final void Function(DesignElement) onChanged;

  const _PositionedElement({
    super.key,
    required this.element,
    required this.zoom,
    required this.isSelected,
    required this.isDark,
    required this.pageBounds,
    required this.snap,
    required this.onSelect,
    required this.onActivate,
    required this.onChanged,
  });

  @override
  State<_PositionedElement> createState() => _PositionedElementState();
}

class _PositionedElementState extends State<_PositionedElement> {
  Offset? _dragStartPointer;
  Offset? _dragStartTopLeft;
  Rect? _resizeStartRect;
  Offset? _resizeStartPointer;
  String? _resizeAnchor;

  @override
  Widget build(BuildContext context) {
    final el = widget.element;
    final z = widget.zoom;
    final accent =
        widget.isDark ? AppColors.primaryLight : AppColors.primary;

    return Positioned(
      left: el.x * z,
      top: el.y * z,
      width: el.width * z,
      height: el.height * z,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelect(),
        onDoubleTap: () => widget.onActivate(),
        onPanStart: (details) {
          widget.onSelect();
          _dragStartPointer = details.globalPosition;
          _dragStartTopLeft = Offset(el.x, el.y);
        },
        onPanUpdate: (details) {
          if (_dragStartPointer == null || _dragStartTopLeft == null) return;
          final dx = (details.globalPosition.dx - _dragStartPointer!.dx) / z;
          final dy = (details.globalPosition.dy - _dragStartPointer!.dy) / z;
          final nx = widget.snap(_dragStartTopLeft!.dx + dx);
          final ny = widget.snap(_dragStartTopLeft!.dy + dy);
          final maxX = widget.pageBounds.width - el.width;
          final maxY = widget.pageBounds.height - el.height;
          el.x = nx.clamp(0, maxX > 0 ? maxX : 0).toDouble();
          el.y = ny.clamp(0, maxY > 0 ? maxY : 0).toDouble();
          widget.onChanged(el);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: Opacity(
            opacity: el.opacity.clamp(0.05, 1.0).toDouble(),
            child: Transform.rotate(
              angle: el.rotation * 3.14159265 / 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      decoration: BoxDecoration(
                        border: widget.isSelected
                            ? Border.all(color: accent, width: 1.4)
                            : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRect(
                        child: ElementRenderer(
                          element: el,
                          zoom: z,
                          isDark: widget.isDark,
                          selected: widget.isSelected,
                          onChanged: widget.onChanged,
                          onActivate: widget.onActivate,
                        ),
                      ),
                    ),
                  ),
                  if (widget.isSelected) ..._handles(accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _handles(Color accent) {
    const anchors = ['tl', 'tr', 'bl', 'br', 't', 'b', 'l', 'r'];
    return [
      for (final a in anchors)
        _ResizeHandle(
          anchor: a,
          accent: accent,
          onStart: (g) {
            _resizeStartPointer = g;
            _resizeStartRect = Rect.fromLTWH(
              widget.element.x,
              widget.element.y,
              widget.element.width,
              widget.element.height,
            );
            _resizeAnchor = a;
          },
          onUpdate: (g) {
            if (_resizeStartPointer == null ||
                _resizeStartRect == null ||
                _resizeAnchor == null) {
              return;
            }
            final dx = (g.dx - _resizeStartPointer!.dx) / widget.zoom;
            final dy = (g.dy - _resizeStartPointer!.dy) / widget.zoom;
            final r = _resizeStartRect!;
            double x = r.left,
                y = r.top,
                w = r.width,
                h = r.height;
            switch (_resizeAnchor!) {
              case 'tl':
                x = r.left + dx;
                y = r.top + dy;
                w = r.width - dx;
                h = r.height - dy;
                break;
              case 'tr':
                y = r.top + dy;
                w = r.width + dx;
                h = r.height - dy;
                break;
              case 'bl':
                x = r.left + dx;
                w = r.width - dx;
                h = r.height + dy;
                break;
              case 'br':
                w = r.width + dx;
                h = r.height + dy;
                break;
              case 't':
                y = r.top + dy;
                h = r.height - dy;
                break;
              case 'b':
                h = r.height + dy;
                break;
              case 'l':
                x = r.left + dx;
                w = r.width - dx;
                break;
              case 'r':
                w = r.width + dx;
                break;
            }
            const minSize = 24.0;
            if (w < minSize) {
              if (_resizeAnchor!.contains('l')) x = r.right - minSize;
              w = minSize;
            }
            if (h < minSize) {
              if (_resizeAnchor!.contains('t')) y = r.bottom - minSize;
              h = minSize;
            }
            x = widget.snap(x);
            y = widget.snap(y);
            w = widget.snap(w);
            h = widget.snap(h);
            widget.element.x =
                x.clamp(0.0, widget.pageBounds.width - 4).toDouble();
            widget.element.y =
                y.clamp(0.0, widget.pageBounds.height - 4).toDouble();
            widget.element.width = w
                .clamp(minSize, widget.pageBounds.width - widget.element.x)
                .toDouble();
            widget.element.height = h
                .clamp(minSize, widget.pageBounds.height - widget.element.y)
                .toDouble();
            widget.onChanged(widget.element);
          },
          onEnd: () {
            _resizeStartPointer = null;
            _resizeStartRect = null;
            _resizeAnchor = null;
          },
        ),
    ];
  }
}

// ─── resize handle ─────────────────────────────────────────────────────────
class _ResizeHandle extends StatelessWidget {
  final String anchor;
  final Color accent;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;

  const _ResizeHandle({
    required this.anchor,
    required this.accent,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    const handleSize = 12.0;
    AlignmentDirectional align;
    SystemMouseCursor cursor = SystemMouseCursors.resizeUpLeftDownRight;
    switch (anchor) {
      case 'tl':
        align = AlignmentDirectional.topStart;
        cursor = SystemMouseCursors.resizeUpLeftDownRight;
        break;
      case 'tr':
        align = AlignmentDirectional.topEnd;
        cursor = SystemMouseCursors.resizeUpRightDownLeft;
        break;
      case 'bl':
        align = AlignmentDirectional.bottomStart;
        cursor = SystemMouseCursors.resizeUpRightDownLeft;
        break;
      case 'br':
        align = AlignmentDirectional.bottomEnd;
        cursor = SystemMouseCursors.resizeUpLeftDownRight;
        break;
      case 't':
        align = AlignmentDirectional.topCenter;
        cursor = SystemMouseCursors.resizeUpDown;
        break;
      case 'b':
        align = AlignmentDirectional.bottomCenter;
        cursor = SystemMouseCursors.resizeUpDown;
        break;
      case 'l':
        align = AlignmentDirectional.centerStart;
        cursor = SystemMouseCursors.resizeLeftRight;
        break;
      case 'r':
      default:
        align = AlignmentDirectional.centerEnd;
        cursor = SystemMouseCursors.resizeLeftRight;
        break;
    }

    return Positioned.fill(
      child: Align(
        alignment: align,
        child: Transform.translate(
          offset: Offset(
            anchor.contains('l') ? -handleSize / 2 : (anchor.contains('r') ? handleSize / 2 : 0),
            anchor.contains('t') ? -handleSize / 2 : (anchor.contains('b') ? handleSize / 2 : 0),
          ),
          child: MouseRegion(
            cursor: cursor,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => onStart(d.globalPosition),
              onPanUpdate: (d) => onUpdate(d.globalPosition),
              onPanEnd: (_) => onEnd(),
              child: Container(
                width: handleSize,
                height: handleSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: accent, width: 1.5),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── zoom badge ────────────────────────────────────────────────────────────
class _ZoomBadge extends StatelessWidget {
  final double zoom;
  final ValueChanged<double> onZoom;
  final bool isDark;

  const _ZoomBadge({
    required this.zoom,
    required this.onZoom,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Zoom out',
              icon: const Icon(Icons.remove_rounded, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              onPressed: () =>
                  onZoom((zoom - 0.1).clamp(0.3, 2.5).toDouble()),
            ),
            GestureDetector(
              onTap: () => onZoom(1.0),
              child: SizedBox(
                width: 52,
                child: Text(
                  '${(zoom * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Zoom in',
              icon: const Icon(Icons.add_rounded, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              onPressed: () =>
                  onZoom((zoom + 0.1).clamp(0.3, 2.5).toDouble()),
            ),
          ],
        ),
      ),
    );
  }
}
