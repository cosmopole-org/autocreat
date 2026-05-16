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

  // pinch-to-zoom state
  final Map<int, Offset> _pointers = {};
  double? _pinchStartDist;
  double? _pinchStartZoom;

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

  double _fitZoom(Size viewport, double padding) {
    final page = widget.pageSize.pixels;
    if (viewport.width <= 0 || viewport.height <= 0) return widget.zoom;
    final usableW = (viewport.width - padding * 2).clamp(40.0, double.infinity);
    final usableH = (viewport.height - padding * 2).clamp(40.0, double.infinity);
    final fitW = usableW / page.width;
    final fitH = usableH / page.height;
    return (fitW < fitH ? fitW : fitH).clamp(0.2, 2.5).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final pageSize = widget.pageSize.pixels;
    final scaled = pageSize * widget.zoom;
    final canvasBg = widget.isDark ? AppColors.darkBg : const Color(0xFFE7EAF5);
    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 720;
    final canvasPadding = isMobile ? 16.0 : 48.0;
    final handleSize = isMobile ? 20.0 : 12.0;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.isDark
                    ? [
                        AppColors.darkBg,
                        const Color(0xFF0A1228),
                      ]
                    : [
                        const Color(0xFFE7EAF5),
                        const Color(0xFFDFE5F4),
                      ],
              ),
            ),
            child: Listener(
              onPointerDown: (e) {
                _pointers[e.pointer] = e.position;
                if (_pointers.length == 2) {
                  final pts = _pointers.values.toList();
                  _pinchStartDist = (pts[0] - pts[1]).distance;
                  _pinchStartZoom = widget.zoom;
                }
              },
              onPointerMove: (e) {
                if (!_pointers.containsKey(e.pointer)) return;
                _pointers[e.pointer] = e.position;
                if (_pointers.length >= 2 &&
                    _pinchStartDist != null &&
                    _pinchStartZoom != null) {
                  final pts = _pointers.values.toList();
                  final d = (pts[0] - pts[1]).distance;
                  if (_pinchStartDist! > 0) {
                    final factor = d / _pinchStartDist!;
                    final next =
                        (_pinchStartZoom! * factor).clamp(0.2, 2.5).toDouble();
                    if ((next - widget.zoom).abs() > 0.005) {
                      widget.onZoom(next);
                    }
                  }
                }
              },
              onPointerUp: (e) {
                _pointers.remove(e.pointer);
                if (_pointers.length < 2) {
                  _pinchStartDist = null;
                  _pinchStartZoom = null;
                }
              },
              onPointerCancel: (e) {
                _pointers.remove(e.pointer);
                if (_pointers.length < 2) {
                  _pinchStartDist = null;
                  _pinchStartZoom = null;
                }
              },
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: _vController,
                    physics: const ClampingScrollPhysics(),
                    child: SingleChildScrollView(
                      controller: _hController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: viewport.width,
                          minHeight: viewport.height,
                        ),
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(canvasPadding),
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
                                        handleSize: handleSize,
                                        onSelect: () => widget.onSelect(el.id),
                                        onActivate: () =>
                                            widget.onActivate(el.id),
                                        onChanged: widget.onChanged,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: isMobile ? 10 : 16,
                    bottom: isMobile ? 10 : 16,
                    child: _ZoomBadge(
                      zoom: widget.zoom,
                      onZoom: widget.onZoom,
                      onFit: () =>
                          widget.onZoom(_fitZoom(viewport, canvasPadding)),
                      isDark: widget.isDark,
                      isMobile: isMobile,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.18),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: showGrid
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
          .withValues(alpha: isDark ? 0.05 : 0.045)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = (isDark ? Colors.white : Colors.black)
          .withValues(alpha: isDark ? 0.10 : 0.09)
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
  final double handleSize;
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
    required this.handleSize,
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
                      duration: const Duration(milliseconds: 90),
                      decoration: BoxDecoration(
                        border: widget.isSelected
                            ? Border.all(color: accent, width: 1.6)
                            : null,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: widget.isSelected
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.20),
                                  blurRadius: 14,
                                  spreadRadius: -2,
                                ),
                              ]
                            : null,
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
          size: widget.handleSize,
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
  final double size;
  final ValueChanged<Offset> onStart;
  final ValueChanged<Offset> onUpdate;
  final VoidCallback onEnd;

  const _ResizeHandle({
    required this.anchor,
    required this.accent,
    required this.size,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    AlignmentDirectional align;
    SystemMouseCursor cursor = SystemMouseCursors.resizeUpLeftDownRight;
    final isCorner = anchor.length == 2;
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

    final visualSize = isCorner ? size : size * 0.75;

    return Positioned.fill(
      child: Align(
        alignment: align,
        child: Transform.translate(
          offset: Offset(
            anchor.contains('l') ? -size / 2 : (anchor.contains('r') ? size / 2 : 0),
            anchor.contains('t') ? -size / 2 : (anchor.contains('b') ? size / 2 : 0),
          ),
          child: MouseRegion(
            cursor: cursor,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => onStart(d.globalPosition),
              onPanUpdate: (d) => onUpdate(d.globalPosition),
              onPanEnd: (_) => onEnd(),
              child: SizedBox(
                width: size,
                height: size,
                child: Center(
                  child: Container(
                    width: visualSize,
                    height: visualSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: accent, width: 1.6),
                      borderRadius:
                          BorderRadius.circular(isCorner ? 3 : visualSize / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
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
  final VoidCallback onFit;
  final bool isDark;
  final bool isMobile;

  const _ZoomBadge({
    required this.zoom,
    required this.onZoom,
    required this.onFit,
    required this.isDark,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.darkCard.withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);
    final fg = isDark ? AppColors.darkText : AppColors.lightText;
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final btnSize = isMobile ? 34.0 : 30.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 6, vertical: isMobile ? 5 : 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _circleBtn(
              icon: Icons.remove_rounded,
              tooltip: 'Zoom out',
              size: btnSize,
              fg: fg,
              onTap: () =>
                  onZoom((zoom - 0.1).clamp(0.2, 2.5).toDouble()),
            ),
            GestureDetector(
              onTap: () => onZoom(1.0),
              child: SizedBox(
                width: isMobile ? 50 : 48,
                child: Text(
                  '${(zoom * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 13 : 12,
                    color: fg,
                  ),
                ),
              ),
            ),
            _circleBtn(
              icon: Icons.add_rounded,
              tooltip: 'Zoom in',
              size: btnSize,
              fg: fg,
              onTap: () =>
                  onZoom((zoom + 0.1).clamp(0.2, 2.5).toDouble()),
            ),
            Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.08),
            ),
            _circleBtn(
              icon: Icons.fit_screen_outlined,
              tooltip: 'Fit to screen',
              size: btnSize,
              fg: accent,
              onTap: onFit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required String tooltip,
    required double size,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: isMobile ? 19 : 17, color: fg),
        ),
      ),
    );
  }
}
