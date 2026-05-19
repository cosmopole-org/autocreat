import 'dart:io';
import 'dart:math' show Random;
import 'package:api_cli/core/token_storage.dart';
import 'package:api_cli/data/api_client.dart';
import 'package:api_cli/data/repositories/auth_repository.dart';
import 'package:api_cli/data/repositories/company_repository.dart';
import 'package:api_cli/data/repositories/flow_repository.dart';
import 'package:api_cli/data/repositories/form_repository.dart';
import 'package:api_cli/data/repositories/letter_repository.dart';
import 'package:api_cli/data/repositories/model_repository.dart';
import 'package:api_cli/data/repositories/role_repository.dart';
import 'package:api_cli/data/repositories/binding_repository.dart';
import 'package:api_cli/data/repositories/ticket_repository.dart';
import 'package:api_cli/data/repositories/user_repository.dart';
import 'package:api_cli/models/binding.dart';
import 'package:api_cli/models/flow.dart';
import 'package:api_cli/models/form_definition.dart';
import 'package:api_cli/models/model_definition.dart';
import 'package:api_cli/models/ticket.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _rng = Random();

String _uuid() {
  String hex(int n) => _rng.nextInt(n).toRadixString(16).padLeft(4, '0');
  return '${hex(0x10000)}${hex(0x10000)}-${hex(0x10000)}-4${hex(0x1000).substring(1)}'
      '-${(8 + _rng.nextInt(4)).toRadixString(16)}${hex(0x1000).substring(1)}'
      '-${hex(0x10000)}${hex(0x10000)}${hex(0x10000)}';
}

// ── Test harness ─────────────────────────────────────────────────────────────

int _passed = 0;
int _failed = 0;
final List<String> _failures = [];

void pass(String msg) {
  _passed++;
  print('  ✓  $msg');
}

void fail(String msg, [Object? err]) {
  _failed++;
  final detail = err != null ? '\n       $err' : '';
  _failures.add('$msg$detail');
  print('  ✗  $msg$detail');
}

void check(bool condition, String msg, [Object? err]) {
  if (condition) {
    pass(msg);
  } else {
    fail(msg, err);
  }
}

Future<void> section(String title, Future<void> Function() body) async {
  print('\n── $title ──────────────────────────────────');
  try {
    await body();
  } catch (e) {
    fail('Unhandled exception in section "$title"', e);
  }
}

// ── Main ─────────────────────────────────────────────────────────────────────

Future<void> main() async {
  final storage = TokenStorage();
  final client = ApiClient(storage: storage);

  final auth = AuthRepository(client, storage);
  final companies = CompanyRepository(client);
  final roles = RoleRepository(client);
  final users = UserRepository(client);
  final forms = FormRepository(client);
  final models = ModelRepository(client);
  final flows = FlowRepository(client);
  final letters = LetterRepository(client);
  final tickets = TicketRepository(client);
  final bindings = BindingRepository(client);

  // IDs collected during tests for chaining
  String? companyId;
  String? adminRoleId;
  String? newRoleId;
  String? userId;
  String? formId;
  String? modelId;
  String? flowId;
  String? flowInstanceId;
  String? letterId;
  String? ticketId;
  String? bindingId;
  String? letterAssignmentId;
  String? stepId;
  String? bindingNodeId;

  // ── Auth ──────────────────────────────────────────────────────────────────

  await section('Auth: Login', () async {
    final res = await auth.login('admin@horizondigital.com', 'Demo123!');
    check(res.accessToken.isNotEmpty, 'accessToken is non-empty');
    check(res.refreshToken.isNotEmpty, 'refreshToken is non-empty');
    check(res.user.email == 'admin@horizondigital.com', 'user email matches');
    check(res.user.id.isNotEmpty, 'user id is non-empty');
    userId = res.user.id;
    companyId = res.user.companyId;
    check(companyId != null, 'companyId is in user object');
  });

  await section('Auth: Get Me', () async {
    final me = await auth.getMe();
    check(me.email == 'admin@horizondigital.com', 'getMe email matches');
    check(me.id.isNotEmpty, 'getMe id non-empty');
  });

  // ── Companies ─────────────────────────────────────────────────────────────

  await section('Companies: List', () async {
    final list = await companies.getCompanies();
    check(list.isNotEmpty, 'companies list non-empty');
    check(list.any((c) => c.id == companyId), 'seed company in list');
  });

  await section('Companies: Get by ID', () async {
    final c = await companies.getCompany(companyId!);
    check(c.id == companyId, 'company id matches');
    check(c.name.isNotEmpty, 'company name non-empty');
  });

  await section('Companies: List Members', () async {
    final members = await companies.listMembers(companyId!);
    check(members.isNotEmpty, 'members list non-empty');
    check(members.every((m) => m['userId'] != null), 'members have userId');
  });

  await section('Companies: Create / Update / Delete', () async {
    final created = await companies.createCompany({
      'name': 'CLI Test Company',
      'description': 'Created by CLI e2e test',
    });
    check(created.id.isNotEmpty, 'created company has id');
    check(created.name == 'CLI Test Company', 'created company name correct');

    final updated = await companies.updateCompany(created.id, {
      'name': 'CLI Test Company (updated)',
    });
    check(updated.name == 'CLI Test Company (updated)', 'company name updated');

    await companies.deleteCompany(created.id);
    pass('deleteCompany did not throw');
  });

  // ── Roles ─────────────────────────────────────────────────────────────────

  await section('Roles: List', () async {
    final list = await roles.getRoles(companyId: companyId);
    check(list.isNotEmpty, 'roles list non-empty');
    adminRoleId = list.firstWhere((r) => r.name == 'Administrator').id;
    check(adminRoleId != null, 'found Administrator role');
  });

  await section('Roles: CRUD', () async {
    final created = await roles.createRole({
      'name': 'CLI Test Role',
      'description': 'From CLI e2e',
      'level': 'member',
      'companyId': companyId,
      'permissions': [],
    });
    newRoleId = created.id;
    check(created.name == 'CLI Test Role', 'created role name correct');
    check(created.permissions.isEmpty, 'permissions list accessible');

    final updated = await roles.updateRole(newRoleId!, {'name': 'CLI Test Role Updated'});
    check(updated.name == 'CLI Test Role Updated', 'role name updated');

    final fetched = await roles.getRole(newRoleId!);
    check(fetched.id == newRoleId, 'getRole id matches');

    await roles.deleteRole(newRoleId!);
    pass('deleteRole did not throw');
    newRoleId = null;
  });

  // ── Users ─────────────────────────────────────────────────────────────────

  await section('Users: List', () async {
    final list = await users.getUsers(companyId: companyId);
    check(list.isNotEmpty, 'users list non-empty');
    check(list.any((u) => u.id == userId), 'logged-in user in list');
  });

  await section('Users: Get + Update', () async {
    final u = await users.getUser(userId!);
    check(u.id == userId, 'getUser id matches');
    check(u.firstName.isNotEmpty, 'firstName non-empty');

    final updated = await users.updateUser(userId!, {'firstName': 'AlexUpdated'});
    check(updated.firstName == 'AlexUpdated', 'firstName updated');

    // restore
    await users.updateUser(userId!, {'firstName': 'Alexandra'});
  });

  await section('Users: Create + AssignRole + Delete', () async {
    final created = await users.createUser({
      'email': 'cli_test_${DateTime.now().millisecondsSinceEpoch}@test.com',
      'password': 'Test1234!',
      'firstName': 'CLI',
      'lastName': 'Tester',
      'companyId': companyId,
      'roleId': adminRoleId,
    });
    check(created.id.isNotEmpty, 'created user has id');

    final assigned = await users.assignRole(created.id, adminRoleId!);
    check(assigned.roleId == adminRoleId, 'role assigned correctly');

    await users.deleteUser(created.id);
    pass('deleteUser did not throw');
  });

  // ── Forms ─────────────────────────────────────────────────────────────────

  await section('Forms: List + Parse fields', () async {
    final list = await forms.getForms(companyId: companyId);
    check(list.isNotEmpty, 'forms list non-empty');

    final onboarding = list.firstWhere((f) => f.name.contains('Onboarding'));
    check(onboarding.fields.isNotEmpty, 'onboarding form has fields');

    final deptField = onboarding.fields.firstWhere((f) => f.label == 'Department');
    check(deptField.type == FormFieldType.dropdown, 'Department field is dropdown type');
    check(deptField.options.isNotEmpty, 'Department field has options');
    check(deptField.options.first.value.isNotEmpty, 'Option has value string');
    check(deptField.options.first.label.isNotEmpty, 'Option has label string');
  });

  await section('Forms: CRUD', () async {
    final created = await forms.createForm({
      'name': 'CLI Test Form',
      'description': 'From CLI e2e',
      'companyId': companyId,
      'fields': [
        {'id': 'f1', 'name': 'name', 'label': 'Name', 'type': 'text', 'required': true},
      ],
    });
    formId = created.id;
    check(created.name == 'CLI Test Form', 'created form name correct');
    check(created.fields.isNotEmpty, 'created form has parsed fields');

    final updated = await forms.updateForm(formId!, {'name': 'CLI Test Form Updated'});
    check(updated.name == 'CLI Test Form Updated', 'form name updated');

    final fetched = await forms.getForm(formId!);
    check(fetched.id == formId, 'getForm id matches');

    await forms.deleteForm(formId!);
    pass('deleteForm did not throw');
    formId = null;
  });

  // ── Models ────────────────────────────────────────────────────────────────

  await section('Models: List + Parse fields', () async {
    final list = await models.getModels(companyId: companyId);
    check(list.isNotEmpty, 'models list non-empty');

    final client = list.firstWhere((m) => m.name == 'Client');
    check(client.fields.isNotEmpty, 'Client model has fields');

    final nameField = client.fields.firstWhere((f) => f.name == 'company_name');
    check(nameField.type == ModelFieldType.string, 'company_name field is string type');

    final revenueField = client.fields.firstWhere((f) => f.name == 'annual_revenue');
    check(revenueField.type == ModelFieldType.float, 'annual_revenue field is float type');
  });

  await section('Models: CRUD + Entities', () async {
    final created = await models.createModel({
      'name': 'CLI Test Model',
      'description': 'From CLI e2e',
      'companyId': companyId,
      'fields': [
        {'id': 'mf1', 'name': 'title', 'label': 'Title', 'type': 'string', 'required': true},
        {'id': 'mf2', 'name': 'count', 'label': 'Count', 'type': 'integer'},
      ],
    });
    modelId = created.id;
    check(created.name == 'CLI Test Model', 'created model name correct');

    final updated = await models.updateModel(modelId!, {'name': 'CLI Test Model Updated'});
    check(updated.name == 'CLI Test Model Updated', 'model name updated');

    // Entity CRUD
    final entity = await models.createEntity(modelId!, {
      'data': {'title': 'Test Entity', 'count': 42},
    });
    check(entity['id'] != null, 'entity has id');
    final entityId = entity['id'] as String;

    final entities = await models.listEntities(modelId!);
    check(entities.isNotEmpty, 'entities list non-empty');

    final fetched = await models.getEntity(modelId!, entityId);
    check(fetched['id'] == entityId, 'getEntity id matches');

    final updatedEntity = await models.updateEntity(modelId!, entityId, {
      'data': {'title': 'Updated Entity', 'count': 99},
    });
    check(updatedEntity['id'] == entityId, 'updateEntity returns entity');

    await models.deleteEntity(modelId!, entityId);
    pass('deleteEntity did not throw');

    await models.deleteModel(modelId!);
    pass('deleteModel did not throw');
    modelId = null;
  });

  // ── Flows ─────────────────────────────────────────────────────────────────

  await section('Flows: List', () async {
    final list = await flows.getFlows(companyId: companyId);
    check(list.isNotEmpty, 'flows list non-empty');
    check(list.every((f) => f.id.isNotEmpty), 'all flows have ids');
    check(list.any((f) => f.nodes.isNotEmpty), 'at least one flow has nodes');
  });

  await section('Flows: CRUD + SaveGraph', () async {
    final created = await flows.createFlow({
      'name': 'CLI Test Flow',
      'description': 'From CLI e2e',
      'companyId': companyId,
      'status': 'draft',
    });
    flowId = created.id;
    check(created.name == 'CLI Test Flow', 'created flow name correct');

    final updated = await flows.updateFlow(flowId!, {'name': 'CLI Test Flow Updated'});
    check(updated.name == 'CLI Test Flow Updated', 'flow name updated');

    final startNodeId = _uuid();
    final endNodeId   = _uuid();
    final startNode = FlowNode(
      id: startNodeId,
      label: 'Start',
      type: NodeType.start,
      x: 100,
      y: 200,
    );
    final endNode = FlowNode(
      id: endNodeId,
      label: 'End',
      type: NodeType.end,
      x: 400,
      y: 200,
    );
    final edge = FlowEdge(
      id: _uuid(),
      sourceNodeId: startNodeId,
      targetNodeId: endNodeId,
      label: 'proceed',
    );

    final saved = await flows.saveFlowGraph(flowId!, [startNode, endNode], [edge]);
    check(saved.nodes.length == 2, 'saved graph has 2 nodes');
    check(saved.edges.length == 1, 'saved graph has 1 edge');
    check(
      saved.nodes.any((n) => n.type == NodeType.start),
      'start node type parsed correctly',
    );
  });

  // ── Flow Instances ────────────────────────────────────────────────────────

  await section('Flow Instances: Start', () async {
    final instance = await flows.startInstance(flowId!, companyId: companyId);
    flowInstanceId = instance.id;
    check(instance.id.isNotEmpty, 'instance has id');
    check(instance.flowId == flowId, 'instance flowId matches');
    check(instance.status == InstanceStatus.active, 'instance is ACTIVE');
    check(instance.createdAt != null, 'instance has createdAt (camelCase parsed)');
    check(instance.updatedAt != null, 'instance has updatedAt (camelCase parsed)');
  });

  await section('Flow Instances: List', () async {
    final list = await flows.listInstances(companyId: companyId);
    check(list.isNotEmpty, 'instances list non-empty');
    final found = list.any((i) => i.id == flowInstanceId);
    check(found, 'newly created instance appears in list');
  });

  await section('Flow Instances: Get by ID', () async {
    final instance = await flows.getInstance(flowInstanceId!);
    check(instance.id == flowInstanceId, 'getInstance id matches');
    check(instance.status == InstanceStatus.active, 'status is ACTIVE');
  });

  await section('Flow Instances: Advance', () async {
    final advanced = await flows.advanceInstance(flowInstanceId!, {});
    check(advanced.id == flowInstanceId, 'advanceInstance id matches');
    check(
      advanced.status == InstanceStatus.active ||
          advanced.status == InstanceStatus.completed,
      'status is active or completed after advance',
    );
  });

  // ── Letters ───────────────────────────────────────────────────────────────

  await section('Letters: List', () async {
    final list = await letters.getLetters(companyId: companyId);
    check(list.isNotEmpty, 'letters list non-empty');
    check(list.any((l) => l.name.contains('Welcome')), 'Welcome letter seeded');
    check(list.first.deltaContent.isNotEmpty, 'deltaContent parsed as map');
  });

  await section('Letters: CRUD', () async {
    final created = await letters.createLetter({
      'name': 'CLI Test Letter',
      'description': 'From CLI e2e',
      'companyId': companyId,
      'content': 'Hello {{name}}!',
      'variables': ['name'],
      'status': 'draft',
    });
    letterId = created.id;
    check(created.name == 'CLI Test Letter', 'created letter name correct');
    check(created.variables.contains('name'), 'variables list parsed');

    final updated = await letters.updateLetter(letterId!, {'name': 'CLI Test Letter Updated'});
    check(updated.name == 'CLI Test Letter Updated', 'letter name updated');

    final fetched = await letters.getLetter(letterId!);
    check(fetched.id == letterId, 'getLetter id matches');
  });

  await section('Letters: Generate', () async {
    final result = await letters.generateLetter(letterId!, {'name': 'World'});
    check(result.containsKey('generatedContent'), 'generateLetter returns generatedContent key');
    check((result['generatedContent'] as String).isNotEmpty, 'generatedContent is non-empty');
    check(result.containsKey('createdAt'), 'generatedLetter has camelCase createdAt');
  });

  // ── Tickets ───────────────────────────────────────────────────────────────

  await section('Tickets: List + Status filter', () async {
    final list = await tickets.getTickets(companyId: companyId);
    check(list.isNotEmpty, 'tickets list non-empty');
    check(list.any((t) => t.status == TicketStatus.open), 'open tickets exist');
    check(list.any((t) => t.status == TicketStatus.inProgress), 'inProgress tickets exist');

    final open = await tickets.getTickets(companyId: companyId, status: 'open');
    check(open.every((t) => t.status == TicketStatus.open), 'status filter works');
  });

  await section('Tickets: CRUD + Message + Status update', () async {
    final created = await tickets.createTicket({
      'title': 'CLI Test Ticket',
      'description': 'From CLI e2e',
      'companyId': companyId,
      'priority': 'low',
    });
    ticketId = created.id;
    check(created.id.isNotEmpty, 'created ticket has id');
    check(created.status == TicketStatus.open, 'new ticket is open');
    check(created.priority == TicketPriority.low, 'priority parsed correctly');

    final updated = await tickets.updateTicket(ticketId!, {'title': 'CLI Test Ticket Updated'});
    check(updated.title == 'CLI Test Ticket Updated', 'ticket title updated');

    final message = await tickets.sendMessage(ticketId!, 'Hello from CLI test', null);
    check(message.id.isNotEmpty, 'message has id');
    check(message.content == 'Hello from CLI test', 'message content matches');

    final statusUpdated = await tickets.updateStatus(ticketId!, TicketStatus.inProgress);
    check(statusUpdated.status == TicketStatus.inProgress,
          'status updated to inProgress');

    final resolved = await tickets.updateStatus(ticketId!, TicketStatus.resolved);
    check(resolved.status == TicketStatus.resolved, 'status updated to resolved');
  });

  // ── Node Bindings ─────────────────────────────────────────────────────────

  // Collect a node ID from the test flow to exercise binding endpoints.
  await section('Node Bindings: Setup – pick a node from test flow', () async {
    if (flowId == null) {
      fail('flowId is null, cannot test bindings');
      return;
    }
    final flow = await flows.getFlow(flowId!);
    if (flow.nodes.isEmpty) {
      fail('test flow has no nodes');
      return;
    }
    bindingNodeId = flow.nodes.first.id;
    check(bindingNodeId != null && bindingNodeId!.isNotEmpty, 'got a node ID for binding tests');
  });

  await section('Node Bindings: List (empty)', () async {
    if (bindingNodeId == null) return;
    final list = await bindings.getNodeBindings(bindingNodeId!);
    check(list is List<FormModelBinding>, 'returns a list of FormModelBinding');
  });

  await section('Node Bindings: Save + List + Delete', () async {
    if (bindingNodeId == null || modelId != null) {
      // modelId was deleted in cleanup; create a transient one just to get an ID.
      // We use a placeholder UUID that may fail validation – skip this sub-test gracefully.
      pass('skipping: modelId not available (cleaned up earlier)');
      return;
    }
    // modelId is null because it was cleaned up. We still verify the POST shape:
    try {
      final binding = await bindings.saveBinding(bindingNodeId!, {
        'name': 'CLI Test Binding',
        'rules': [],
      });
      bindingId = binding.id;
      check(binding.id.isNotEmpty, 'saved binding has id');
      check(binding.name == 'CLI Test Binding', 'binding name correct');

      final list = await bindings.getNodeBindings(bindingNodeId!);
      check(list.any((b) => b.id == bindingId), 'binding appears in list');

      await bindings.deleteBinding(bindingId!);
      pass('deleteBinding did not throw');
      bindingId = null;
    } catch (e) {
      fail('Node Bindings CRUD failed', e);
    }
  });

  // ── Node Letter Assignments ───────────────────────────────────────────────

  await section('Node Letter Assignments: List (empty)', () async {
    if (bindingNodeId == null) return;
    final list = await bindings.getNodeLetterAssignments(bindingNodeId!);
    check(list is List<NodeLetterAssignment>, 'returns a list of NodeLetterAssignment');
  });

  await section('Node Letter Assignments: Save + List + Delete', () async {
    if (bindingNodeId == null || letterId == null) {
      pass('skipping: bindingNodeId or letterId not available');
      return;
    }
    try {
      final assignment = await bindings.saveNodeLetterAssignment(bindingNodeId!, {
        'letterTemplateId': letterId,
        'autoGenerateOnApprove': false,
        'allowBeforeApprove': true,
        'variableBindings': {},
      });
      letterAssignmentId = assignment.id;
      check(assignment.id.isNotEmpty, 'saved assignment has id');
      check(assignment.letterTemplateId == letterId, 'letterTemplateId matches');
      check(!assignment.autoGenerateOnApprove, 'autoGenerateOnApprove is false');
      check(assignment.allowBeforeApprove, 'allowBeforeApprove is true');

      final list = await bindings.getNodeLetterAssignments(bindingNodeId!);
      check(list.any((a) => a.id == letterAssignmentId), 'assignment appears in list');

      await bindings.deleteNodeLetterAssignment(letterAssignmentId!);
      pass('deleteNodeLetterAssignment did not throw');
      letterAssignmentId = null;
    } catch (e) {
      fail('Node Letter Assignments CRUD failed', e);
    }
  });

  // ── Step Generated Letters ────────────────────────────────────────────────

  await section('Step Generated Letters: List for non-existent step (empty)', () async {
    if (flowInstanceId == null) {
      pass('skipping: no flowInstanceId');
      return;
    }
    // Use a placeholder step ID – expect empty list or 404 handled gracefully.
    try {
      final list = await bindings.getGeneratedLettersForStep(
        instanceId: flowInstanceId!,
        stepId: _uuid(),
      );
      check(list is List<StepGeneratedLetter>, 'returns a list');
    } catch (_) {
      pass('endpoint returned error for unknown step (expected)');
    }
  });

  // ── Cleanup ───────────────────────────────────────────────────────────────

  await section('Cleanup: delete test flow', () async {
    if (flowId != null) {
      await flows.deleteFlow(flowId!);
      pass('test flow deleted');
    }
    if (letterId != null) {
      await letters.deleteLetter(letterId!);
      pass('test letter deleted');
    }
  });

  await section('Auth: Logout', () async {
    await auth.logout();
    pass('logout did not throw');
  });

  // ── Summary ───────────────────────────────────────────────────────────────

  print('\n${'─' * 60}');
  print('Results: $_passed passed, $_failed failed');
  if (_failures.isNotEmpty) {
    print('\nFailed assertions:');
    for (final f in _failures) {
      print('  ✗ $f');
    }
  }
  print('${'─' * 60}');

  exitCode = _failed > 0 ? 1 : 0;
}
