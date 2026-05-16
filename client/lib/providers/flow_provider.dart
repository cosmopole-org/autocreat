import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/demo_data.dart';
import '../data/repositories/flow_repository.dart';
import '../models/flow.dart';
import 'auth_provider.dart';
import 'demo_provider.dart';
import 'theme_provider.dart';

final flowRepositoryProvider = Provider<FlowRepository>((ref) {
  return FlowRepository(ref.watch(apiClientProvider));
});

final flowsProvider = FutureProvider.family<List<Flow>, String?>((ref, companyId) async {
  final isDemo = ref.watch(isDemoModeProvider);
  ref.watch(languageProvider);
  if (isDemo) return DemoData.flows.map(Flow.fromJson).toList();
  return ref.watch(flowRepositoryProvider).getFlows(companyId: companyId);
});

final flowDetailProvider = FutureProvider.family<Flow, String>((ref, id) async {
  final isDemo = ref.watch(isDemoModeProvider);
  ref.watch(languageProvider);
  if (isDemo) {
    final match = DemoData.flows.firstWhere(
      (f) => f['id'] == id,
      orElse: () => DemoData.flows.first,
    );
    return Flow.fromJson(match);
  }
  return ref.watch(flowRepositoryProvider).getFlow(id);
});

class FlowEditorNotifier extends Notifier<FlowEditorState> {
  @override
  FlowEditorState build() => FlowEditorState.empty();

  void loadFlow(Flow flow) {
    state = FlowEditorState(
      flow: flow,
      nodes: List.from(flow.nodes),
      edges: List.from(flow.edges),
      selectedNodeId: null,
      isDirty: false,
      scale: 1.0,
      offsetX: 0.0,
      offsetY: 0.0,
    );
  }

  void updateNodePosition(String nodeId, double x, double y) {
    state = state.copyWith(
      nodes: state.nodes
          .map((n) => n.id == nodeId ? n.copyWith(x: x, y: y) : n)
          .toList(),
      isDirty: true,
    );
  }

  void selectNode(String? nodeId) {
    state = state.copyWith(
      selectedNodeId: nodeId,
      clearSelectedEdge: true,
    );
  }

  void selectEdge(String? edgeId) {
    state = state.copyWith(
      selectedEdgeId: edgeId,
      clearSelectedNode: true,
    );
  }

  void addNode(FlowNode node) {
    state = state.copyWith(
      nodes: [...state.nodes, node],
      isDirty: true,
    );
  }

  void updateNode(FlowNode node) {
    state = state.copyWith(
      nodes: state.nodes.map((n) => n.id == node.id ? node : n).toList(),
      isDirty: true,
    );
  }

  void deleteNode(String nodeId) {
    state = state.copyWith(
      nodes: state.nodes.where((n) => n.id != nodeId).toList(),
      edges: state.edges
          .where(
              (e) => e.sourceNodeId != nodeId && e.targetNodeId != nodeId)
          .toList(),
      selectedNodeId:
          state.selectedNodeId == nodeId ? null : state.selectedNodeId,
      isDirty: true,
    );
  }

  void addEdge(FlowEdge edge) {
    // Avoid duplicate edges
    final exists = state.edges.any((e) =>
        e.sourceNodeId == edge.sourceNodeId &&
        e.targetNodeId == edge.targetNodeId);
    if (!exists) {
      state = state.copyWith(
        edges: [...state.edges, edge],
        isDirty: true,
      );
    }
  }

  void deleteEdge(String edgeId) {
    state = state.copyWith(
      edges: state.edges.where((e) => e.id != edgeId).toList(),
      isDirty: true,
      clearSelectedEdge: true,
    );
  }

  void setScale(double scale) {
    state = state.copyWith(scale: scale.clamp(0.3, 3.0));
  }

  void setOffset(double x, double y) {
    state = state.copyWith(offsetX: x, offsetY: y);
  }

  Future<void> save(FlowRepository repo) async {
    if (state.flow == null) return;
    final saved = await repo.saveFlowGraph(
      state.flow!.id,
      state.nodes,
      state.edges,
    );
    state = state.copyWith(flow: saved, isDirty: false);
  }
}

class FlowEditorState {
  final Flow? flow;
  final List<FlowNode> nodes;
  final List<FlowEdge> edges;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final bool isDirty;
  final double scale;
  final double offsetX;
  final double offsetY;

  const FlowEditorState({
    this.flow,
    required this.nodes,
    required this.edges,
    this.selectedNodeId,
    this.selectedEdgeId,
    required this.isDirty,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  factory FlowEditorState.empty() => const FlowEditorState(
        nodes: [],
        edges: [],
        isDirty: false,
        scale: 1.0,
        offsetX: 0.0,
        offsetY: 0.0,
      );

  FlowEditorState copyWith({
    Flow? flow,
    List<FlowNode>? nodes,
    List<FlowEdge>? edges,
    String? selectedNodeId,
    String? selectedEdgeId,
    bool? isDirty,
    double? scale,
    double? offsetX,
    double? offsetY,
    bool clearSelectedNode = false,
    bool clearSelectedEdge = false,
  }) {
    return FlowEditorState(
      flow: flow ?? this.flow,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      selectedNodeId:
          clearSelectedNode ? null : (selectedNodeId ?? this.selectedNodeId),
      selectedEdgeId:
          clearSelectedEdge ? null : (selectedEdgeId ?? this.selectedEdgeId),
      isDirty: isDirty ?? this.isDirty,
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
    );
  }

  FlowNode? get selectedNode {
    if (selectedNodeId == null) return null;
    try {
      return nodes.firstWhere((n) => n.id == selectedNodeId);
    } catch (_) {
      return null;
    }
  }
}

final flowEditorProvider =
    NotifierProvider<FlowEditorNotifier, FlowEditorState>(
        FlowEditorNotifier.new);
