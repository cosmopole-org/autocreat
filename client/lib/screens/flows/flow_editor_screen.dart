import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/flow.dart';
import '../../providers/flow_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/graph_editor.dart';
import 'flow_node_editor.dart';

class FlowEditorScreen extends ConsumerStatefulWidget {
  final String flowId;

  const FlowEditorScreen({super.key, required this.flowId});

  @override
  ConsumerState<FlowEditorScreen> createState() => _FlowEditorScreenState();
}

class _FlowEditorScreenState extends ConsumerState<FlowEditorScreen> {
  bool _loading = true;
  bool _saving = false;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadFlow();
  }

  Future<void> _loadFlow() async {
    final repo = ref.read(flowRepositoryProvider);
    try {
      final flow = await repo.getFlow(widget.flowId);
      ref.read(flowEditorProvider.notifier).loadFlow(flow);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading flow: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(flowRepositoryProvider);
      await ref.read(flowEditorProvider.notifier).save(repo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flow saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addNode(NodeType type) {
    const uuid = Uuid();
    final state = ref.read(flowEditorProvider);
    final node = FlowNode(
      id: uuid.v4(),
      label: type.name.toUpperCase(),
      type: type,
      x: 200 - state.offsetX / state.scale,
      y: 200 - state.offsetY / state.scale,
    );
    ref.read(flowEditorProvider.notifier).addNode(node);
  }

  void _showLabelEditor(BuildContext ctx, FlowNode node) {
    final ctrl = TextEditingController(text: node.label);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Edit node label'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Label'),
          onSubmitted: (_) => Navigator.pop(ctx, ctrl.text),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((result) {
      if (result is String && result.isNotEmpty) {
        ref.read(flowEditorProvider.notifier).updateNode(
              node.copyWith(label: result),
            );
      }
    });
  }

  void _autoLayout() {
    final state = ref.read(flowEditorProvider);
    final nodes = List<FlowNode>.from(state.nodes);
    const startX = 80.0;
    const startY = 200.0;
    const spacingX = 220.0;

    // Simple left-to-right layout
    int i = 0;
    for (final node in nodes) {
      ref.read(flowEditorProvider.notifier).updateNodePosition(
            node.id,
            startX + i * spacingX,
            startY,
          );
      i++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(flowEditorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.flows),
        ),
        title: Row(
          children: [
            Text(editorState.flow?.name ?? 'Flow Editor'),
            if (editorState.isDirty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Unsaved',
                  style: TextStyle(fontSize: 11, color: AppColors.warning),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => ref
                .read(flowEditorProvider.notifier)
                .setScale(editorState.scale - 0.1),
            tooltip: 'Zoom out',
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(editorState.scale * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => ref
                .read(flowEditorProvider.notifier)
                .setScale(editorState.scale + 0.1),
            tooltip: 'Zoom in',
          ),
          const SizedBox(width: 8),
          AppButton(
            label: 'Save',
            icon: Icons.save_outlined,
            loading: _saving,
            onPressed: _save,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Toolbar
          Container(
            width: 56,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _ToolButton(
                  icon: Icons.play_circle_outline,
                  color: AppColors.nodeStart,
                  tooltip: 'Add Start Node',
                  onTap: () => _addNode(NodeType.start),
                ),
                const SizedBox(height: 4),
                _ToolButton(
                  icon: Icons.task_alt,
                  color: AppColors.nodeStep,
                  tooltip: 'Add Step Node',
                  onTap: () => _addNode(NodeType.step),
                ),
                const SizedBox(height: 4),
                _ToolButton(
                  icon: Icons.call_split,
                  color: AppColors.nodeDecision,
                  tooltip: 'Add Decision Node',
                  onTap: () => _addNode(NodeType.decision),
                ),
                const SizedBox(height: 4),
                _ToolButton(
                  icon: Icons.stop_circle_outlined,
                  color: AppColors.nodeEnd,
                  tooltip: 'Add End Node',
                  onTap: () => _addNode(NodeType.end),
                ),
                const Spacer(),
                _ToolButton(
                  icon: Icons.auto_fix_high,
                  color: AppColors.accent,
                  tooltip: 'Auto Layout',
                  onTap: _autoLayout,
                ),
                _ToolButton(
                  icon: Icons.fit_screen,
                  color: AppColors.lightTextSecondary,
                  tooltip: 'Fit to screen',
                  onTap: () {
                    ref.read(flowEditorProvider.notifier).setScale(1.0);
                    ref.read(flowEditorProvider.notifier).setOffset(0, 0);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Canvas
          Expanded(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    _canvasSize = Size(
                        constraints.maxWidth, constraints.maxHeight);
                    if (editorState.nodes.isEmpty) {
                      return _EmptyCanvasHint(
                        onAddNode: () => _addNode(NodeType.start),
                      );
                    }
                    return GraphEditor(
                      nodes: editorState.nodes,
                      edges: editorState.edges,
                      selectedNodeId: editorState.selectedNodeId,
                      selectedEdgeId: editorState.selectedEdgeId,
                      scale: editorState.scale,
                      offsetX: editorState.offsetX,
                      offsetY: editorState.offsetY,
                      onNodeTap: (node) {
                        if (node.id.isEmpty) {
                          ref
                              .read(flowEditorProvider.notifier)
                              .selectNode(null);
                        } else {
                          ref
                              .read(flowEditorProvider.notifier)
                              .selectNode(node.id);
                        }
                      },
                      onEdgeTap: (edge) => ref
                          .read(flowEditorProvider.notifier)
                          .selectEdge(edge.id),
                      onNodeMoved: (node) => ref
                          .read(flowEditorProvider.notifier)
                          .updateNodePosition(node.id, node.x, node.y),
                      onEdgeCreate: (sourceId, targetId,
                          {String? conditionLabel}) {
                        const uuid = Uuid();
                        ref.read(flowEditorProvider.notifier).addEdge(
                              FlowEdge(
                                id: uuid.v4(),
                                sourceNodeId: sourceId,
                                targetNodeId: targetId,
                                label: conditionLabel,
                              ),
                            );
                      },
                      onEdgeDelete: (edgeId) => ref
                          .read(flowEditorProvider.notifier)
                          .deleteEdge(edgeId),
                      onNodeDelete: (nodeId) => ref
                          .read(flowEditorProvider.notifier)
                          .deleteNode(nodeId),
                      onNodeDoubleTap: (node) =>
                          _showLabelEditor(context, node),
                      onScaleChanged: (s) =>
                          ref.read(flowEditorProvider.notifier).setScale(s),
                      onOffsetChanged: (dx, dy) => ref
                          .read(flowEditorProvider.notifier)
                          .setOffset(dx, dy),
                    );
                  },
                ),

                // Minimap
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: GraphMinimap(
                    nodes: editorState.nodes,
                    scale: editorState.scale,
                    offsetX: editorState.offsetX,
                    offsetY: editorState.offsetY,
                    viewportSize: _canvasSize,
                    onTap: (dx, dy) => ref
                        .read(flowEditorProvider.notifier)
                        .setOffset(dx, dy),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                // Node count indicator
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      '${editorState.nodes.length} nodes · ${editorState.edges.length} edges',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Node properties panel
          if (editorState.selectedNode != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isDesktop ? 300 : 240,
              child: FlowNodeEditor(
                node: editorState.selectedNode!,
                onUpdate: (updated) =>
                    ref.read(flowEditorProvider.notifier).updateNode(updated),
                onDelete: () => ref
                    .read(flowEditorProvider.notifier)
                    .deleteNode(editorState.selectedNode!.id),
              ),
            ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1),
        ],
      ),
    );
  }
}

class _EmptyCanvasHint extends StatelessWidget {
  final VoidCallback onAddNode;

  const _EmptyCanvasHint({required this.onAddNode});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(20),
        dashPattern: const [8, 4],
        color: AppColors.primary.withValues(alpha: 0.4),
        strokeWidth: 2,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onAddNode,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 60, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 56,
                    color: AppColors.primary.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Start building your flow',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click here to add a Start node,\nor use the toolbar on the left.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
