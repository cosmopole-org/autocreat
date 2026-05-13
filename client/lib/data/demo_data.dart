// ignore_for_file: prefer_single_quotes
/// All static demo data for client-side demo mode.
/// Every field matches the shape expected by the corresponding
/// `fromJson` factory on the real model classes.
library demo_data;

class DemoData {
  DemoData._();

  // ──────────────────────────────────────────────────────────────
  // IDs
  // ──────────────────────────────────────────────────────────────

  static const String companyId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

  static const String _uid0 = 'd0e1f2a3-b4c5-d6e7-f8a9-b0c1d2e3f4a5'; // demo
  static const String _uid1 = 'u0000001-0000-0000-0000-000000000001'; // alexandra
  static const String _uid2 = 'u0000002-0000-0000-0000-000000000002'; // marcus
  static const String _uid3 = 'u0000003-0000-0000-0000-000000000003'; // sofia
  static const String _uid4 = 'u0000004-0000-0000-0000-000000000004'; // james
  static const String _uid5 = 'u0000005-0000-0000-0000-000000000005'; // emily

  static const String _rid1 = 'r0000001-0000-0000-0000-000000000001'; // admin
  static const String _rid2 = 'r0000002-0000-0000-0000-000000000002'; // ops
  static const String _rid3 = 'r0000003-0000-0000-0000-000000000003'; // support
  static const String _rid4 = 'r0000004-0000-0000-0000-000000000004'; // dev
  static const String _rid5 = 'r0000005-0000-0000-0000-000000000005'; // viewer

  static const String _flo1 = 'f0000001-0000-0000-0000-000000000001';
  static const String _flo2 = 'f0000002-0000-0000-0000-000000000002';
  static const String _flo3 = 'f0000003-0000-0000-0000-000000000003';

  static const String _frm1 = 'fm000001-0000-0000-0000-000000000001';
  static const String _frm2 = 'fm000002-0000-0000-0000-000000000002';
  static const String _frm3 = 'fm000003-0000-0000-0000-000000000003';
  static const String _frm4 = 'fm000004-0000-0000-0000-000000000004';

  static const String _let1 = 'lt000001-0000-0000-0000-000000000001';
  static const String _let2 = 'lt000002-0000-0000-0000-000000000002';
  static const String _let3 = 'lt000003-0000-0000-0000-000000000003';

  static const String _mod1 = 'md000001-0000-0000-0000-000000000001';
  static const String _mod2 = 'md000002-0000-0000-0000-000000000002';

  static const String _tkt1 = 'tk000001-0000-0000-0000-000000000001';
  static const String _tkt2 = 'tk000002-0000-0000-0000-000000000002';
  static const String _tkt3 = 'tk000003-0000-0000-0000-000000000003';
  static const String _tkt4 = 'tk000004-0000-0000-0000-000000000004';
  static const String _tkt5 = 'tk000005-0000-0000-0000-000000000005';
  static const String _tkt6 = 'tk000006-0000-0000-0000-000000000006';
  static const String _tkt7 = 'tk000007-0000-0000-0000-000000000007';
  static const String _tkt8 = 'tk000008-0000-0000-0000-000000000008';

  static const String _ins1 = 'in000001-0000-0000-0000-000000000001';
  static const String _ins2 = 'in000002-0000-0000-0000-000000000002';
  static const String _ins3 = 'in000003-0000-0000-0000-000000000003';

  // ──────────────────────────────────────────────────────────────
  // COMPANY
  // ──────────────────────────────────────────────────────────────

  static final Map<String, dynamic> company = {
    'id': companyId,
    'name': 'Horizon Digital Agency',
    'description':
        'Full-service digital transformation agency helping businesses modernise their operations and customer journeys.',
    'website': 'https://horizondigital.io',
    'industry': 'Technology',
    'logo': '',
    'ownerId': _uid1,
    'status': 'active',
    'memberCount': 6,
    'flowCount': 3,
    'createdAt': '2026-01-10T08:00:00.000Z',
    'updatedAt': '2026-04-28T14:22:00.000Z',
  };

  // ──────────────────────────────────────────────────────────────
  // CURRENT / DEMO USER
  // ──────────────────────────────────────────────────────────────

  static final Map<String, dynamic> currentUser = {
    'id': _uid0,
    'email': 'demo@autocreat.io',
    'firstName': 'Demo',
    'lastName': 'User',
    'avatar': '',
    'phone': '+1 555 000 0000',
    'role': 'admin',
    'isActive': true,
    'companyId': companyId,
    'roleId': _rid1,
    'permissions': <String>[],
    'createdAt': '2026-02-01T09:00:00.000Z',
    'updatedAt': '2026-04-30T10:00:00.000Z',
  };

  // ──────────────────────────────────────────────────────────────
  // DASHBOARD STATS
  // ──────────────────────────────────────────────────────────────

  static final Map<String, dynamic> stats = {
    'total_users': 6,
    'total_flows': 3,
    'active_instances': 2,
    'total_tickets': 8,
    'open_tickets': 3,
    'total_forms': 4,
    'total_models': 2,
    'total_letter_templates': 3,
  };

  // ──────────────────────────────────────────────────────────────
  // USERS  (6)
  // ──────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> users = [
    {
      'id': _uid1,
      'email': 'alexandra.chen@horizondigital.io',
      'firstName': 'Alexandra',
      'lastName': 'Chen',
      'avatar': '',
      'phone': '+1 415 555 0101',
      'role': 'owner',
      'isActive': true,
      'companyId': companyId,
      'roleId': _rid1,
      'permissions': <String>[],
      'createdAt': '2026-01-10T08:05:00.000Z',
      'updatedAt': '2026-04-15T11:30:00.000Z',
    },
    {
      'id': _uid2,
      'email': 'marcus.thompson@horizondigital.io',
      'firstName': 'Marcus',
      'lastName': 'Thompson',
      'avatar': '',
      'phone': '+1 415 555 0202',
      'role': 'member',
      'isActive': true,
      'companyId': companyId,
      'roleId': _rid2,
      'permissions': <String>[],
      'createdAt': '2026-01-15T09:30:00.000Z',
      'updatedAt': '2026-04-10T16:00:00.000Z',
    },
    {
      'id': _uid3,
      'email': 'sofia.rodriguez@horizondigital.io',
      'firstName': 'Sofia',
      'lastName': 'Rodriguez',
      'avatar': '',
      'phone': '+1 415 555 0303',
      'role': 'member',
      'isActive': true,
      'companyId': companyId,
      'roleId': _rid3,
      'permissions': <String>[],
      'createdAt': '2026-01-22T10:00:00.000Z',
      'updatedAt': '2026-03-28T09:15:00.000Z',
    },
    {
      'id': _uid4,
      'email': 'james.park@horizondigital.io',
      'firstName': 'James',
      'lastName': 'Park',
      'avatar': '',
      'phone': '+1 415 555 0404',
      'role': 'member',
      'isActive': true,
      'companyId': companyId,
      'roleId': _rid4,
      'permissions': <String>[],
      'createdAt': '2026-02-03T11:00:00.000Z',
      'updatedAt': '2026-04-20T14:45:00.000Z',
    },
    {
      'id': _uid5,
      'email': 'emily.watson@horizondigital.io',
      'firstName': 'Emily',
      'lastName': 'Watson',
      'avatar': '',
      'phone': '+1 415 555 0505',
      'role': 'member',
      'isActive': true,
      'companyId': companyId,
      'roleId': _rid3,
      'permissions': <String>[],
      'createdAt': '2026-02-14T08:30:00.000Z',
      'updatedAt': '2026-04-22T10:20:00.000Z',
    },
    {
      'id': _uid0,
      'email': 'demo@autocreat.io',
      'firstName': 'Demo',
      'lastName': 'User',
      'avatar': '',
      'phone': '+1 555 000 0000',
      'role': 'admin',
      'isActive': true,
      'companyId': companyId,
      'roleId': _rid1,
      'permissions': <String>[],
      'createdAt': '2026-02-01T09:00:00.000Z',
      'updatedAt': '2026-04-30T10:00:00.000Z',
    },
  ];

  // ──────────────────────────────────────────────────────────────
  // ROLES  (5)
  // Permission shape matches Permission.fromJson:
  //   resource, canCreate, canRead, canUpdate, canDelete, customActions
  // ──────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _makePermissions({
    required bool admin,
  }) {
    final resources = [
      'companies',
      'flows',
      'forms',
      'tickets',
      'users',
      'roles',
      'letters',
      'models',
      'instances',
    ];
    return resources
        .map((r) => <String, dynamic>{
              'resource': r,
              'canCreate': admin,
              'canRead': true,
              'canUpdate': admin,
              'canDelete': admin,
              'customActions': <String>[],
            })
        .toList();
  }

  static List<Map<String, dynamic>> _opsPermissions() {
    final full = ['flows', 'forms', 'instances', 'tickets'];
    final read = ['companies', 'users', 'roles', 'letters', 'models'];
    return [
      ...full.map((r) => <String, dynamic>{
            'resource': r,
            'canCreate': true,
            'canRead': true,
            'canUpdate': true,
            'canDelete': false,
            'customActions': <String>[],
          }),
      ...read.map((r) => <String, dynamic>{
            'resource': r,
            'canCreate': false,
            'canRead': true,
            'canUpdate': false,
            'canDelete': false,
            'customActions': <String>[],
          }),
    ];
  }

  static List<Map<String, dynamic>> _supportPermissions() {
    return [
      {
        'resource': 'tickets',
        'canCreate': true,
        'canRead': true,
        'canUpdate': true,
        'canDelete': false,
        'customActions': <String>['assign', 'resolve'],
      },
      {
        'resource': 'users',
        'canCreate': false,
        'canRead': true,
        'canUpdate': false,
        'canDelete': false,
        'customActions': <String>[],
      },
      {
        'resource': 'flows',
        'canCreate': false,
        'canRead': true,
        'canUpdate': false,
        'canDelete': false,
        'customActions': <String>[],
      },
    ];
  }

  static List<Map<String, dynamic>> _devPermissions() {
    final full = ['flows', 'forms', 'models', 'letters'];
    final read = ['companies', 'users', 'roles', 'tickets', 'instances'];
    return [
      ...full.map((r) => <String, dynamic>{
            'resource': r,
            'canCreate': true,
            'canRead': true,
            'canUpdate': true,
            'canDelete': true,
            'customActions': <String>[],
          }),
      ...read.map((r) => <String, dynamic>{
            'resource': r,
            'canCreate': false,
            'canRead': true,
            'canUpdate': false,
            'canDelete': false,
            'customActions': <String>[],
          }),
    ];
  }

  static final List<Map<String, dynamic>> roles = [
    {
      'id': _rid1,
      'name': 'Administrator',
      'description':
          'Full access to all resources and settings within the organisation.',
      'companyId': companyId,
      'level': 'admin',
      'permissions': _makePermissions(admin: true),
      'ruleSets': <Map<String, dynamic>>[],
      'isActive': true,
      'memberCount': 2,
      'createdAt': '2026-01-10T08:10:00.000Z',
      'updatedAt': '2026-04-01T12:00:00.000Z',
    },
    {
      'id': _rid2,
      'name': 'Operations Manager',
      'description':
          'Manages flows, forms, tickets, and instances. Read-only access to users and roles.',
      'companyId': companyId,
      'level': 'manager',
      'permissions': _opsPermissions(),
      'ruleSets': <Map<String, dynamic>>[],
      'isActive': true,
      'memberCount': 1,
      'createdAt': '2026-01-10T08:15:00.000Z',
      'updatedAt': '2026-03-15T09:30:00.000Z',
    },
    {
      'id': _rid3,
      'name': 'Support Agent',
      'description':
          'Create, update and resolve support tickets. View users and flows.',
      'companyId': companyId,
      'level': 'member',
      'permissions': _supportPermissions(),
      'ruleSets': <Map<String, dynamic>>[],
      'isActive': true,
      'memberCount': 2,
      'createdAt': '2026-01-10T08:20:00.000Z',
      'updatedAt': '2026-03-20T14:00:00.000Z',
    },
    {
      'id': _rid4,
      'name': 'Developer',
      'description':
          'Full CRUD on flows, forms, models, and letter templates. Read-only on everything else.',
      'companyId': companyId,
      'level': 'member',
      'permissions': _devPermissions(),
      'ruleSets': <Map<String, dynamic>>[],
      'isActive': true,
      'memberCount': 1,
      'createdAt': '2026-01-12T10:00:00.000Z',
      'updatedAt': '2026-04-05T16:45:00.000Z',
    },
    {
      'id': _rid5,
      'name': 'Viewer',
      'description': 'Read-only access to all non-sensitive resources.',
      'companyId': companyId,
      'level': 'viewer',
      'permissions': _makePermissions(admin: false),
      'ruleSets': <Map<String, dynamic>>[],
      'isActive': true,
      'memberCount': 0,
      'createdAt': '2026-01-15T11:00:00.000Z',
      'updatedAt': '2026-02-01T10:00:00.000Z',
    },
  ];

  // ──────────────────────────────────────────────────────────────
  // FLOWS  (3)
  // Shape matches Flow.fromJson
  // ──────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> flows = [
    {
      'id': _flo1,
      'name': 'Client Onboarding',
      'description':
          'End-to-end onboarding pipeline: intake form → contract signing → kickoff scheduling → welcome letter.',
      'companyId': companyId,
      'status': 'active',
      'nodes': [
        {
          'id': 'n001',
          'label': 'Start',
          'type': 'start',
          'x': 80.0,
          'y': 200.0,
          'width': 140.0,
          'height': 60.0,
          'branches': <Map<String, dynamic>>[],
        },
        {
          'id': 'n002',
          'label': 'Intake Form',
          'type': 'step',
          'x': 280.0,
          'y': 200.0,
          'width': 160.0,
          'height': 60.0,
          'assignedRoleId': _rid3,
          'assignedFormId': _frm1,
          'branches': <Map<String, dynamic>>[],
        },
        {
          'id': 'n003',
          'label': 'Approval?',
          'type': 'decision',
          'x': 500.0,
          'y': 200.0,
          'width': 160.0,
          'height': 60.0,
          'branches': [
            {'id': 'b001', 'label': 'Approved', 'condition': 'approved == true', 'targetNodeId': 'n004', 'isDefault': false},
            {'id': 'b002', 'label': 'Rejected', 'condition': 'approved == false', 'targetNodeId': 'n005', 'isDefault': true},
          ],
        },
        {
          'id': 'n004',
          'label': 'Send Welcome Letter',
          'type': 'step',
          'x': 720.0,
          'y': 140.0,
          'width': 180.0,
          'height': 60.0,
          'assignedRoleId': _rid2,
          'branches': <Map<String, dynamic>>[],
        },
        {
          'id': 'n005',
          'label': 'End',
          'type': 'end',
          'x': 960.0,
          'y': 200.0,
          'width': 140.0,
          'height': 60.0,
          'branches': <Map<String, dynamic>>[],
        },
      ],
      'edges': [
        {'id': 'e001', 'sourceNodeId': 'n001', 'targetNodeId': 'n002', 'label': null},
        {'id': 'e002', 'sourceNodeId': 'n002', 'targetNodeId': 'n003', 'label': null},
        {'id': 'e003', 'sourceNodeId': 'n003', 'targetNodeId': 'n004', 'label': 'Approved', 'conditionId': 'b001'},
        {'id': 'e004', 'sourceNodeId': 'n003', 'targetNodeId': 'n005', 'label': 'Rejected', 'conditionId': 'b002'},
        {'id': 'e005', 'sourceNodeId': 'n004', 'targetNodeId': 'n005', 'label': null},
      ],
      'settings': <String, dynamic>{},
      'createdAt': '2026-01-20T10:00:00.000Z',
      'updatedAt': '2026-04-18T15:30:00.000Z',
    },
    {
      'id': _flo2,
      'name': 'Bug Report Triage',
      'description':
          'Automated triage pipeline for incoming bug reports: classify → assign → resolve → close.',
      'companyId': companyId,
      'status': 'active',
      'nodes': [
        {
          'id': 'n101',
          'label': 'Start',
          'type': 'start',
          'x': 80.0,
          'y': 150.0,
          'width': 140.0,
          'height': 60.0,
          'branches': <Map<String, dynamic>>[],
        },
        {
          'id': 'n102',
          'label': 'Bug Report Form',
          'type': 'step',
          'x': 280.0,
          'y': 150.0,
          'width': 180.0,
          'height': 60.0,
          'assignedFormId': _frm2,
          'branches': <Map<String, dynamic>>[],
        },
        {
          'id': 'n103',
          'label': 'Severity Check',
          'type': 'decision',
          'x': 520.0,
          'y': 150.0,
          'width': 160.0,
          'height': 60.0,
          'branches': [
            {'id': 'b101', 'label': 'Critical', 'condition': 'severity == "critical"', 'targetNodeId': 'n104', 'isDefault': false},
            {'id': 'b102', 'label': 'Normal', 'condition': null, 'targetNodeId': 'n105', 'isDefault': true},
          ],
        },
        {
          'id': 'n104',
          'label': 'Escalate to Dev Lead',
          'type': 'step',
          'x': 740.0,
          'y': 80.0,
          'width': 200.0,
          'height': 60.0,
          'assignedRoleId': _rid4,
          'branches': <Map<String, dynamic>>[],
        },
        {
          'id': 'n105',
          'label': 'Assign to Developer',
          'type': 'step',
          'x': 740.0,
          'y': 220.0,
          'width': 200.0,
          'height': 60.0,
          'assignedRoleId': _rid4,
          'branches': <Map<String, dynamic>>[],
        },
        {
          'id': 'n106',
          'label': 'End',
          'type': 'end',
          'x': 1000.0,
          'y': 150.0,
          'width': 140.0,
          'height': 60.0,
          'branches': <Map<String, dynamic>>[],
        },
      ],
      'edges': [
        {'id': 'e101', 'sourceNodeId': 'n101', 'targetNodeId': 'n102'},
        {'id': 'e102', 'sourceNodeId': 'n102', 'targetNodeId': 'n103'},
        {'id': 'e103', 'sourceNodeId': 'n103', 'targetNodeId': 'n104', 'label': 'Critical', 'conditionId': 'b101'},
        {'id': 'e104', 'sourceNodeId': 'n103', 'targetNodeId': 'n105', 'label': 'Normal', 'conditionId': 'b102'},
        {'id': 'e105', 'sourceNodeId': 'n104', 'targetNodeId': 'n106'},
        {'id': 'e106', 'sourceNodeId': 'n105', 'targetNodeId': 'n106'},
      ],
      'settings': <String, dynamic>{},
      'createdAt': '2026-02-05T11:00:00.000Z',
      'updatedAt': '2026-04-25T09:00:00.000Z',
    },
    {
      'id': _flo3,
      'name': 'Employee Leave Request',
      'description':
          'HR leave-request flow with manager approval and automated notification letters.',
      'companyId': companyId,
      'status': 'draft',
      'nodes': [
        {
          'id': 'n201',
          'label': 'Start',
          'type': 'start',
          'x': 80.0,
          'y': 180.0,
          'width': 140.0,
          'height': 60.0,
          'branches': <Map<String, dynamic>>[],
        },
        {
          'id': 'n202',
          'label': 'Leave Request Form',
          'type': 'step',
          'x': 280.0,
          'y': 180.0,
          'width': 190.0,
          'height': 60.0,
          'assignedFormId': _frm3,
          'branches': <Map<String, dynamic>>[],
        },
        {
          'id': 'n203',
          'label': 'Manager Approval',
          'type': 'decision',
          'x': 530.0,
          'y': 180.0,
          'width': 180.0,
          'height': 60.0,
          'assignedRoleId': _rid2,
          'branches': [
            {'id': 'b201', 'label': 'Approved', 'condition': 'approved == true', 'targetNodeId': 'n204', 'isDefault': false},
            {'id': 'b202', 'label': 'Denied', 'condition': 'approved == false', 'targetNodeId': 'n205', 'isDefault': true},
          ],
        },
        {
          'id': 'n204',
          'label': 'Send Approval Letter',
          'type': 'step',
          'x': 780.0,
          'y': 110.0,
          'width': 200.0,
          'height': 60.0,
          'branches': <Map<String, dynamic>>[],
        },
        {
          'id': 'n205',
          'label': 'Send Denial Letter',
          'type': 'step',
          'x': 780.0,
          'y': 250.0,
          'width': 200.0,
          'height': 60.0,
          'branches': <Map<String, dynamic>>[],
        },
        {
          'id': 'n206',
          'label': 'End',
          'type': 'end',
          'x': 1050.0,
          'y': 180.0,
          'width': 140.0,
          'height': 60.0,
          'branches': <Map<String, dynamic>>[],
        },
      ],
      'edges': [
        {'id': 'e201', 'sourceNodeId': 'n201', 'targetNodeId': 'n202'},
        {'id': 'e202', 'sourceNodeId': 'n202', 'targetNodeId': 'n203'},
        {'id': 'e203', 'sourceNodeId': 'n203', 'targetNodeId': 'n204', 'label': 'Approved', 'conditionId': 'b201'},
        {'id': 'e204', 'sourceNodeId': 'n203', 'targetNodeId': 'n205', 'label': 'Denied', 'conditionId': 'b202'},
        {'id': 'e205', 'sourceNodeId': 'n204', 'targetNodeId': 'n206'},
        {'id': 'e206', 'sourceNodeId': 'n205', 'targetNodeId': 'n206'},
      ],
      'settings': <String, dynamic>{},
      'createdAt': '2026-03-10T14:00:00.000Z',
      'updatedAt': '2026-04-30T08:45:00.000Z',
    },
  ];

  // ──────────────────────────────────────────────────────────────
  // FORMS  (4)
  // Shape matches FormDefinition.fromJson
  // ──────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> forms = [
    {
      'id': _frm1,
      'name': 'Client Intake Form',
      'description': 'Collects new client contact details, project scope, and budget range during the onboarding flow.',
      'companyId': companyId,
      'modelId': _mod1,
      'status': 'active',
      'fields': [
        {
          'id': 'ff0101',
          'type': 'text',
          'label': 'Company Name',
          'placeholder': 'Acme Corp',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 1,
        },
        {
          'id': 'ff0102',
          'type': 'text',
          'label': 'Primary Contact',
          'placeholder': 'Full name',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 2,
        },
        {
          'id': 'ff0103',
          'type': 'text',
          'label': 'Email Address',
          'placeholder': 'contact@example.com',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'validation': {'isEmail': true},
          'options': <Map<String, dynamic>>[],
          'order': 3,
        },
        {
          'id': 'ff0104',
          'type': 'dropdown',
          'label': 'Project Type',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'options': [
            {'value': 'web_app', 'label': 'Web Application'},
            {'value': 'mobile_app', 'label': 'Mobile Application'},
            {'value': 'data_platform', 'label': 'Data Platform'},
            {'value': 'integration', 'label': 'Systems Integration'},
          ],
          'order': 4,
        },
        {
          'id': 'ff0105',
          'type': 'number',
          'label': 'Estimated Budget (USD)',
          'placeholder': '50000',
          'required': false,
          'readOnly': false,
          'hidden': false,
          'validation': {'min': 1000.0, 'max': 5000000.0},
          'options': <Map<String, dynamic>>[],
          'order': 5,
        },
        {
          'id': 'ff0106',
          'type': 'textarea',
          'label': 'Project Description',
          'placeholder': 'Describe the goals and requirements...',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 6,
        },
        {
          'id': 'ff0107',
          'type': 'date',
          'label': 'Desired Start Date',
          'required': false,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 7,
        },
      ],
      'createdAt': '2026-01-22T10:30:00.000Z',
      'updatedAt': '2026-04-10T11:00:00.000Z',
    },
    {
      'id': _frm2,
      'name': 'Bug Report Form',
      'description': 'Structured form for reporting software defects with severity, steps to reproduce, and attachments.',
      'companyId': companyId,
      'modelId': null,
      'status': 'active',
      'fields': [
        {
          'id': 'ff0201',
          'type': 'text',
          'label': 'Bug Title',
          'placeholder': 'Short summary of the issue',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'validation': {'maxLength': 120},
          'options': <Map<String, dynamic>>[],
          'order': 1,
        },
        {
          'id': 'ff0202',
          'type': 'dropdown',
          'label': 'Severity',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'options': [
            {'value': 'critical', 'label': 'Critical — system down'},
            {'value': 'high', 'label': 'High — major feature broken'},
            {'value': 'medium', 'label': 'Medium — degraded experience'},
            {'value': 'low', 'label': 'Low — cosmetic / minor'},
          ],
          'order': 2,
        },
        {
          'id': 'ff0203',
          'type': 'textarea',
          'label': 'Steps to Reproduce',
          'placeholder': '1. Navigate to...\n2. Click...',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 3,
        },
        {
          'id': 'ff0204',
          'type': 'textarea',
          'label': 'Expected Behaviour',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 4,
        },
        {
          'id': 'ff0205',
          'type': 'textarea',
          'label': 'Actual Behaviour',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 5,
        },
        {
          'id': 'ff0206',
          'type': 'file',
          'label': 'Screenshots / Logs',
          'required': false,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 6,
        },
      ],
      'createdAt': '2026-02-08T09:00:00.000Z',
      'updatedAt': '2026-04-20T13:30:00.000Z',
    },
    {
      'id': _frm3,
      'name': 'Employee Leave Request',
      'description': 'Annual, sick, and personal leave request form with date range and reason.',
      'companyId': companyId,
      'modelId': null,
      'status': 'active',
      'fields': [
        {
          'id': 'ff0301',
          'type': 'dropdown',
          'label': 'Leave Type',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'options': [
            {'value': 'annual', 'label': 'Annual Leave'},
            {'value': 'sick', 'label': 'Sick Leave'},
            {'value': 'personal', 'label': 'Personal Leave'},
            {'value': 'parental', 'label': 'Parental Leave'},
          ],
          'order': 1,
        },
        {
          'id': 'ff0302',
          'type': 'date',
          'label': 'Start Date',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 2,
        },
        {
          'id': 'ff0303',
          'type': 'date',
          'label': 'End Date',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 3,
        },
        {
          'id': 'ff0304',
          'type': 'textarea',
          'label': 'Reason',
          'placeholder': 'Optional additional details',
          'required': false,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 4,
        },
        {
          'id': 'ff0305',
          'type': 'switchField',
          'label': 'Cover Arranged',
          'defaultValue': false,
          'required': false,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 5,
        },
      ],
      'createdAt': '2026-03-12T10:00:00.000Z',
      'updatedAt': '2026-04-28T14:00:00.000Z',
    },
    {
      'id': _frm4,
      'name': 'Project Feedback Survey',
      'description': 'Post-delivery client satisfaction survey with NPS score, rating, and open comments.',
      'companyId': companyId,
      'modelId': null,
      'status': 'active',
      'fields': [
        {
          'id': 'ff0401',
          'type': 'rating',
          'label': 'Overall Satisfaction',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 1,
        },
        {
          'id': 'ff0402',
          'type': 'number',
          'label': 'Net Promoter Score (0–10)',
          'required': true,
          'readOnly': false,
          'hidden': false,
          'validation': {'min': 0.0, 'max': 10.0},
          'options': <Map<String, dynamic>>[],
          'order': 2,
        },
        {
          'id': 'ff0403',
          'type': 'multiselect',
          'label': 'What went well?',
          'required': false,
          'readOnly': false,
          'hidden': false,
          'options': [
            {'value': 'communication', 'label': 'Communication'},
            {'value': 'quality', 'label': 'Delivery Quality'},
            {'value': 'timeline', 'label': 'On-Time Delivery'},
            {'value': 'support', 'label': 'Post-Launch Support'},
            {'value': 'value', 'label': 'Value for Money'},
          ],
          'order': 3,
        },
        {
          'id': 'ff0404',
          'type': 'textarea',
          'label': 'Additional Comments',
          'placeholder': 'Any other feedback...',
          'required': false,
          'readOnly': false,
          'hidden': false,
          'options': <Map<String, dynamic>>[],
          'order': 4,
        },
      ],
      'createdAt': '2026-03-25T09:30:00.000Z',
      'updatedAt': '2026-05-01T10:00:00.000Z',
    },
  ];

  // ──────────────────────────────────────────────────────────────
  // LETTER TEMPLATES  (3)
  // Shape matches LetterTemplate.fromJson
  // ──────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> letters = [
    {
      'id': _let1,
      'name': 'Welcome Letter',
      'description': 'Sent to new clients after onboarding approval. Introduces the team and next steps.',
      'companyId': companyId,
      'content':
          'Dear {{client_name}},\n\nWelcome to Horizon Digital Agency! We are thrilled to have {{company_name}} as a new client.\n\n'
          'Your dedicated project manager is {{pm_name}}, who will be in touch within 24 hours to schedule your kickoff call.\n\n'
          'In the meantime, please find attached your signed contract and the project brief for your records.\n\n'
          'We look forward to delivering outstanding results together.\n\nWarm regards,\n{{sender_name}}\nHorizon Digital Agency',
      'deltaContent': <String, dynamic>{},
      'variables': ['client_name', 'company_name', 'pm_name', 'sender_name'],
      'status': 'active',
      'category': 'Onboarding',
      'createdAt': '2026-01-25T11:00:00.000Z',
      'updatedAt': '2026-04-12T09:00:00.000Z',
    },
    {
      'id': _let2,
      'name': 'Leave Approval Notice',
      'description': 'HR notification confirming an approved employee leave request.',
      'companyId': companyId,
      'content':
          'Dear {{employee_name}},\n\nThis letter confirms that your leave request has been approved.\n\n'
          'Leave Type: {{leave_type}}\nStart Date: {{start_date}}\nEnd Date: {{end_date}}\n\n'
          'Please ensure all pending tasks are handed over before your leave begins.\n\n'
          'Should you have any questions, please contact HR at hr@horizondigital.io.\n\n'
          'Best regards,\n{{manager_name}}\nHorizon Digital Agency — HR',
      'deltaContent': <String, dynamic>{},
      'variables': ['employee_name', 'leave_type', 'start_date', 'end_date', 'manager_name'],
      'status': 'active',
      'category': 'HR',
      'createdAt': '2026-02-20T14:00:00.000Z',
      'updatedAt': '2026-04-18T11:30:00.000Z',
    },
    {
      'id': _let3,
      'name': 'Project Completion Certificate',
      'description': 'Formal certificate issued to clients on successful project delivery.',
      'companyId': companyId,
      'content':
          'CERTIFICATE OF PROJECT COMPLETION\n\nThis is to certify that the project "{{project_name}}" commissioned by {{client_company}} '
          'has been successfully completed by Horizon Digital Agency on {{completion_date}}.\n\n'
          'Project Scope: {{project_scope}}\nDelivery Standard: {{standard}}\n\n'
          'All deliverables have been tested, accepted, and handed over as per the agreed specifications.\n\n'
          'Authorised by: {{authoriser_name}}\nDate: {{issue_date}}\n\nHorizon Digital Agency\nhttps://horizondigital.io',
      'deltaContent': <String, dynamic>{},
      'variables': ['project_name', 'client_company', 'completion_date', 'project_scope', 'standard', 'authoriser_name', 'issue_date'],
      'status': 'draft',
      'category': 'Delivery',
      'createdAt': '2026-03-30T10:00:00.000Z',
      'updatedAt': '2026-04-29T16:00:00.000Z',
    },
  ];

  // ──────────────────────────────────────────────────────────────
  // MODEL DEFINITIONS  (2)
  // Shape matches ModelDefinition.fromJson
  // ──────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> models = [
    {
      'id': _mod1,
      'name': 'Client',
      'description': 'Core entity representing an external client organisation.',
      'companyId': companyId,
      'fields': [
        {'id': 'mf0101', 'name': 'company_name', 'type': 'string', 'required': true, 'unique': false, 'order': 1},
        {'id': 'mf0102', 'name': 'primary_contact', 'type': 'string', 'required': true, 'unique': false, 'order': 2},
        {'id': 'mf0103', 'name': 'email', 'type': 'string', 'required': true, 'unique': true, 'order': 3},
        {'id': 'mf0104', 'name': 'phone', 'type': 'string', 'required': false, 'unique': false, 'order': 4},
        {'id': 'mf0105', 'name': 'industry', 'type': 'string', 'required': false, 'unique': false, 'order': 5},
        {'id': 'mf0106', 'name': 'contract_value', 'type': 'float', 'required': false, 'unique': false, 'order': 6},
        {'id': 'mf0107', 'name': 'onboarded_at', 'type': 'dateTime', 'required': false, 'unique': false, 'order': 7},
        {'id': 'mf0108', 'name': 'is_active', 'type': 'boolean', 'required': false, 'unique': false, 'defaultValue': true, 'order': 8},
      ],
      'createdAt': '2026-01-20T10:15:00.000Z',
      'updatedAt': '2026-04-10T12:00:00.000Z',
    },
    {
      'id': _mod2,
      'name': 'Project',
      'description': 'Tracks individual delivery projects linked to a client.',
      'companyId': companyId,
      'fields': [
        {'id': 'mf0201', 'name': 'project_name', 'type': 'string', 'required': true, 'unique': false, 'order': 1},
        {'id': 'mf0202', 'name': 'client_id', 'type': 'reference', 'required': true, 'unique': false, 'referenceModelId': _mod1, 'order': 2},
        {'id': 'mf0203', 'name': 'start_date', 'type': 'date', 'required': true, 'unique': false, 'order': 3},
        {'id': 'mf0204', 'name': 'end_date', 'type': 'date', 'required': false, 'unique': false, 'order': 4},
        {'id': 'mf0205', 'name': 'budget_usd', 'type': 'float', 'required': false, 'unique': false, 'order': 5},
        {'id': 'mf0206', 'name': 'status', 'type': 'string', 'required': true, 'unique': false, 'defaultValue': 'active', 'order': 6},
        {'id': 'mf0207', 'name': 'completed', 'type': 'boolean', 'required': false, 'unique': false, 'defaultValue': false, 'order': 7},
      ],
      'createdAt': '2026-02-01T09:00:00.000Z',
      'updatedAt': '2026-04-22T15:00:00.000Z',
    },
  ];

  // ──────────────────────────────────────────────────────────────
  // TICKETS  (8)
  // Shape matches Ticket.fromJson + TicketMessage.fromJson
  // Status enum values: open, inProgress, resolved, closed
  // Priority enum values: low, medium, high, urgent
  // ──────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> tickets = [
    {
      'id': _tkt1,
      'title': 'Login page crashes on iOS 17.4 Safari',
      'description':
          'Users on iPhone 15 running iOS 17.4 and using Safari cannot complete login — the page crashes after submitting credentials.',
      'companyId': companyId,
      'flowId': _flo2,
      'creatorId': _uid3,
      'creatorName': 'Sofia Rodriguez',
      'assigneeId': _uid4,
      'assigneeName': 'James Park',
      'status': 'inProgress',
      'priority': 'urgent',
      'tags': ['ios', 'auth', 'safari'],
      'isRead': true,
      'messageCount': 4,
      'messages': [
        {
          'id': 'msg0101',
          'ticketId': _tkt1,
          'senderId': _uid3,
          'senderName': 'Sofia Rodriguez',
          'content': 'Reproduced on iPhone 15 Pro and SE 3rd gen. Both crash on form submit.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-28T09:15:00.000Z',
        },
        {
          'id': 'msg0102',
          'ticketId': _tkt1,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': 'Checking the Safari console logs — looks like a memory issue with the auth token storage. Will patch today.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-28T10:30:00.000Z',
        },
        {
          'id': 'msg0103',
          'ticketId': _tkt1,
          'senderId': _uid2,
          'senderName': 'Marcus Thompson',
          'content': 'This is blocking onboarding for the Apex client. Priority escalated to Urgent.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-28T11:00:00.000Z',
        },
        {
          'id': 'msg0104',
          'ticketId': _tkt1,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': 'Fix deployed to staging. Needs QA sign-off before going to production.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-29T14:00:00.000Z',
        },
      ],
      'dueDate': '2026-05-02T17:00:00.000Z',
      'createdAt': '2026-04-28T09:00:00.000Z',
      'updatedAt': '2026-04-29T14:00:00.000Z',
    },
    {
      'id': _tkt2,
      'title': 'Flow editor canvas zoom reset on node drag',
      'description':
          'When dragging a node in the flow editor, the canvas zoom level resets to 100% unexpectedly.',
      'companyId': companyId,
      'creatorId': _uid4,
      'creatorName': 'James Park',
      'assigneeId': _uid4,
      'assigneeName': 'James Park',
      'status': 'open',
      'priority': 'high',
      'tags': ['flow-editor', 'ux', 'bug'],
      'isRead': false,
      'messageCount': 3,
      'messages': [
        {
          'id': 'msg0201',
          'ticketId': _tkt2,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': 'Happens consistently on all browsers. Steps: open editor → zoom to 150% → drag any node → zoom resets.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-30T08:00:00.000Z',
        },
        {
          'id': 'msg0202',
          'ticketId': _tkt2,
          'senderId': _uid1,
          'senderName': 'Alexandra Chen',
          'content': 'Confirmed. Blocking the UX review this week. Assign highest priority.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-30T09:15:00.000Z',
        },
        {
          'id': 'msg0203',
          'ticketId': _tkt2,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': 'Root cause identified: scale state is not persisted in the zoom handler. Working on fix.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-05-01T10:00:00.000Z',
        },
      ],
      'dueDate': '2026-05-05T17:00:00.000Z',
      'createdAt': '2026-04-30T08:00:00.000Z',
      'updatedAt': '2026-05-01T10:00:00.000Z',
    },
    {
      'id': _tkt3,
      'title': 'Add CSV export for user list',
      'description': 'Clients have requested the ability to export the full user list as a CSV for their own records.',
      'companyId': companyId,
      'creatorId': _uid2,
      'creatorName': 'Marcus Thompson',
      'assigneeId': _uid4,
      'assigneeName': 'James Park',
      'status': 'open',
      'priority': 'medium',
      'tags': ['feature-request', 'users', 'export'],
      'isRead': false,
      'messageCount': 2,
      'messages': [
        {
          'id': 'msg0301',
          'ticketId': _tkt3,
          'senderId': _uid2,
          'senderName': 'Marcus Thompson',
          'content': 'At least 3 enterprise clients have requested this. Should include: name, email, role, last login, status.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-05-02T11:00:00.000Z',
        },
        {
          'id': 'msg0302',
          'ticketId': _tkt3,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': 'Will add to the next sprint. ETA end of week.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-05-02T13:30:00.000Z',
        },
      ],
      'createdAt': '2026-05-02T11:00:00.000Z',
      'updatedAt': '2026-05-02T13:30:00.000Z',
    },
    {
      'id': _tkt4,
      'title': 'Email notifications not sending for ticket assignment',
      'description':
          'When a ticket is assigned to a user, the email notification is not being sent. Confirmed across all SMTP configurations.',
      'companyId': companyId,
      'creatorId': _uid5,
      'creatorName': 'Emily Watson',
      'assigneeId': _uid4,
      'assigneeName': 'James Park',
      'status': 'resolved',
      'priority': 'high',
      'tags': ['email', 'notifications', 'bug'],
      'isRead': true,
      'messageCount': 5,
      'messages': [
        {
          'id': 'msg0401',
          'ticketId': _tkt4,
          'senderId': _uid5,
          'senderName': 'Emily Watson',
          'content': 'Multiple users confirming no emails on ticket assignment. Checked spam — not there either.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-15T10:00:00.000Z',
        },
        {
          'id': 'msg0402',
          'ticketId': _tkt4,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': 'Investigating the notification service. Will check queue logs.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-15T11:20:00.000Z',
        },
        {
          'id': 'msg0403',
          'ticketId': _tkt4,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': 'Found it — a misconfiguration in the event handler was silently swallowing the SMTP error. Deploying fix now.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-16T09:00:00.000Z',
        },
        {
          'id': 'msg0404',
          'ticketId': _tkt4,
          'senderId': _uid5,
          'senderName': 'Emily Watson',
          'content': 'Just received a test notification. Fix confirmed working.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-16T15:30:00.000Z',
        },
        {
          'id': 'msg0405',
          'ticketId': _tkt4,
          'senderId': _uid2,
          'senderName': 'Marcus Thompson',
          'content': 'Closing this ticket. Great turnaround time.',
          'attachments': <String>[],
          'isSystem': true,
          'createdAt': '2026-04-16T16:00:00.000Z',
        },
      ],
      'resolvedAt': '2026-04-16T16:00:00.000Z',
      'createdAt': '2026-04-15T10:00:00.000Z',
      'updatedAt': '2026-04-16T16:00:00.000Z',
    },
    {
      'id': _tkt5,
      'title': 'Role permissions not applying to form builder',
      'description':
          'Users with the Viewer role can still edit form fields in the form builder despite canUpdate being false on the forms resource.',
      'companyId': companyId,
      'creatorId': _uid3,
      'creatorName': 'Sofia Rodriguez',
      'assigneeId': _uid4,
      'assigneeName': 'James Park',
      'status': 'inProgress',
      'priority': 'high',
      'tags': ['permissions', 'forms', 'security'],
      'isRead': true,
      'messageCount': 3,
      'messages': [
        {
          'id': 'msg0501',
          'ticketId': _tkt5,
          'senderId': _uid3,
          'senderName': 'Sofia Rodriguez',
          'content': 'Tested with a Viewer account — I can drag fields and change labels. This is a security risk.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-05-05T08:30:00.000Z',
        },
        {
          'id': 'msg0502',
          'ticketId': _tkt5,
          'senderId': _uid1,
          'senderName': 'Alexandra Chen',
          'content': 'Security issue confirmed. Escalating to High. James, please fix before the next client demo.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-05-05T09:00:00.000Z',
        },
        {
          'id': 'msg0503',
          'ticketId': _tkt5,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': 'The form builder widget was not checking the permission guard on render. Fix in progress — ETA tomorrow.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-05-05T10:45:00.000Z',
        },
      ],
      'dueDate': '2026-05-07T17:00:00.000Z',
      'createdAt': '2026-05-05T08:30:00.000Z',
      'updatedAt': '2026-05-05T10:45:00.000Z',
    },
    {
      'id': _tkt6,
      'title': 'Letter template variables not substituting on preview',
      'description': 'Clicking "Preview" in the letter template editor shows the raw {{variable}} tags instead of substituted sample values.',
      'companyId': companyId,
      'creatorId': _uid5,
      'creatorName': 'Emily Watson',
      'assigneeId': _uid5,
      'assigneeName': 'Emily Watson',
      'status': 'closed',
      'priority': 'low',
      'tags': ['letters', 'preview', 'bug'],
      'isRead': true,
      'messageCount': 3,
      'messages': [
        {
          'id': 'msg0601',
          'ticketId': _tkt6,
          'senderId': _uid5,
          'senderName': 'Emily Watson',
          'content': 'The {{client_name}} and {{sender_name}} tags are showing raw in the preview pane.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-03-18T14:00:00.000Z',
        },
        {
          'id': 'msg0602',
          'ticketId': _tkt6,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': 'Good catch. The preview renderer was using the raw content field instead of the processed one. Fixed in v1.2.3.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-03-19T10:00:00.000Z',
        },
        {
          'id': 'msg0603',
          'ticketId': _tkt6,
          'senderId': _uid5,
          'senderName': 'Emily Watson',
          'content': 'Confirmed fixed. Closing.',
          'attachments': <String>[],
          'isSystem': true,
          'createdAt': '2026-03-19T15:00:00.000Z',
        },
      ],
      'resolvedAt': '2026-03-19T15:00:00.000Z',
      'createdAt': '2026-03-18T14:00:00.000Z',
      'updatedAt': '2026-03-19T15:00:00.000Z',
    },
    {
      'id': _tkt7,
      'title': 'Dark mode: sidebar icon colours inconsistent',
      'description':
          'In dark mode, several sidebar navigation icons appear with a light background box rather than the expected transparent fill.',
      'companyId': companyId,
      'creatorId': _uid2,
      'creatorName': 'Marcus Thompson',
      'assigneeId': _uid4,
      'assigneeName': 'James Park',
      'status': 'resolved',
      'priority': 'low',
      'tags': ['dark-mode', 'ui', 'cosmetic'],
      'isRead': true,
      'messageCount': 4,
      'messages': [
        {
          'id': 'msg0701',
          'ticketId': _tkt7,
          'senderId': _uid2,
          'senderName': 'Marcus Thompson',
          'content': 'Affects the Tickets, Roles, and Letters icons. Screenshot attached (not available in demo).',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-02T09:00:00.000Z',
        },
        {
          'id': 'msg0702',
          'ticketId': _tkt7,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': 'Those icons have a hardcoded white background in their SVG. Will update them.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-02T10:30:00.000Z',
        },
        {
          'id': 'msg0703',
          'ticketId': _tkt7,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': 'Updated all three icon assets. Deployed in v1.3.0.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-05T14:00:00.000Z',
        },
        {
          'id': 'msg0704',
          'ticketId': _tkt7,
          'senderId': _uid2,
          'senderName': 'Marcus Thompson',
          'content': 'Looks perfect now. Resolved.',
          'attachments': <String>[],
          'isSystem': true,
          'createdAt': '2026-04-05T16:00:00.000Z',
        },
      ],
      'resolvedAt': '2026-04-05T16:00:00.000Z',
      'createdAt': '2026-04-02T09:00:00.000Z',
      'updatedAt': '2026-04-05T16:00:00.000Z',
    },
    {
      'id': _tkt8,
      'title': 'Onboarding flow — approval step silently fails for large files',
      'description':
          'When a client uploads a file larger than 10 MB in the Intake Form step, the approval step fails with no error displayed.',
      'companyId': companyId,
      'flowId': _flo1,
      'creatorId': _uid3,
      'creatorName': 'Sofia Rodriguez',
      'assigneeId': _uid4,
      'assigneeName': 'James Park',
      'status': 'open',
      'priority': 'medium',
      'tags': ['onboarding', 'file-upload', 'bug'],
      'isRead': false,
      'messageCount': 2,
      'messages': [
        {
          'id': 'msg0801',
          'ticketId': _tkt8,
          'senderId': _uid3,
          'senderName': 'Sofia Rodriguez',
          'content': 'The Apex client tried to upload a 14 MB PDF proposal. Flow got stuck — no error, no progress.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-05-10T13:00:00.000Z',
        },
        {
          'id': 'msg0802',
          'ticketId': _tkt8,
          'senderId': _uid2,
          'senderName': 'Marcus Thompson',
          'content': 'This affects our active onboarding flow. Needs fixing before the next client intake.',
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-05-10T14:00:00.000Z',
        },
      ],
      'dueDate': '2026-05-14T17:00:00.000Z',
      'createdAt': '2026-05-10T13:00:00.000Z',
      'updatedAt': '2026-05-10T14:00:00.000Z',
    },
  ];

  // ──────────────────────────────────────────────────────────────
  // FLOW INSTANCES  (3)
  // These are plain maps — no generated model class exists yet.
  // ──────────────────────────────────────────────────────────────

  static final List<Map<String, dynamic>> instances = [
    {
      'id': _ins1,
      'flowId': _flo1,
      'flowName': 'Client Onboarding',
      'companyId': companyId,
      'status': 'active',
      'startedById': _uid3,
      'startedByName': 'Sofia Rodriguez',
      'currentNodeId': 'n003',
      'currentNodeLabel': 'Approval?',
      'progressPercent': 40,
      'metadata': {
        'client_name': 'Apex Dynamics Ltd',
        'project_type': 'data_platform',
      },
      'createdAt': '2026-05-08T09:00:00.000Z',
      'updatedAt': '2026-05-10T11:30:00.000Z',
    },
    {
      'id': _ins2,
      'flowId': _flo2,
      'flowName': 'Bug Report Triage',
      'companyId': companyId,
      'status': 'active',
      'startedById': _uid5,
      'startedByName': 'Emily Watson',
      'currentNodeId': 'n104',
      'currentNodeLabel': 'Escalate to Dev Lead',
      'progressPercent': 60,
      'metadata': {
        'bug_title': 'Memory leak in report generator',
        'severity': 'critical',
      },
      'createdAt': '2026-05-09T14:00:00.000Z',
      'updatedAt': '2026-05-10T09:00:00.000Z',
    },
    {
      'id': _ins3,
      'flowId': _flo1,
      'flowName': 'Client Onboarding',
      'companyId': companyId,
      'status': 'completed',
      'startedById': _uid2,
      'startedByName': 'Marcus Thompson',
      'currentNodeId': 'n005',
      'currentNodeLabel': 'End',
      'progressPercent': 100,
      'metadata': {
        'client_name': 'BlueSky Ventures',
        'project_type': 'web_app',
      },
      'completedAt': '2026-04-22T16:00:00.000Z',
      'createdAt': '2026-04-18T10:00:00.000Z',
      'updatedAt': '2026-04-22T16:00:00.000Z',
    },
  ];
}
