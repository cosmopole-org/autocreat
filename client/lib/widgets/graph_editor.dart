import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../core/utils.dart';
import '../models/flow.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';

typedef NodeCallback = void Function(FlowNode node);
typedef EdgeCallback = void Function(FlowEdge edge);

// ─── Port descriptor ───────────────────────────────────────────────────────────

enum _PortSide { inputLeft, outputRight, outputBottomYes, outputBottomNo }

class _Port {
  final String nodeId;
  final _PortSide side;
  const _Port(this.nodeId, this.side);
}

// ─── GraphEditor ───────────────────────────────────────────────────────────────

class GraphEditor extends StatefulWidget {
  final List<FlowNode> nodes;
  final List<FlowEdge> edges;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final NodeCallback? onNodeTap;
  final NodeCallback? onNodeMoved;
  final EdgeCallback? onEdgeTap;
  final Function(String sourceId, String targetId, {String? conditionLabel})?
      onEdgeCreate;
  final Function(String edgeId)? onEdgeDelete;
  final Function(String nodeId)? onNodeDelete;
  final NodeCallback? onNodeDoubleTap;
  final double scale;
  final double offsetX;
  final double offsetY;
  final ValueChanged<double>? onScaleChanged;
  final Function(double dx, double dy)? onOffsetChanged;

  const GraphEditor({
    super.key,
    required this.nodes,
    required this.edges,
    this.selectedNodeId,
    this.selectedEdgeId,
    this.onNodeTap,
    this.onNodeMoved,
    this.onEdgeTap,
    this.onEdgeCreate,
    this.onEdgeDelete,
    this.onNodeDelete,
    this.onNodeDoubleTap,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.onScaleChanged,
    this.onOffsetChanged,
  });

  @override
  State<GraphEditor> createState() => _GraphEditorState();
}

class _GraphEditorState extends State<GraphEditor>
    with SingleTickerProviderStateMixin {
  static const double _basePortHitRadius = 22;
  // Drag state
  String? _draggingNodeId;
  Offset? _dragStartCanvas;
  Offset? _nodeStartPos;

  // Edge drawing
  _Port? _edgeSourcePort;
  Offset? _edgeDragCanvas; // current cursor in canvas coords

  // Panning
  bool _isPanning = false;
  Offset? _panStartScreen;
  double _panStartOffX = 0, _panStartOffY = 0;

  // Hover tracking (for port highlight)
  Offset? _hoverCanvas;

  // Focus node for keyboard events
  final _focusNode = FocusNode();

  // Animated marching ants ticker for selected edges
  late AnimationController _marchAnim;

  @override
  void initState() {
    super.initState();
    _marchAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _marchAnim.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── coord helpers ─────────────────────────────────────────────────────────

  Offset _screenToCanvas(Offset screen) => Offset(
        (screen.dx - widget.offsetX) / widget.scale,
        (screen.dy - widget.offsetY) / widget.scale,
      );

  // ── hit tests ─────────────────────────────────────────────────────────────

  FlowNode? _hitNode(Offset canvas) {
    for (final n in widget.nodes.reversed) {
      if (_nodeRect(n).contains(canvas)) return n;
    }
    return null;
  }

  Rect _nodeRect(FlowNode n) => Rect.fromLTWH(n.x, n.y, n.width, n.height);

  _Port? _hitPort(Offset canvas) {
    final radius = _basePortHitRadius / widget.scale;
    for (final n in widget.nodes) {
      for (final port in _portsForNode(n)) {
        final c = _portCanvasOffset(n, port.side);
        if ((canvas - c).distance < radius) return port;
      }
    }
    return null;
  }

  FlowEdge? _hitEdge(Offset canvas) {
    for (final e in widget.edges) {
      if (_edgeHitTest(e, canvas)) return e;
    }
    return null;
  }

  bool _edgeHitTest(FlowEdge e, Offset canvas) {
    final src = _findNode(e.sourceNodeId);
    final tgt = _findNode(e.targetNodeId);
    if (src == null || tgt == null) return false;
    final p0 = _portCanvasOffset(src, _PortSide.outputRight);
    final p3 = _portCanvasOffset(tgt, _PortSide.inputLeft);
    final ctrl = _bezierCtrl(p0, p3);
    // Sample 30 points on the bezier curve
    for (int i = 0; i <= 30; i++) {
      final t = i / 30;
      final pt = _cubicBezier(p0, ctrl.$1, ctrl.$2, p3, t);
      if ((pt - canvas).distance < 8 / widget.scale) return true;
    }
    return false;
  }

  // ── port helpers ──────────────────────────────────────────────────────────

  List<_Port> _portsForNode(FlowNode n) {
    final ports = [_Port(n.id, _PortSide.inputLeft)];
    if (n.type == NodeType.decision) {
      ports.add(_Port(n.id, _PortSide.outputBottomYes));
      ports.add(_Port(n.id, _PortSide.outputBottomNo));
      ports.add(_Port(n.id, _PortSide.outputRight));
    } else if (n.type != NodeType.end) {
      ports.add(_Port(n.id, _PortSide.outputRight));
    }
    return ports;
  }

  Offset _portCanvasOffset(FlowNode n, _PortSide side) {
    switch (side) {
      case _PortSide.inputLeft:
        return Offset(n.x, n.y + n.height / 2);
      case _PortSide.outputRight:
        return Offset(n.x + n.width, n.y + n.height / 2);
      case _PortSide.outputBottomYes:
        return Offset(n.x + n.width * 0.35, n.y + n.height);
      case _PortSide.outputBottomNo:
        return Offset(n.x + n.width * 0.65, n.y + n.height);
    }
  }

  bool _isOutputPort(_PortSide side) =>
      side != _PortSide.inputLeft;

  // ── bezier helpers ─────────────────────────────────────────────────────────

  (Offset, Offset) _bezierCtrl(Offset p0, Offset p3) {
    final dx = (p3.dx - p0.dx).abs().clamp(60.0, 300.0);
    return (
      Offset(p0.dx + dx * 0.5, p0.dy),
      Offset(p3.dx - dx * 0.5, p3.dy),
    );
  }

  Offset _cubicBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1 - t;
    return p0 * (mt * mt * mt) +
        p1 * (3 * mt * mt * t) +
        p2 * (3 * mt * t * t) +
        p3 * (t * t * t);
  }

  FlowNode? _findNode(String id) {
    try {
      return widget.nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── keyboard handler ──────────────────────────────────────────────────────

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (widget.selectedNodeId != null) {
        widget.onNodeDelete?.call(widget.selectedNodeId!);
      } else if (widget.selectedEdgeId != null) {
        widget.onEdgeDelete?.call(widget.selectedEdgeId!);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onNodeTap?.call(const FlowNode(id: '', label: '', type: NodeType.step));
    }
  }

  // ── context menu ──────────────────────────────────────────────────────────

  bool get _glassMode => ProviderScope.containerOf(context, listen: false).read(glassModeProvider);

  Color _contextMenuColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_glassMode) {
      return isDark ? AppColors.darkCard : AppColors.lightSurface;
    }
    return Colors.white.withValues(alpha: isDark ? 0.10 : 0.74);
  }

  ShapeBorder _contextMenuShape() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_glassMode ? 18 : 12),
      side: BorderSide(
        color: _glassMode
            ? Colors.white.withValues(alpha: isDark ? 0.16 : 0.62)
            : isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
      ),
    );
  }

  void _showNodeMenu(FlowNode node, Offset screenPos) {
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    showMenu(
      context: context,
      position: RelativeRect.fromSize(
        Rect.fromLTWH(screenPos.dx, screenPos.dy, 0, 0),
        overlay.size,
      ),
      color: _contextMenuColor(),
      surfaceTintColor: Colors.transparent,
      elevation: _glassMode ? 14 : 4,
      shadowColor: Colors.black.withValues(alpha: _glassMode ? 0.28 : 0.16),
      shape: _contextMenuShape(),
      items: <PopupMenuEntry<Object?>>[
        PopupMenuItem<Object?>(
          child: const Row(children: [
            Icon(Icons.edit_outlined, size: 16),
            SizedBox(width: 8),
            Text('Edit label'),
          ]),
          onTap: () =>
              Future.microtask(() => widget.onNodeDoubleTap?.call(node)),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<Object?>(
          child: const Row(children: [
            Icon(Icons.delete_outline, size: 16, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete node',
                style: TextStyle(color: AppColors.error)),
          ]),
          onTap: () => widget.onNodeDelete?.call(node.id),
        ),
      ],
    );
  }

  void _showEdgeMenu(FlowEdge edge, Offset screenPos) {
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    showMenu(
      context: context,
      position: RelativeRect.fromSize(
        Rect.fromLTWH(screenPos.dx, screenPos.dy, 0, 0),
        overlay.size,
      ),
      color: _contextMenuColor(),
      surfaceTintColor: Colors.transparent,
      elevation: _glassMode ? 14 : 4,
      shadowColor: Colors.black.withValues(alpha: _glassMode ? 0.28 : 0.16),
      shape: _contextMenuShape(),
      items: <PopupMenuEntry<Object?>>[
        PopupMenuItem<Object?>(
          child: const Row(children: [
            Icon(Icons.delete_outline, size: 16, color: AppColors.error),
            SizedBox(width: 8),
            Text('Delete edge',
                style: TextStyle(color: AppColors.error)),
          ]),
          onTap: () => widget.onEdgeDelete?.call(edge.id),
        ),
      ],
    );
  }

  // ── gesture handlers ──────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    _focusNode.requestFocus();
    final canvas = _screenToCanvas(d.localPosition);
    final port = _hitPort(canvas);
    if (port != null && _isOutputPort(port.side)) {
      setState(() {
        _edgeSourcePort = port;
        _edgeDragCanvas = canvas;
      });
      return;
    }
    final node = _hitNode(canvas);
    if (node != null) {
      setState(() {
        _draggingNodeId = node.id;
        _dragStartCanvas = canvas;
        _nodeStartPos = Offset(node.x, node.y);
      });
    } else {
      setState(() {
        _isPanning = true;
        _panStartScreen = d.localPosition;
        _panStartOffX = widget.offsetX;
        _panStartOffY = widget.offsetY;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final canvas = _screenToCanvas(d.localPosition);
    if (_edgeSourcePort != null) {
      setState(() => _edgeDragCanvas = canvas);
      return;
    }
    if (_draggingNodeId != null) {
      final dx = canvas.dx - _dragStartCanvas!.dx;
      final dy = canvas.dy - _dragStartCanvas!.dy;
      final node = widget.nodes.firstWhere((n) => n.id == _draggingNodeId);
      widget.onNodeMoved
          ?.call(node.copyWith(x: _nodeStartPos!.dx + dx, y: _nodeStartPos!.dy + dy));
    } else if (_isPanning) {
      final dx = d.localPosition.dx - _panStartScreen!.dx;
      final dy = d.localPosition.dy - _panStartScreen!.dy;
      widget.onOffsetChanged?.call(_panStartOffX + dx, _panStartOffY + dy);
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (_edgeSourcePort != null && _edgeDragCanvas != null) {
      final destPort = _hitInputPort(_edgeDragCanvas!);
      final target = _hitNode(_edgeDragCanvas!);
      final destId = destPort?.nodeId ?? target?.id;
      if (destId != null && destId != _edgeSourcePort!.nodeId) {
        final conditionLabel = _edgeSourcePort!.side == _PortSide.outputBottomYes
            ? 'Yes'
            : _edgeSourcePort!.side == _PortSide.outputBottomNo
                ? 'No'
                : null;
        widget.onEdgeCreate?.call(_edgeSourcePort!.nodeId, destId,
            conditionLabel: conditionLabel);
      }
    }
    setState(() {
      _draggingNodeId = null;
      _dragStartCanvas = null;
      _nodeStartPos = null;
      _edgeSourcePort = null;
      _edgeDragCanvas = null;
      _isPanning = false;
      _panStartScreen = null;
    });
  }

  _Port? _hitInputPort(Offset canvas) {
    final port = _hitPort(canvas);
    if (port != null && port.side == _PortSide.inputLeft) return port;
    return null;
  }

  void _onTapUp(TapUpDetails d) {
    _focusNode.requestFocus();
    final canvas = _screenToCanvas(d.localPosition);
    final node = _hitNode(canvas);
    if (node != null) {
      widget.onNodeTap?.call(node);
      return;
    }
    final edge = _hitEdge(canvas);
    if (edge != null) {
      widget.onEdgeTap?.call(edge);
      return;
    }
    // Deselect
    widget.onNodeTap
        ?.call(const FlowNode(id: '', label: '', type: NodeType.step));
  }

  void _onDoubleTap() {
    if (widget.selectedNodeId != null) {
      final node = _findNode(widget.selectedNodeId!);
      if (node != null) widget.onNodeDoubleTap?.call(node);
    }
  }

  void _onLongPressStart(LongPressStartDetails d) {
    _focusNode.requestFocus();
    final canvas = _screenToCanvas(d.localPosition);
    final node = _hitNode(canvas);
    if (node != null) {
      widget.onNodeTap?.call(node);
      _showNodeMenu(node, d.globalPosition);
      return;
    }
    final edge = _hitEdge(canvas);
    if (edge != null) {
      widget.onEdgeTap?.call(edge);
      _showEdgeMenu(edge, d.globalPosition);
    }
  }

  void _onScroll(PointerScrollEvent e) {
    final delta = e.scrollDelta.dy > 0 ? -0.08 : 0.08;
    final newScale = (widget.scale + delta).clamp(0.2, 4.0);
    // Zoom towards cursor position
    final cursorCanvas = _screenToCanvas(e.localPosition);
    final newOffX =
        e.localPosition.dx - cursorCanvas.dx * newScale;
    final newOffY =
        e.localPosition.dy - cursorCanvas.dy * newScale;
    widget.onScaleChanged?.call(newScale);
    widget.onOffsetChanged?.call(newOffX, newOffY);
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Listener(
        onPointerSignal: (e) {
          if (e is PointerScrollEvent) _onScroll(e);
        },
        onPointerHover: (e) {
          final canvas = _screenToCanvas(e.localPosition);
          if (mounted) setState(() => _hoverCanvas = canvas);
        },
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onTapUp: _onTapUp,
          onDoubleTap: _onDoubleTap,
          onLongPressStart: _onLongPressStart,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _marchAnim,
              builder: (context, _) => CustomPaint(
                painter: _GraphPainter(
                  nodes: widget.nodes,
                  edges: widget.edges,
                  selectedNodeId: widget.selectedNodeId,
                  selectedEdgeId: widget.selectedEdgeId,
                  scale: widget.scale,
                  offsetX: widget.offsetX,
                  offsetY: widget.offsetY,
                  edgeSourcePort: _edgeSourcePort,
                  edgeDragCanvas: _edgeDragCanvas,
                  hoverCanvas: _hoverCanvas,
                  marchPhase: _marchAnim.value,
                  brightness: Theme.of(context).brightness,
                ),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── CustomPainter ─────────────────────────────────────────────────────────────

class _GraphPainter extends CustomPainter {
  final List<FlowNode> nodes;
  final List<FlowEdge> edges;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final double scale;
  final double offsetX;
  final double offsetY;
  final _Port? edgeSourcePort;
  final Offset? edgeDragCanvas;
  final Offset? hoverCanvas;
  final double marchPhase;
  final Brightness brightness;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    this.selectedNodeId,
    this.selectedEdgeId,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    this.edgeSourcePort,
    this.edgeDragCanvas,
    this.hoverCanvas,
    required this.marchPhase,
    required this.brightness,
  });

  bool get isDark => brightness == Brightness.dark;
  Color get bgColor =>
      isDark ? const Color(0xFF0F1420) : const Color(0xFFF0F4FF);
  Color get dotColor => isDark
      ? const Color(0xFF2A3050)
      : const Color(0xFFDDE2F5);
  Color get edgeColor =>
      isDark ? const Color(0xFF4A5280) : const Color(0xFFB0BCEA);
  Color get edgeSelectedColor => AppColors.primary;
  Color get nodeBg =>
      isDark ? const Color(0xFF1C2333) : Colors.white;
  Color get nodeBorder =>
      isDark ? const Color(0xFF2D3555) : const Color(0xFFDDE2F5);
  Color get textPrimary =>
      isDark ? AppColors.darkText : AppColors.lightText;
  Color get textSecondary => AppColors.lightTextSecondary;

  Offset canvasToScreen(Offset c) =>
      Offset(c.dx * scale + offsetX, c.dy * scale + offsetY);

  Rect nodeScreenRect(FlowNode n) {
    final tl = canvasToScreen(Offset(n.x, n.y));
    return Rect.fromLTWH(tl.dx, tl.dy, n.width * scale, n.height * scale);
  }

  Offset portScreen(FlowNode n, _PortSide side) =>
      canvasToScreen(_portCanvas(n, side));

  Offset _portCanvas(FlowNode n, _PortSide side) {
    switch (side) {
      case _PortSide.inputLeft:
        return Offset(n.x, n.y + n.height / 2);
      case _PortSide.outputRight:
        return Offset(n.x + n.width, n.y + n.height / 2);
      case _PortSide.outputBottomYes:
        return Offset(n.x + n.width * 0.35, n.y + n.height);
      case _PortSide.outputBottomNo:
        return Offset(n.x + n.width * 0.65, n.y + n.height);
    }
  }

  (Offset, Offset) _bezierCtrl(Offset p0, Offset p3) {
    final dx = (p3.dx - p0.dx).abs().clamp(50.0, 250.0);
    return (
      Offset(p0.dx + dx * 0.5, p0.dy),
      Offset(p3.dx - dx * 0.5, p3.dy),
    );
  }

  Offset _cubicBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final mt = 1 - t;
    return p0 * (mt * mt * mt) +
        p1 * (3 * mt * mt * t) +
        p2 * (3 * mt * t * t) +
        p3 * (t * t * t);
  }

  FlowNode? _findNode(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = bgColor,
    );

    // Dot grid
    _drawGrid(canvas, size);

    // Shadow pass for selected node
    for (final n in nodes) {
      if (n.id == selectedNodeId) _drawNodeShadow(canvas, n);
    }

    // Edges
    for (final e in edges) {
      _drawEdge(canvas, e);
    }

    // Dragging edge
    if (edgeSourcePort != null && edgeDragCanvas != null) {
      final srcNode = _findNode(edgeSourcePort!.nodeId);
      if (srcNode != null) {
        final p0 = portScreen(srcNode, edgeSourcePort!.side);
        final p3 = canvasToScreen(edgeDragCanvas!);
        _drawDragEdge(canvas, p0, p3);
      }
    }

    // Nodes
    for (final n in nodes) {
      _drawNode(canvas, n);
    }

    // Port handles on hover / dragging
    for (final n in nodes) {
      _drawPorts(canvas, n);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    final startX = offsetX % spacing;
    final startY = offsetY % spacing;

    for (double x = startX; x < size.width; x += spacing) {
      for (double y = startY; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  void _drawNodeShadow(Canvas canvas, FlowNode n) {
    final rect = nodeScreenRect(n);
    final color = AppUtils.getNodeTypeColor(n.type.name);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(6), const Radius.circular(18)),
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  void _drawEdge(Canvas canvas, FlowEdge e) {
    final src = _findNode(e.sourceNodeId);
    final tgt = _findNode(e.targetNodeId);
    if (src == null || tgt == null) return;

    final isSelected = e.id == selectedEdgeId;

    // Determine ports: default right→left, but if there's a label matching
    // a branch condition use the appropriate output port
    _PortSide srcSide = _PortSide.outputRight;
    if (e.label == 'Yes') srcSide = _PortSide.outputBottomYes;
    if (e.label == 'No') srcSide = _PortSide.outputBottomNo;

    final p0 = portScreen(src, srcSide);
    final p3 = portScreen(tgt, _PortSide.inputLeft);
    final ctrl = _bezierCtrl(p0, p3);

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(
          ctrl.$1.dx, ctrl.$1.dy, ctrl.$2.dx, ctrl.$2.dy, p3.dx, p3.dy);

    if (isSelected) {
      // Glow under
      canvas.drawPath(
        path,
        Paint()
          ..color = edgeSelectedColor.withValues(alpha: 0.3)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Marching ants effect (simulated via _drawDashedPath)
      _drawDashedPath(
        canvas,
        path,
        Paint()
          ..color = edgeSelectedColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = edgeColor
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Arrowhead at target
    _drawArrow(canvas, ctrl.$2, p3,
        isSelected ? edgeSelectedColor : edgeColor, isSelected ? 2.0 : 1.6);

    // Label
    if (e.label != null && e.label!.isNotEmpty) {
      final mid = _cubicBezier(p0, ctrl.$1, ctrl.$2, p3, 0.5);
      _drawEdgeLabel(canvas, e.label!, mid, isSelected);
    }
  }

  void _drawDragEdge(Canvas canvas, Offset p0, Offset p3) {
    final dx = (p3.dx - p0.dx).abs().clamp(50.0, 250.0);
    final p1 = Offset(p0.dx + dx * 0.5, p0.dy);
    final p2 = Offset(p3.dx - dx * 0.5, p3.dy);

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);

    // Dashed drag line
    _drawDashedPath(
      canvas,
      path,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      p3,
      5,
      Paint()..color = AppColors.accent.withValues(alpha: 0.6),
    );
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      {double dashLen = 8, double gapLen = 5}) {
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double dist = marchPhase * (dashLen + gapLen);
      while (dist < m.length) {
        final end = math.min(dist + dashLen, m.length);
        canvas.drawPath(m.extractPath(dist, end), paint);
        dist += dashLen + gapLen;
      }
    }
  }

  void _drawArrow(
      Canvas canvas, Offset from, Offset to, Color color, double width) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowSize = 9.0;
    final arrowPath = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - arrowSize * math.cos(angle - 0.38),
        to.dy - arrowSize * math.sin(angle - 0.38),
      )
      ..lineTo(
        to.dx - arrowSize * math.cos(angle + 0.38),
        to.dy - arrowSize * math.sin(angle + 0.38),
      )
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawEdgeLabel(Canvas canvas, String label, Offset pos, bool selected) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 10,
          color: selected ? edgeSelectedColor : textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          background: Paint()
            ..color = bgColor.withValues(alpha: 0.85)
            ..style = PaintingStyle.fill,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    // Pill background
    final rect = Rect.fromCenter(
      center: pos,
      width: tp.width + 10,
      height: tp.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = bgColor.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..color =
            (selected ? edgeSelectedColor : edgeColor).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawNode(Canvas canvas, FlowNode n) {
    final rect = nodeScreenRect(n);
    final isSelected = n.id == selectedNodeId;
    final color = AppUtils.getNodeTypeColor(n.type.name);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    // Node background
    canvas.drawRRect(rrect, Paint()..color = nodeBg);

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isSelected ? color : nodeBorder
        ..strokeWidth = isSelected ? 2.5 : 1.2
        ..style = PaintingStyle.stroke,
    );

    // Left accent bar
    final barRect = Rect.fromLTWH(rect.left, rect.top, 5 * scale.clamp(0.8, 1.2), rect.height);
    canvas.drawRRect(
      RRect.fromRectAndCorners(barRect,
          topLeft: const Radius.circular(14),
          bottomLeft: const Radius.circular(14)),
      Paint()..color = color,
    );

    // Status badge for decision (small "?" in top-right corner)
    if (n.type == NodeType.decision) {
      const badgeR = 9.0;
      final badgeCenter = Offset(rect.right - badgeR - 4, rect.top + badgeR + 4);
      canvas.drawCircle(
        badgeCenter,
        badgeR,
        Paint()..color = color.withValues(alpha: 0.15),
      );
      _paintText(
        canvas,
        '?',
        badgeCenter - const Offset(3.5, 5),
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w800,
      );
    }

    // Icon
    final iconOffset = Offset(rect.left + 12 * scale.clamp(0.7, 1.3),
        rect.center.dy - 10 * scale.clamp(0.7, 1.3));
    _paintIcon(canvas, AppUtils.getNodeTypeIcon(n.type.name), iconOffset,
        color, 18 * scale.clamp(0.7, 1.3));

    // Label
    final labelX = rect.left + 38 * scale.clamp(0.7, 1.3);
    final labelW = rect.width - 44 * scale.clamp(0.7, 1.3);
    _paintTextBox(
      canvas,
      n.label,
      Offset(labelX, rect.center.dy - 10),
      labelW,
      12 * scale.clamp(0.7, 1.3),
      textPrimary,
      fontWeight: FontWeight.w600,
    );
    // Type sub-label
    _paintTextBox(
      canvas,
      n.type.name.toUpperCase(),
      Offset(labelX, rect.center.dy + 4),
      labelW,
      9 * scale.clamp(0.6, 1.1),
      color,
    );

    // Role/Form badge if assigned
    if (n.assignedRoleId != null || n.assignedFormId != null) {
      final badgeText = n.assignedFormId != null ? 'Form' : 'Role';
      final bp = Offset(rect.right - 36, rect.bottom - 16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bp.dx - 2, bp.dy - 1, 34, 12),
          const Radius.circular(4),
        ),
        Paint()..color = color.withValues(alpha: 0.12),
      );
      _paintTextBox(canvas, badgeText, bp, 32, 8, color,
          fontWeight: FontWeight.w600);
    }
  }

  void _drawPorts(Canvas canvas, FlowNode n) {
    final isHovering = hoverCanvas != null &&
        (_portCanvas(n, _PortSide.inputLeft) - hoverCanvas!).distance <
            20 / scale;

    final ports = <_PortSide>[];
    ports.add(_PortSide.inputLeft);
    if (n.type != NodeType.end) {
      ports.add(_PortSide.outputRight);
    }
    if (n.type == NodeType.decision) {
      ports.add(_PortSide.outputBottomYes);
      ports.add(_PortSide.outputBottomNo);
    }

    final isSelected = n.id == selectedNodeId;
    final color = AppUtils.getNodeTypeColor(n.type.name);
    final showPorts = isSelected || isHovering ||
        (edgeSourcePort != null && edgeSourcePort!.nodeId != n.id);

    for (final side in ports) {
      final sp = portScreen(n, side);
      final isOutput = side != _PortSide.inputLeft;
      final portColor = isOutput ? color : edgeColor;
      final radius = (showPorts ? 6.0 : 4.0) * scale.clamp(0.6, 1.4);

      // Outer ring
      canvas.drawCircle(sp, radius + 2,
          Paint()..color = portColor.withValues(alpha: showPorts ? 0.2 : 0.0));
      // Circle
      canvas.drawCircle(
          sp, radius, Paint()..color = nodeBg);
      canvas.drawCircle(
        sp,
        radius,
        Paint()
          ..color = portColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = showPorts ? 2.0 : 1.2,
      );

      // Label for decision outputs
      if (side == _PortSide.outputBottomYes && showPorts) {
        _paintText(canvas, 'Y',
            sp + Offset(-3, 6 * scale.clamp(0.6, 1.4)),
            fontSize: 8 * scale.clamp(0.6, 1.2),
            color: AppColors.success,
            fontWeight: FontWeight.w700);
      } else if (side == _PortSide.outputBottomNo && showPorts) {
        _paintText(canvas, 'N',
            sp + Offset(-3, 6 * scale.clamp(0.6, 1.4)),
            fontSize: 8 * scale.clamp(0.6, 1.2),
            color: AppColors.error,
            fontWeight: FontWeight.w700);
      }
    }
  }

  // ── text helpers ───────────────────────────────────────────────────────────

  void _paintText(Canvas canvas, String text, Offset pos,
      {required double fontSize,
      required Color color,
      FontWeight fontWeight = FontWeight.w400}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: fontSize, color: color, fontWeight: fontWeight)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, pos);
  }

  void _paintTextBox(Canvas canvas, String text, Offset pos, double maxWidth,
      double fontSize, Color color,
      {FontWeight fontWeight = FontWeight.w400}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: fontSize, color: color, fontWeight: fontWeight)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    tp.layout(maxWidth: maxWidth);
    tp.paint(canvas, pos);
  }

  void _paintIcon(Canvas canvas, IconData icon, Offset pos, Color color,
      double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(_GraphPainter old) => true;
}

// ─── GraphMinimap ──────────────────────────────────────────────────────────────

class GraphMinimap extends StatelessWidget {
  final List<FlowNode> nodes;
  final double scale;
  final double offsetX;
  final double offsetY;
  final Size viewportSize;
  final Function(double dx, double dy)? onTap;

  const GraphMinimap({
    super.key,
    required this.nodes,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.viewportSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapUp: (d) {
        if (nodes.isEmpty || onTap == null) return;
        // Map tap position on minimap to canvas offset
        const w = 160.0;
        const h = 100.0;
        double minX = double.infinity, minY = double.infinity;
        double maxX = double.negativeInfinity,
            maxY = double.negativeInfinity;
        for (final n in nodes) {
          minX = math.min(minX, n.x);
          minY = math.min(minY, n.y);
          maxX = math.max(maxX, n.x + n.width);
          maxY = math.max(maxY, n.y + n.height);
        }
        const pad = 20.0;
        final gw = maxX - minX + pad * 2;
        final gh = maxY - minY + pad * 2;
        final s = math.min(w / gw, h / gh);
        final canvasX = (d.localPosition.dx / s) + minX - pad;
        final canvasY = (d.localPosition.dy / s) + minY - pad;
        onTap!(-(canvasX * scale - viewportSize.width / 2),
            -(canvasY * scale - viewportSize.height / 2));
      },
      child: Container(
        width: 160,
        height: 100,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1C2333).withValues(alpha: 0.96)
              : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CustomPaint(
            painter: _MinimapPainter(
              nodes: nodes,
              scale: scale,
              offsetX: offsetX,
              offsetY: offsetY,
              viewportSize: viewportSize,
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final List<FlowNode> nodes;
  final double scale;
  final double offsetX;
  final double offsetY;
  final Size viewportSize;
  final bool isDark;

  _MinimapPainter({
    required this.nodes,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.viewportSize,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'No nodes',
          style: TextStyle(
              fontSize: 9,
              color: AppColors.lightTextSecondary.withValues(alpha: 0.6)),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
          canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
      return;
    }

    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final n in nodes) {
      minX = math.min(minX, n.x);
      minY = math.min(minY, n.y);
      maxX = math.max(maxX, n.x + n.width);
      maxY = math.max(maxY, n.y + n.height);
    }
    const padding = 16.0;
    final graphW = (maxX - minX) + padding * 2;
    final graphH = (maxY - minY) + padding * 2;
    final s = math.min(size.width / graphW, size.height / graphH);

    for (final node in nodes) {
      final rx = (node.x - minX + padding) * s;
      final ry = (node.y - minY + padding) * s;
      final rw = node.width * s;
      final rh = node.height * s;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(rx, ry, rw, rh), const Radius.circular(2)),
        Paint()
          ..color = AppUtils.getNodeTypeColor(node.type.name).withValues(alpha: 0.65)
          ..style = PaintingStyle.fill,
      );
    }

    // Viewport rect
    final vpLeft = (-offsetX / scale - minX + padding) * s;
    final vpTop = (-offsetY / scale - minY + padding) * s;
    final vpW = viewportSize.width / scale * s;
    final vpH = viewportSize.height / scale * s;

    canvas.drawRect(
      Rect.fromLTWH(vpLeft, vpTop, vpW, vpH),
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      Rect.fromLTWH(vpLeft, vpTop, vpW, vpH),
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_MinimapPainter old) => true;
}
