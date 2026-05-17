import 'package:flutter_test/flutter_test.dart';
import 'package:autocreat/models/flow.dart';

void main() {
  group('NodeType', () {
    test('all values exist', () {
      expect(NodeType.values, contains(NodeType.start));
      expect(NodeType.values, contains(NodeType.step));
      expect(NodeType.values, contains(NodeType.decision));
      expect(NodeType.values, contains(NodeType.end));
    });

    test('displayName is non-empty for all types', () {
      for (final type in NodeType.values) {
        expect(type.displayName.isNotEmpty, isTrue,
            reason: '${type.name} displayName should not be empty');
      }
    });

    test('enum names match Go server values', () {
      expect(NodeType.start.name, 'start');
      expect(NodeType.step.name, 'step');
      expect(NodeType.decision.name, 'decision');
      expect(NodeType.end.name, 'end');
    });
  });

  group('FlowNode', () {
    test('FlowNode.fromJson parses correctly', () {
      final json = {
        'id': 'node-1',
        'label': 'Start Step',
        'type': 'start',
        'x': 100.0,
        'y': 200.0,
        'width': 160.0,
        'height': 60.0,
        'branches': <Map<String, dynamic>>[],
      };
      final node = FlowNode.fromJson(json);
      expect(node.id, 'node-1');
      expect(node.label, 'Start Step');
      expect(node.type, NodeType.start);
      expect(node.x, 100.0);
      expect(node.y, 200.0);
    });

    test('FlowNode defaults width and height', () {
      const node = FlowNode(
        id: 'id',
        label: 'Test',
        type: NodeType.step,
      );
      expect(node.width, 160.0);
      expect(node.height, 60.0);
    });

    test('FlowNode defaults position to 100', () {
      const node = FlowNode(
        id: 'id',
        label: 'Test',
        type: NodeType.step,
      );
      expect(node.x, 100.0);
      expect(node.y, 100.0);
    });

    test('FlowNode with decision type and branches', () {
      final json = {
        'id': 'decision-1',
        'label': 'Approve?',
        'type': 'decision',
        'x': 50.0,
        'y': 150.0,
        'branches': [
          {
            'id': 'branch-1',
            'label': 'Yes',
            'isDefault': true,
          },
          {
            'id': 'branch-2',
            'label': 'No',
            'isDefault': false,
          },
        ],
      };
      final node = FlowNode.fromJson(json);
      expect(node.type, NodeType.decision);
      expect(node.branches.length, 2);
      expect(node.branches.first.label, 'Yes');
      expect(node.branches.first.isDefault, isTrue);
    });
  });

  group('BranchCondition', () {
    test('BranchCondition.fromJson parses correctly', () {
      final json = {
        'id': 'bc-1',
        'label': 'Approved',
        'condition': 'status == approved',
        'targetNodeId': 'node-end',
        'isDefault': false,
      };
      final branch = BranchCondition.fromJson(json);
      expect(branch.id, 'bc-1');
      expect(branch.label, 'Approved');
      expect(branch.condition, 'status == approved');
      expect(branch.targetNodeId, 'node-end');
      expect(branch.isDefault, isFalse);
    });

    test('BranchCondition isDefault defaults to false', () {
      const branch = BranchCondition(id: 'id', label: 'branch');
      expect(branch.isDefault, isFalse);
    });
  });

  group('FlowEdge', () {
    test('FlowEdge.fromJson parses correctly', () {
      final json = {
        'id': 'edge-1',
        'sourceNodeId': 'node-a',
        'targetNodeId': 'node-b',
        'label': 'transition',
      };
      final edge = FlowEdge.fromJson(json);
      expect(edge.id, 'edge-1');
      expect(edge.sourceNodeId, 'node-a');
      expect(edge.targetNodeId, 'node-b');
      expect(edge.label, 'transition');
    });
  });

  group('Flow', () {
    test('Flow.fromJson parses correctly', () {
      final json = {
        'id': 'flow-1',
        'name': 'Onboarding Flow',
        'description': 'New employee onboarding',
        'companyId': 'company-1',
        'status': 'active',
        'nodes': <Map<String, dynamic>>[],
        'edges': <Map<String, dynamic>>[],
      };
      final flow = Flow.fromJson(json);
      expect(flow.id, 'flow-1');
      expect(flow.name, 'Onboarding Flow');
      expect(flow.status, 'active');
      expect(flow.nodes, isEmpty);
      expect(flow.edges, isEmpty);
    });

    test('Flow default status is draft', () {
      const flow = Flow(
        id: 'id',
        name: 'Test Flow',
      );
      expect(flow.status, 'draft');
    });

    test('Flow with nodes and edges', () {
      final json = {
        'id': 'flow-2',
        'name': 'Complex Flow',
        'status': 'draft',
        'nodes': [
          {
            'id': 'node-1',
            'label': 'Start',
            'type': 'start',
            'x': 0.0,
            'y': 0.0,
            'branches': <Map<String, dynamic>>[],
          }
        ],
        'edges': [
          {
            'id': 'edge-1',
            'sourceNodeId': 'node-1',
            'targetNodeId': 'node-2',
          }
        ],
      };
      final flow = Flow.fromJson(json);
      expect(flow.nodes.length, 1);
      expect(flow.edges.length, 1);
      expect(flow.nodes.first.type, NodeType.start);
    });
  });
}
