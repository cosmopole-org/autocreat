import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils.dart';
import '../../models/flow.dart';
import '../../providers/flow_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/graph_editor.dart';
import 'flow_node_editor.dart';
import '../../data/mock_ui_text.dart';

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
  // Track which node id currently has the bottom sheet open (mobile)
  String? _sheetNodeId;

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
          SnackBar(content: Text(MockUiText.errorLoadingFlow(e))),
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
            content: Text(MockUiText.flowSaved),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(MockUiText.errorSaving(e)),
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
        title: Text(MockUiText.editNodeLabel),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: MockUiText.label),
          onSubmitted: (_) => Navigator.pop(ctx, ctrl.text),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MockUiText.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(MockUiText.save),
          ),
        ],
      ),
    ).then((result) {
      if (result is String && result.isNotEmpty) {
        ref
            .read(flowEditorProvider.notifier)
            .updateNode(node.copyWith(label: result));
      }
    });
  }

  void _autoLayout() {
    final state = ref.read(flowEditorProvider);
    final nodes = List<FlowNode>.from(state.nodes);
    const startX = 80.0;
    const startY = 200.0;
    const spacingX = 220.0;

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

  // ── Mobile bottom sheet ───────────────────────────────────────

  void _openNodeSheet(FlowNode node) {
    if (_sheetNodeId == node.id) return;
    setState(() => _sheetNodeId = node.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      enableDrag: true,
      builder: (sheetCtx) => _NodePropertiesSheet(
        node: node,
        onUpdate: (updated) =>
            ref.read(flowEditorProvider.notifier).updateNode(updated),
        onDelete: () {
          Navigator.of(sheetCtx).pop();
          ref.read(flowEditorProvider.notifier).deleteNode(node.id);
          ref.read(flowEditorProvider.notifier).selectNode(null);
        },
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _sheetNodeId = null);
        // Deselect so the sheet does not auto-reopen after user swipes down
        ref.read(flowEditorProvider.notifier).selectNode(null);
      }
    });
  }

  void _showMobileControls(
      BuildContext context, FlowEditorState editorState, bool isDark) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
              blurRadius: 28,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  MockUiText.canvasControls,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  MockUiText.zoomPercent(editorState.scale),
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ControlButton(
                        icon: Icons.remove_rounded,
                        label: MockUiText.zoomOut,
                        color: AppColors.primary,
                        onTap: () {
                          ref
                              .read(flowEditorProvider.notifier)
                              .setScale(editorState.scale - 0.15);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ControlButton(
                        icon: Icons.add_rounded,
                        label: MockUiText.zoomIn,
                        color: AppColors.primary,
                        onTap: () {
                          ref
                              .read(flowEditorProvider.notifier)
                              .setScale(editorState.scale + 0.15);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ControlButton(
                        icon: Icons.fit_screen_rounded,
                        label: MockUiText.fitScreen,
                        color: AppColors.accent,
                        onTap: () {
                          ref
                              .read(flowEditorProvider.notifier)
                              .setScale(1.0);
                          ref
                              .read(flowEditorProvider.notifier)
                              .setOffset(0, 0);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ControlButton(
                        icon: Icons.auto_fix_high_rounded,
                        label: MockUiText.autoLayout,
                        color: AppColors.accent,
                        onTap: () {
                          _autoLayout();
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(flowEditorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 700 && width < 1100;
    final isMobile = width < 700;

    // Auto-open sheet when node is selected on mobile
    if (isMobile && editorState.selectedNode != null) {
      final selId = editorState.selectedNode!.id;
      if (_sheetNodeId != selId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openNodeSheet(editorState.selectedNode!);
        });
      }
    }

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final toolbarBg =
        isDark ? AppColors.darkSurface : AppColors.lightCard;
    final toolbarBorder =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                editorState.flow?.name ?? MockUiText.flowEditor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (editorState.isDirty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  MockUiText.unsaved,
                  style: TextStyle(fontSize: 11, color: AppColors.warning),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!isMobile) ...[
            IconButton(
              icon: const Icon(Icons.remove_rounded, size: 18),
              onPressed: () => ref
                  .read(flowEditorProvider.notifier)
                  .setScale(editorState.scale - 0.1),
              tooltip: MockUiText.zoomOut3,
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                MockUiText.percent(editorState.scale),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 18),
              onPressed: () => ref
                  .read(flowEditorProvider.notifier)
                  .setScale(editorState.scale + 0.1),
              tooltip: MockUiText.zoomIn3,
            ),
            const SizedBox(width: 4),
          ],
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: MockUiText.canvasControls3,
              onPressed: () =>
                  _showMobileControls(context, editorState, isDark),
            ),
          AppButton(
            label: isMobile ? MockUiText.save : MockUiText.saveFlow,
            icon: Icons.save_outlined,
            loading: _saving,
            onPressed: _save,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          // ── Left toolbar ──────────────────────────────────────
          Container(
            width: isMobile ? 48 : 56,
            decoration: BoxDecoration(
              color: toolbarBg,
              border: Border(
                right: BorderSide(color: toolbarBorder),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _ToolButton(
                  icon: Icons.play_circle_outline,
                  color: AppColors.nodeStart,
                  tooltip: MockUiText.addStartNode,
                  onTap: () => _addNode(NodeType.start),
                ),
                const SizedBox(height: 4),
                _ToolButton(
                  icon: Icons.task_alt,
                  color: AppColors.nodeStep,
                  tooltip: MockUiText.addStepNode,
                  onTap: () => _addNode(NodeType.step),
                ),
                const SizedBox(height: 4),
                _ToolButton(
                  icon: Icons.call_split,
                  color: AppColors.nodeDecision,
                  tooltip: MockUiText.addDecisionNode,
                  onTap: () => _addNode(NodeType.decision),
                ),
                const SizedBox(height: 4),
                _ToolButton(
                  icon: Icons.stop_circle_outlined,
                  color: AppColors.nodeEnd,
                  tooltip: MockUiText.addEndNode,
                  onTap: () => _addNode(NodeType.end),
                ),
                const Spacer(),
                _ToolButton(
                  icon: Icons.auto_fix_high_rounded,
                  color: AppColors.accent,
                  tooltip: MockUiText.autoLayout,
                  onTap: _autoLayout,
                ),
                _ToolButton(
                  icon: Icons.fit_screen_rounded,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  tooltip: MockUiText.fitToScreen,
                  onTap: () {
                    ref.read(flowEditorProvider.notifier).setScale(1.0);
                    ref.read(flowEditorProvider.notifier).setOffset(0, 0);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // ── Canvas ────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    _canvasSize =
                        Size(constraints.maxWidth, constraints.maxHeight);
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

                // Node / edge count badge
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard.withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      MockUiText.nodesAndEdges(editorState.nodes.length, editorState.edges.length),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Right properties panel (tablet / desktop) ─────────
          if (editorState.selectedNode != null && !isMobile)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isDesktop ? 340 : isTablet ? 290 : 240,
              child: FlowNodeEditor(
                node: editorState.selectedNode!,
                onUpdate: (updated) => ref
                    .read(flowEditorProvider.notifier)
                    .updateNode(updated),
                onDelete: () => ref
                    .read(flowEditorProvider.notifier)
                    .deleteNode(editorState.selectedNode!.id),
              ),
            ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.06),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// MOBILE NODE PROPERTIES SHEET
// ────────────────────────────────────────────────────────────────

class _NodePropertiesSheet extends StatelessWidget {
  final FlowNode node;
  final ValueChanged<FlowNode> onUpdate;
  final VoidCallback onDelete;

  const _NodePropertiesSheet({
    required this.node,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final nodeColor = AppUtils.getNodeTypeColor(node.type.name);
    final sheetBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final handleColor = cs.onSurface.withValues(alpha: 0.18);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      snapSizes: const [0.35, 0.6, 0.92],
      snap: true,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: isDark ? 0.55 : 0.16),
                blurRadius: 32,
                spreadRadius: 0,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 6),
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Sheet header ─────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 6, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: nodeColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        AppUtils.getNodeTypeIcon(node.type.name),
                        color: nodeColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MockUiText.nodeProperties,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 1),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: nodeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              node.type.name.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: nodeColor,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error, size: 22),
                      onPressed: onDelete,
                      tooltip: MockUiText.deleteNode,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppColors.error.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: cs.onSurface.withValues(alpha: 0.5),
                          size: 26),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: MockUiText.close,
                    ),
                  ],
                ),
              ),

              Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),

              // ── Scrollable properties ─────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 4,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: FlowNodeEditor(
                    node: node,
                    onUpdate: onUpdate,
                    onDelete: onDelete,
                    compact: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────
// CONTROL BUTTON (mobile canvas controls sheet)
// ────────────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// EMPTY CANVAS HINT
// ────────────────────────────────────────────────────────────────

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
        color: AppColors.primary.withValues(alpha: 0.35),
        strokeWidth: 2,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onAddNode,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 48,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    MockUiText.startBuildingYourFlow,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.lightText,
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    MockUiText.tapHereToAddAStartNodeNorUseTheToolbarOnTheLeft,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
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

// ────────────────────────────────────────────────────────────────
// TOOLBAR BUTTON
// ────────────────────────────────────────────────────────────────

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
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 22, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
