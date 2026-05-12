import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/utils.dart';
import '../models/flow.dart';
import '../theme/app_colors.dart';

typedef NodeCallback = void Function(FlowNode node);
typedef EdgeCallback = void Function(FlowEdge edge);

class GraphEditor extends StatefulWidget {
  final List<FlowNode> nodes;
  final List<FlowEdge> edges;
  final String? selectedNodeId;
  final NodeCallback? onNodeTap;
  final NodeCallback? onNodeMoved;
  final Function(String sourceId, String targetId)? onEdgeCreate;
  final EdgeCallback? onEdgeTap;
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
    this.onNodeTap,
    this.onNodeMoved,
    this.onEdgeCreate,
    this.onEdgeTap,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.onScaleChanged,
    this.onOffsetChanged,
  });

  @override
  State<GraphEditor> createState() => _GraphEditorState();
}

class _GraphEditorState extends State<GraphEditor> {
  String? _draggingNodeId;
  Offset? _dragStartOffset;
  Offset? _nodeStartPosition;
  Offset? _edgeDragStart;
  String? _edgeDragSourceId;
  Offset? _edgeDragCurrent;
  bool _isPanning = false;
  Offset? _panStart;
  double _panStartOffsetX = 0;
  double _panStartOffsetY = 0;

  // Convert screen coords to canvas coords
  Offset _screenToCanvas(Offset screen) {
    return Offset(
      (screen.dx - widget.offsetX) / widget.scale,
      (screen.dy - widget.offsetY) / widget.scale,
    );
  }

  FlowNode? _hitTestNode(Offset canvasPos) {
    for (final node in widget.nodes.reversed) {
      final rect = Rect.fromLTWH(node.x, node.y, node.width, node.height);
      if (rect.contains(canvasPos)) return node;
    }
    return null;
  }

  bool _hitTestEdgeHandle(Offset canvasPos, FlowNode node) {
    // right handle
    final handleCenter = Offset(node.x + node.width, node.y + node.height / 2);
    return (canvasPos - handleCenter).distance < 12;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          double delta = event.scrollDelta.dy > 0 ? -0.1 : 0.1;
          final newScale = (widget.scale + delta).clamp(0.3, 3.0);
          widget.onScaleChanged?.call(newScale);
        }
      },
      child: GestureDetector(
        onPanStart: (details) {
          final canvasPos = _screenToCanvas(details.localPosition);
          // Check if starting edge drag from handle
          for (final node in widget.nodes) {
            if (_hitTestEdgeHandle(canvasPos, node)) {
              setState(() {
                _edgeDragSourceId = node.id;
                _edgeDragStart = Offset(
                  node.x + node.width,
                  node.y + node.height / 2,
                );
                _edgeDragCurrent = canvasPos;
              });
              return;
            }
          }
          // Check node drag
          final hit = _hitTestNode(canvasPos);
          if (hit != null) {
            setState(() {
              _draggingNodeId = hit.id;
              _dragStartOffset = canvasPos;
              _nodeStartPosition = Offset(hit.x, hit.y);
            });
          } else {
            // Start panning
            setState(() {
              _isPanning = true;
              _panStart = details.localPosition;
              _panStartOffsetX = widget.offsetX;
              _panStartOffsetY = widget.offsetY;
            });
          }
        },
        onPanUpdate: (details) {
          final canvasPos = _screenToCanvas(details.localPosition);
          if (_edgeDragSourceId != null) {
            setState(() => _edgeDragCurrent = canvasPos);
            return;
          }
          if (_draggingNodeId != null && _dragStartOffset != null) {
            final dx = canvasPos.dx - _dragStartOffset!.dx;
            final dy = canvasPos.dy - _dragStartOffset!.dy;
            final newX = _nodeStartPosition!.dx + dx;
            final newY = _nodeStartPosition!.dy + dy;
            final node = widget.nodes.firstWhere((n) => n.id == _draggingNodeId);
            widget.onNodeMoved?.call(node.copyWith(x: newX, y: newY));
          } else if (_isPanning && _panStart != null) {
            final dx = details.localPosition.dx - _panStart!.dx;
            final dy = details.localPosition.dy - _panStart!.dy;
            widget.onOffsetChanged
                ?.call(_panStartOffsetX + dx, _panStartOffsetY + dy);
          }
        },
        onPanEnd: (details) {
          if (_edgeDragSourceId != null && _edgeDragCurrent != null) {
            // Check if dropped on a node
            final target = _hitTestNode(_edgeDragCurrent!);
            if (target != null && target.id != _edgeDragSourceId) {
              widget.onEdgeCreate?.call(_edgeDragSourceId!, target.id);
            }
          }
          setState(() {
            _draggingNodeId = null;
            _dragStartOffset = null;
            _nodeStartPosition = null;
            _edgeDragSourceId = null;
            _edgeDragStart = null;
            _edgeDragCurrent = null;
            _isPanning = false;
            _panStart = null;
          });
        },
        onTapUp: (details) {
          final canvasPos = _screenToCanvas(details.localPosition);
          final hit = _hitTestNode(canvasPos);
          if (hit != null) {
            widget.onNodeTap?.call(hit);
          } else {
            widget.onNodeTap?.call(FlowNode(id: '', label: '', type: NodeType.step));
          }
        },
        child: ClipRect(
          child: CustomPaint(
            painter: _GraphPainter(
              nodes: widget.nodes,
              edges: widget.edges,
              selectedNodeId: widget.selectedNodeId,
              scale: widget.scale,
              offsetX: widget.offsetX,
              offsetY: widget.offsetY,
              edgeDragStart: _edgeDragStart,
              edgeDragEnd: _edgeDragCurrent,
              brightness: Theme.of(context).brightness,
            ),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<FlowNode> nodes;
  final List<FlowEdge> edges;
  final String? selectedNodeId;
  final double scale;
  final double offsetX;
  final double offsetY;
  final Offset? edgeDragStart;
  final Offset? edgeDragEnd;
  final Brightness brightness;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    this.selectedNodeId,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    this.edgeDragStart,
    this.edgeDragEnd,
    required this.brightness,
  });

  bool get isDark => brightness == Brightness.dark;

  Color get bgColor => isDark ? AppColors.darkBg : const Color(0xFFF0F4FF);
  Color get dotColor => isDark
      ? AppColors.darkBorder.withOpacity(0.4)
      : AppColors.lightBorder.withOpacity(0.6);
  Color get edgeColor => isDark ? AppColors.darkBorder : AppColors.lightTextHint;

  Offset canvasToScreen(Offset canvas) {
    return Offset(
      canvas.dx * scale + offsetX,
      canvas.dy * scale + offsetY,
    );
  }

  Rect nodeScreenRect(FlowNode node) {
    final tl = canvasToScreen(Offset(node.x, node.y));
    return Rect.fromLTWH(
        tl.dx, tl.dy, node.width * scale, node.height * scale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = bgColor);

    // Grid dots
    _drawGrid(canvas, size);

    // Edges
    for (final edge in edges) {
      _drawEdge(canvas, edge);
    }

    // Drag edge
    if (edgeDragStart != null && edgeDragEnd != null) {
      final startScreen = canvasToScreen(edgeDragStart!);
      final endScreen = canvasToScreen(edgeDragEnd!);
      _drawCurvedArrow(
        canvas,
        startScreen,
        endScreen,
        Paint()
          ..color = AppColors.accent.withOpacity(0.7)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
        AppColors.accent.withOpacity(0.7),
      );
    }

    // Nodes
    for (final node in nodes) {
      _drawNode(canvas, node);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    final startX = offsetX % spacing;
    final startY = offsetY % spacing;

    for (double x = startX; x < size.width; x += spacing) {
      for (double y = startY; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  void _drawEdge(Canvas canvas, FlowEdge edge) {
    final source = _findNode(edge.sourceNodeId);
    final target = _findNode(edge.targetNodeId);
    if (source == null || target == null) return;

    final sourceCenter = canvasToScreen(
        Offset(source.x + source.width, source.y + source.height / 2));
    final targetCenter = canvasToScreen(
        Offset(target.x, target.y + target.height / 2));

    final edgePaint = Paint()
      ..color = edgeColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawCurvedArrow(canvas, sourceCenter, targetCenter, edgePaint, edgeColor);

    // Label
    if (edge.label != null && edge.label!.isNotEmpty) {
      final mid = Offset(
        (sourceCenter.dx + targetCenter.dx) / 2,
        (sourceCenter.dy + targetCenter.dy) / 2 - 12,
      );
      _drawText(canvas, edge.label!, mid, 10, edgeColor);
    }
  }

  void _drawCurvedArrow(
      Canvas canvas, Offset start, Offset end, Paint paint, Color arrowColor) {
    final dx = end.dx - start.dx;
    final ctrl1 = Offset(start.dx + dx * 0.5, start.dy);
    final ctrl2 = Offset(end.dx - dx * 0.5, end.dy);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, end.dx, end.dy);

    canvas.drawPath(path, paint);

    // Arrow head
    final angle = math.atan2(end.dy - ctrl2.dy, end.dx - ctrl2.dx);
    const arrowSize = 8.0;
    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle - 0.4),
        end.dy - arrowSize * math.sin(angle - 0.4),
      )
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + 0.4),
        end.dy - arrowSize * math.sin(angle + 0.4),
      )
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()..color = arrowColor..style = PaintingStyle.fill,
    );
  }

  void _drawNode(Canvas canvas, FlowNode node) {
    final rect = nodeScreenRect(node);
    final isSelected = node.id == selectedNodeId;
    final nodeColor = AppUtils.getNodeTypeColor(node.type.name);

    // Shadow
    if (isSelected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(14)),
        Paint()
          ..color = nodeColor.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Node background
    final bgPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1C2333)
          : Colors.white
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = isSelected ? nodeColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder)
      ..strokeWidth = isSelected ? 2.5 : 1
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    // Left color stripe
    final stripePath = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(rect.left, rect.top, 4, rect.height),
        topLeft: const Radius.circular(12),
        bottomLeft: const Radius.circular(12),
      ));
    canvas.drawPath(stripePath, Paint()..color = nodeColor);

    // Icon
    final iconData = AppUtils.getNodeTypeIcon(node.type.name);
    final iconOffset = Offset(rect.left + 18, rect.center.dy - 9);
    _drawIcon(canvas, iconData, iconOffset, nodeColor, 18);

    // Label
    final labelX = rect.left + 42;
    final labelWidth = rect.width - 52;
    _drawTextBox(
      canvas,
      node.label,
      Offset(labelX, rect.center.dy - 8),
      labelWidth,
      12 * scale.clamp(0.7, 1.3),
      isDark ? AppColors.darkText : AppColors.lightText,
      fontWeight: FontWeight.w600,
    );

    // Subtitle (type)
    _drawTextBox(
      canvas,
      node.type.name.toUpperCase(),
      Offset(labelX, rect.center.dy + 6),
      labelWidth,
      9 * scale.clamp(0.7, 1.3),
      nodeColor,
    );

    // Edge handle (right side)
    final handlePos = Offset(rect.right, rect.center.dy);
    canvas.drawCircle(handlePos, 6 * scale.clamp(0.5, 1.5),
        Paint()..color = nodeColor);
    canvas.drawCircle(
        handlePos,
        5 * scale.clamp(0.5, 1.5),
        Paint()
          ..color = isDark ? const Color(0xFF1C2333) : Colors.white
          ..style = PaintingStyle.fill);
  }

  void _drawText(
      Canvas canvas, String text, Offset offset, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawTextBox(
    Canvas canvas,
    String text,
    Offset offset,
    double maxWidth,
    double fontSize,
    Color color, {
    FontWeight fontWeight = FontWeight.w400,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            fontSize: fontSize, color: color, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );
    tp.layout(maxWidth: maxWidth);
    tp.paint(canvas, offset);
  }

  void _drawIcon(
      Canvas canvas, IconData icon, Offset offset, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  FlowNode? _findNode(String id) {
    try {
      return nodes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) => true;
}

// Minimap widget
class GraphMinimap extends StatelessWidget {
  final List<FlowNode> nodes;
  final double scale;
  final double offsetX;
  final double offsetY;
  final Size viewportSize;

  const GraphMinimap({
    super.key,
    required this.nodes,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.viewportSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 160,
      height: 100,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
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
    if (nodes.isEmpty) return;

    // Compute bounds of all nodes
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final n in nodes) {
      minX = math.min(minX, n.x);
      minY = math.min(minY, n.y);
      maxX = math.max(maxX, n.x + n.width);
      maxY = math.max(maxY, n.y + n.height);
    }

    const padding = 20.0;
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
            Rect.fromLTWH(rx, ry, rw, rh), const Radius.circular(3)),
        Paint()
          ..color = AppUtils.getNodeTypeColor(node.type.name).withOpacity(0.6)
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
        ..color = AppColors.primary.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      Rect.fromLTWH(vpLeft, vpTop, vpW, vpH),
      Paint()
        ..color = AppColors.primary.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_MinimapPainter old) => true;
}
