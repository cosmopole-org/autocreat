import 'package:freezed_annotation/freezed_annotation.dart';

part 'flow.freezed.dart';
part 'flow.g.dart';

enum NodeType { start, step, decision, end }

@freezed
class FlowNode with _$FlowNode {
  const factory FlowNode({
    required String id,
    required String label,
    required NodeType type,
    @Default(100.0) double x,
    @Default(100.0) double y,
    @Default(160.0) double width,
    @Default(60.0) double height,
    String? assignedRoleId,
    String? assignedFormId,
    String? description,
    @Default([]) List<BranchCondition> branches,
    Map<String, dynamic>? metadata,
  }) = _FlowNode;

  factory FlowNode.fromJson(Map<String, dynamic> json) => _$FlowNodeFromJson(json);
}

@freezed
class BranchCondition with _$BranchCondition {
  const factory BranchCondition({
    required String id,
    required String label,
    String? condition,
    String? targetNodeId,
    @Default(false) bool isDefault,
  }) = _BranchCondition;

  factory BranchCondition.fromJson(Map<String, dynamic> json) => _$BranchConditionFromJson(json);
}

@freezed
class FlowEdge with _$FlowEdge {
  const factory FlowEdge({
    required String id,
    required String sourceNodeId,
    required String targetNodeId,
    String? label,
    String? conditionId,
  }) = _FlowEdge;

  factory FlowEdge.fromJson(Map<String, dynamic> json) => _$FlowEdgeFromJson(json);
}

@freezed
class Flow with _$Flow {
  const factory Flow({
    required String id,
    required String name,
    String? description,
    String? companyId,
    @Default('draft') String status,
    @Default([]) List<FlowNode> nodes,
    @Default([]) List<FlowEdge> edges,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Flow;

  factory Flow.fromJson(Map<String, dynamic> json) => _$FlowFromJson(json);
}
