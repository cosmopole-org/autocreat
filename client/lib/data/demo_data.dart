// ignore_for_file: prefer_single_quotes
/// All static demo data for client-side demo mode.
/// Every field matches the shape expected by the corresponding
/// `fromJson` factory on the real model classes.
///
/// Language-sensitive fields (names, descriptions, labels) are sourced from
/// [MockDataText] so they switch automatically when [UiText.configureLanguage]
/// is called. All top-level collections are computed getters (not `final`
/// fields) so they re-evaluate on each access with the current language.
library demo_data;

import 'mock_data_text.dart';

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

  static Map<String, dynamic> get company => {
        'id': companyId,
        'name': MockDataText.companyName,
        'description': MockDataText.companyDescription,
        'website': 'https://horizondigital.io',
        'industry': MockDataText.companyIndustry,
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

  static Map<String, dynamic> get currentUser => {
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

  static Map<String, dynamic> get stats => {
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

  static List<Map<String, dynamic>> get users => [
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

  static List<Map<String, dynamic>> get roles => [
        {
          'id': _rid1,
          'name': MockDataText.roleAdministratorName,
          'description': MockDataText.roleAdministratorDesc,
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
          'name': MockDataText.roleOperationsManagerName,
          'description': MockDataText.roleOperationsManagerDesc,
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
          'name': MockDataText.roleSupportAgentName,
          'description': MockDataText.roleSupportAgentDesc,
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
          'name': MockDataText.roleDeveloperName,
          'description': MockDataText.roleDeveloperDesc,
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
          'name': MockDataText.roleViewerName,
          'description': MockDataText.roleViewerDesc,
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

  static List<Map<String, dynamic>> get flows => [
        {
          'id': _flo1,
          'name': MockDataText.flow1Name,
          'description': MockDataText.flow1Desc,
          'companyId': companyId,
          'status': 'active',
          'nodes': [
            {
              'id': 'n001',
              'label': MockDataText.nodeStart,
              'type': 'start',
              'x': 80.0,
              'y': 200.0,
              'width': 140.0,
              'height': 60.0,
              'branches': <Map<String, dynamic>>[],
            },
            {
              'id': 'n002',
              'label': MockDataText.nodeIntakeForm,
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
              'label': MockDataText.nodeApprovalQuestion,
              'type': 'decision',
              'x': 500.0,
              'y': 200.0,
              'width': 160.0,
              'height': 60.0,
              'branches': [
                {'id': 'b001', 'label': MockDataText.branchApproved, 'condition': 'approved == true', 'targetNodeId': 'n004', 'isDefault': false},
                {'id': 'b002', 'label': MockDataText.branchRejected, 'condition': 'approved == false', 'targetNodeId': 'n005', 'isDefault': true},
              ],
            },
            {
              'id': 'n004',
              'label': MockDataText.nodeSendWelcomeLetter,
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
              'label': MockDataText.nodeEnd,
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
            {'id': 'e003', 'sourceNodeId': 'n003', 'targetNodeId': 'n004', 'label': MockDataText.branchApproved, 'conditionId': 'b001'},
            {'id': 'e004', 'sourceNodeId': 'n003', 'targetNodeId': 'n005', 'label': MockDataText.branchRejected, 'conditionId': 'b002'},
            {'id': 'e005', 'sourceNodeId': 'n004', 'targetNodeId': 'n005', 'label': null},
          ],
          'settings': <String, dynamic>{},
          'createdAt': '2026-01-20T10:00:00.000Z',
          'updatedAt': '2026-04-18T15:30:00.000Z',
        },
        {
          'id': _flo2,
          'name': MockDataText.flow2Name,
          'description': MockDataText.flow2Desc,
          'companyId': companyId,
          'status': 'active',
          'nodes': [
            {
              'id': 'n101',
              'label': MockDataText.nodeStart,
              'type': 'start',
              'x': 80.0,
              'y': 150.0,
              'width': 140.0,
              'height': 60.0,
              'branches': <Map<String, dynamic>>[],
            },
            {
              'id': 'n102',
              'label': MockDataText.nodeBugReportForm,
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
              'label': MockDataText.nodeSeverityCheck,
              'type': 'decision',
              'x': 520.0,
              'y': 150.0,
              'width': 160.0,
              'height': 60.0,
              'branches': [
                {'id': 'b101', 'label': MockDataText.branchCritical, 'condition': 'severity == "critical"', 'targetNodeId': 'n104', 'isDefault': false},
                {'id': 'b102', 'label': MockDataText.branchNormal, 'condition': null, 'targetNodeId': 'n105', 'isDefault': true},
              ],
            },
            {
              'id': 'n104',
              'label': MockDataText.nodeEscalateToDevLead,
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
              'label': MockDataText.nodeAssignToDeveloper,
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
              'label': MockDataText.nodeEnd,
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
            {'id': 'e103', 'sourceNodeId': 'n103', 'targetNodeId': 'n104', 'label': MockDataText.branchCritical, 'conditionId': 'b101'},
            {'id': 'e104', 'sourceNodeId': 'n103', 'targetNodeId': 'n105', 'label': MockDataText.branchNormal, 'conditionId': 'b102'},
            {'id': 'e105', 'sourceNodeId': 'n104', 'targetNodeId': 'n106'},
            {'id': 'e106', 'sourceNodeId': 'n105', 'targetNodeId': 'n106'},
          ],
          'settings': <String, dynamic>{},
          'createdAt': '2026-02-05T11:00:00.000Z',
          'updatedAt': '2026-04-25T09:00:00.000Z',
        },
        {
          'id': _flo3,
          'name': MockDataText.flow3Name,
          'description': MockDataText.flow3Desc,
          'companyId': companyId,
          'status': 'draft',
          'nodes': [
            {
              'id': 'n201',
              'label': MockDataText.nodeStart,
              'type': 'start',
              'x': 80.0,
              'y': 180.0,
              'width': 140.0,
              'height': 60.0,
              'branches': <Map<String, dynamic>>[],
            },
            {
              'id': 'n202',
              'label': MockDataText.nodeLeaveRequestForm,
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
              'label': MockDataText.nodeManagerApproval,
              'type': 'decision',
              'x': 530.0,
              'y': 180.0,
              'width': 180.0,
              'height': 60.0,
              'assignedRoleId': _rid2,
              'branches': [
                {'id': 'b201', 'label': MockDataText.branchApproved, 'condition': 'approved == true', 'targetNodeId': 'n204', 'isDefault': false},
                {'id': 'b202', 'label': MockDataText.branchDenied, 'condition': 'approved == false', 'targetNodeId': 'n205', 'isDefault': true},
              ],
            },
            {
              'id': 'n204',
              'label': MockDataText.nodeSendApprovalLetter,
              'type': 'step',
              'x': 780.0,
              'y': 110.0,
              'width': 200.0,
              'height': 60.0,
              'branches': <Map<String, dynamic>>[],
            },
            {
              'id': 'n205',
              'label': MockDataText.nodeSendDenialLetter,
              'type': 'step',
              'x': 780.0,
              'y': 250.0,
              'width': 200.0,
              'height': 60.0,
              'branches': <Map<String, dynamic>>[],
            },
            {
              'id': 'n206',
              'label': MockDataText.nodeEnd,
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
            {'id': 'e203', 'sourceNodeId': 'n203', 'targetNodeId': 'n204', 'label': MockDataText.branchApproved, 'conditionId': 'b201'},
            {'id': 'e204', 'sourceNodeId': 'n203', 'targetNodeId': 'n205', 'label': MockDataText.branchDenied, 'conditionId': 'b202'},
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

  static List<Map<String, dynamic>> get forms => [
        {
          'id': _frm1,
          'name': MockDataText.form1Name,
          'description': MockDataText.form1Desc,
          'companyId': companyId,
          'modelId': _mod1,
          'status': 'active',
          'fields': [
            {
              'id': 'ff0101',
              'type': 'text',
              'label': MockDataText.fieldCompanyName,
              'placeholder': MockDataText.phAcmeCorp,
              'required': true,
              'readOnly': false,
              'hidden': false,
              'options': <Map<String, dynamic>>[],
              'order': 1,
            },
            {
              'id': 'ff0102',
              'type': 'text',
              'label': MockDataText.fieldPrimaryContact,
              'placeholder': MockDataText.phFullName,
              'required': true,
              'readOnly': false,
              'hidden': false,
              'options': <Map<String, dynamic>>[],
              'order': 2,
            },
            {
              'id': 'ff0103',
              'type': 'text',
              'label': MockDataText.fieldEmailAddress,
              'placeholder': MockDataText.phContactEmail,
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
              'label': MockDataText.fieldProjectType,
              'required': true,
              'readOnly': false,
              'hidden': false,
              'options': [
                {'value': 'web_app', 'label': MockDataText.optWebApp},
                {'value': 'mobile_app', 'label': MockDataText.optMobileApp},
                {'value': 'data_platform', 'label': MockDataText.optDataPlatform},
                {'value': 'integration', 'label': MockDataText.optIntegration},
              ],
              'order': 4,
            },
            {
              'id': 'ff0105',
              'type': 'number',
              'label': MockDataText.fieldEstimatedBudget,
              'placeholder': MockDataText.phBudget,
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
              'label': MockDataText.fieldProjectDescription,
              'placeholder': MockDataText.phProjectDescGoals,
              'required': true,
              'readOnly': false,
              'hidden': false,
              'options': <Map<String, dynamic>>[],
              'order': 6,
            },
            {
              'id': 'ff0107',
              'type': 'date',
              'label': MockDataText.fieldDesiredStartDate,
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
          'name': MockDataText.form2Name,
          'description': MockDataText.form2Desc,
          'companyId': companyId,
          'modelId': null,
          'status': 'active',
          'fields': [
            {
              'id': 'ff0201',
              'type': 'text',
              'label': MockDataText.fieldBugTitle,
              'placeholder': MockDataText.phBugSummary,
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
              'label': MockDataText.fieldSeverity,
              'required': true,
              'readOnly': false,
              'hidden': false,
              'options': [
                {'value': 'critical', 'label': MockDataText.optCriticalSeverity},
                {'value': 'high', 'label': MockDataText.optHighSeverity},
                {'value': 'medium', 'label': MockDataText.optMediumSeverity},
                {'value': 'low', 'label': MockDataText.optLowSeverity},
              ],
              'order': 2,
            },
            {
              'id': 'ff0203',
              'type': 'textarea',
              'label': MockDataText.fieldStepsToReproduce,
              'placeholder': MockDataText.phStepsToReproduce,
              'required': true,
              'readOnly': false,
              'hidden': false,
              'options': <Map<String, dynamic>>[],
              'order': 3,
            },
            {
              'id': 'ff0204',
              'type': 'textarea',
              'label': MockDataText.fieldExpectedBehaviour,
              'required': true,
              'readOnly': false,
              'hidden': false,
              'options': <Map<String, dynamic>>[],
              'order': 4,
            },
            {
              'id': 'ff0205',
              'type': 'textarea',
              'label': MockDataText.fieldActualBehaviour,
              'required': true,
              'readOnly': false,
              'hidden': false,
              'options': <Map<String, dynamic>>[],
              'order': 5,
            },
            {
              'id': 'ff0206',
              'type': 'file',
              'label': MockDataText.fieldScreenshotsLogs,
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
          'name': MockDataText.form3Name,
          'description': MockDataText.form3Desc,
          'companyId': companyId,
          'modelId': null,
          'status': 'active',
          'fields': [
            {
              'id': 'ff0301',
              'type': 'dropdown',
              'label': MockDataText.fieldLeaveType,
              'required': true,
              'readOnly': false,
              'hidden': false,
              'options': [
                {'value': 'annual', 'label': MockDataText.optAnnualLeave},
                {'value': 'sick', 'label': MockDataText.optSickLeave},
                {'value': 'personal', 'label': MockDataText.optPersonalLeave},
                {'value': 'parental', 'label': MockDataText.optParentalLeave},
              ],
              'order': 1,
            },
            {
              'id': 'ff0302',
              'type': 'date',
              'label': MockDataText.fieldStartDate,
              'required': true,
              'readOnly': false,
              'hidden': false,
              'options': <Map<String, dynamic>>[],
              'order': 2,
            },
            {
              'id': 'ff0303',
              'type': 'date',
              'label': MockDataText.fieldEndDate,
              'required': true,
              'readOnly': false,
              'hidden': false,
              'options': <Map<String, dynamic>>[],
              'order': 3,
            },
            {
              'id': 'ff0304',
              'type': 'textarea',
              'label': MockDataText.fieldReason,
              'placeholder': MockDataText.phOptionalDetails,
              'required': false,
              'readOnly': false,
              'hidden': false,
              'options': <Map<String, dynamic>>[],
              'order': 4,
            },
            {
              'id': 'ff0305',
              'type': 'switchField',
              'label': MockDataText.fieldCoverArranged,
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
          'name': MockDataText.form4Name,
          'description': MockDataText.form4Desc,
          'companyId': companyId,
          'modelId': null,
          'status': 'active',
          'fields': [
            {
              'id': 'ff0401',
              'type': 'rating',
              'label': MockDataText.fieldOverallSatisfaction,
              'required': true,
              'readOnly': false,
              'hidden': false,
              'options': <Map<String, dynamic>>[],
              'order': 1,
            },
            {
              'id': 'ff0402',
              'type': 'number',
              'label': MockDataText.fieldNPS,
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
              'label': MockDataText.fieldWhatWentWell,
              'required': false,
              'readOnly': false,
              'hidden': false,
              'options': [
                {'value': 'communication', 'label': MockDataText.optCommunication},
                {'value': 'quality', 'label': MockDataText.optDeliveryQuality},
                {'value': 'timeline', 'label': MockDataText.optOnTimeDelivery},
                {'value': 'support', 'label': MockDataText.optPostLaunchSupport},
                {'value': 'value', 'label': MockDataText.optValueForMoney},
              ],
              'order': 3,
            },
            {
              'id': 'ff0404',
              'type': 'textarea',
              'label': MockDataText.fieldAdditionalComments,
              'placeholder': MockDataText.phAnyFeedback,
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

  static List<Map<String, dynamic>> get letters => [
    {
      'id': _let1,
      'name': MockDataText.letter1Name,
      'description': MockDataText.letter1Desc,
      'companyId': companyId,
      'content': MockDataText.letter1Content,
      'deltaContent': <String, dynamic>{},
      'variables': ['client_name', 'company_name', 'pm_name', 'sender_name'],
      'status': 'active',
      'category': MockDataText.letter1Category,
      'createdAt': '2026-01-25T11:00:00.000Z',
      'updatedAt': '2026-04-12T09:00:00.000Z',
    },
    {
      'id': _let2,
      'name': MockDataText.letter2Name,
      'description': MockDataText.letter2Desc,
      'companyId': companyId,
      'content': MockDataText.letter2Content,
      'deltaContent': <String, dynamic>{},
      'variables': ['employee_name', 'leave_type', 'start_date', 'end_date', 'manager_name'],
      'status': 'active',
      'category': MockDataText.letter2Category,
      'createdAt': '2026-02-20T14:00:00.000Z',
      'updatedAt': '2026-04-18T11:30:00.000Z',
    },
    {
      'id': _let3,
      'name': MockDataText.letter3Name,
      'description': MockDataText.letter3Desc,
      'companyId': companyId,
      'content': MockDataText.letter3Content,
      'deltaContent': <String, dynamic>{},
      'variables': ['project_name', 'client_company', 'completion_date', 'project_scope', 'standard', 'authoriser_name', 'issue_date'],
      'status': 'draft',
      'category': MockDataText.letter3Category,
      'createdAt': '2026-03-30T10:00:00.000Z',
      'updatedAt': '2026-04-29T16:00:00.000Z',
    },
  ];

  // ──────────────────────────────────────────────────────────────
  // MODEL DEFINITIONS  (2)
  // Shape matches ModelDefinition.fromJson
  // ──────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get models => [
    {
      'id': _mod1,
      'name': MockDataText.model1Name,
      'description': MockDataText.model1Desc,
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
      'name': MockDataText.model2Name,
      'description': MockDataText.model2Desc,
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

  static List<Map<String, dynamic>> get tickets => [
    {
      'id': _tkt1,
      'title': MockDataText.ticket1Title,
      'description': MockDataText.ticket1Desc,
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
          'content': MockDataText.msg0101,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-28T09:15:00.000Z',
        },
        {
          'id': 'msg0102',
          'ticketId': _tkt1,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': MockDataText.msg0102,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-28T10:30:00.000Z',
        },
        {
          'id': 'msg0103',
          'ticketId': _tkt1,
          'senderId': _uid2,
          'senderName': 'Marcus Thompson',
          'content': MockDataText.msg0103,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-28T11:00:00.000Z',
        },
        {
          'id': 'msg0104',
          'ticketId': _tkt1,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': MockDataText.msg0104,
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
      'title': MockDataText.ticket2Title,
      'description': MockDataText.ticket2Desc,
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
          'content': MockDataText.msg0201,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-30T08:00:00.000Z',
        },
        {
          'id': 'msg0202',
          'ticketId': _tkt2,
          'senderId': _uid1,
          'senderName': 'Alexandra Chen',
          'content': MockDataText.msg0202,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-30T09:15:00.000Z',
        },
        {
          'id': 'msg0203',
          'ticketId': _tkt2,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': MockDataText.msg0203,
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
      'title': MockDataText.ticket3Title,
      'description': MockDataText.ticket3Desc,
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
          'content': MockDataText.msg0301,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-05-02T11:00:00.000Z',
        },
        {
          'id': 'msg0302',
          'ticketId': _tkt3,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': MockDataText.msg0302,
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
      'title': MockDataText.ticket4Title,
      'description': MockDataText.ticket4Desc,
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
          'content': MockDataText.msg0401,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-15T10:00:00.000Z',
        },
        {
          'id': 'msg0402',
          'ticketId': _tkt4,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': MockDataText.msg0402,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-15T11:20:00.000Z',
        },
        {
          'id': 'msg0403',
          'ticketId': _tkt4,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': MockDataText.msg0403,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-16T09:00:00.000Z',
        },
        {
          'id': 'msg0404',
          'ticketId': _tkt4,
          'senderId': _uid5,
          'senderName': 'Emily Watson',
          'content': MockDataText.msg0404,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-16T15:30:00.000Z',
        },
        {
          'id': 'msg0405',
          'ticketId': _tkt4,
          'senderId': _uid2,
          'senderName': 'Marcus Thompson',
          'content': MockDataText.msg0405,
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
      'title': MockDataText.ticket5Title,
      'description': MockDataText.ticket5Desc,
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
          'content': MockDataText.msg0501,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-05-05T08:30:00.000Z',
        },
        {
          'id': 'msg0502',
          'ticketId': _tkt5,
          'senderId': _uid1,
          'senderName': 'Alexandra Chen',
          'content': MockDataText.msg0502,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-05-05T09:00:00.000Z',
        },
        {
          'id': 'msg0503',
          'ticketId': _tkt5,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': MockDataText.msg0503,
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
      'title': MockDataText.ticket6Title,
      'description': MockDataText.ticket6Desc,
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
          'content': MockDataText.msg0601,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-03-18T14:00:00.000Z',
        },
        {
          'id': 'msg0602',
          'ticketId': _tkt6,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': MockDataText.msg0602,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-03-19T10:00:00.000Z',
        },
        {
          'id': 'msg0603',
          'ticketId': _tkt6,
          'senderId': _uid5,
          'senderName': 'Emily Watson',
          'content': MockDataText.msg0603,
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
      'title': MockDataText.ticket7Title,
      'description': MockDataText.ticket7Desc,
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
          'content': MockDataText.msg0701,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-02T09:00:00.000Z',
        },
        {
          'id': 'msg0702',
          'ticketId': _tkt7,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': MockDataText.msg0702,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-02T10:30:00.000Z',
        },
        {
          'id': 'msg0703',
          'ticketId': _tkt7,
          'senderId': _uid4,
          'senderName': 'James Park',
          'content': MockDataText.msg0703,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-04-05T14:00:00.000Z',
        },
        {
          'id': 'msg0704',
          'ticketId': _tkt7,
          'senderId': _uid2,
          'senderName': 'Marcus Thompson',
          'content': MockDataText.msg0704,
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
      'title': MockDataText.ticket8Title,
      'description': MockDataText.ticket8Desc,
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
          'content': MockDataText.msg0801,
          'attachments': <String>[],
          'isSystem': false,
          'createdAt': '2026-05-10T13:00:00.000Z',
        },
        {
          'id': 'msg0802',
          'ticketId': _tkt8,
          'senderId': _uid2,
          'senderName': 'Marcus Thompson',
          'content': MockDataText.msg0802,
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

  static List<Map<String, dynamic>> get instances => [
    {
      'id': _ins1,
      'flowId': _flo1,
      'flowName': MockDataText.flow1Name,
      'companyId': companyId,
      'status': 'active',
      'startedById': _uid3,
      'startedByName': 'Sofia Rodriguez',
      'currentNodeId': 'n003',
      'currentNodeLabel': MockDataText.nodeApprovalQuestion,
      'progressPercent': 40,
      'metadata': {
        'client_name': MockDataText.instanceMetaClientApex,
        'project_type': 'data_platform',
      },
      'createdAt': '2026-05-08T09:00:00.000Z',
      'updatedAt': '2026-05-10T11:30:00.000Z',
    },
    {
      'id': _ins2,
      'flowId': _flo2,
      'flowName': MockDataText.flow2Name,
      'companyId': companyId,
      'status': 'active',
      'startedById': _uid5,
      'startedByName': 'Emily Watson',
      'currentNodeId': 'n104',
      'currentNodeLabel': MockDataText.nodeEscalateToDevLead,
      'progressPercent': 60,
      'metadata': {
        'bug_title': MockDataText.instanceMetaBugTitle,
        'severity': 'critical',
      },
      'createdAt': '2026-05-09T14:00:00.000Z',
      'updatedAt': '2026-05-10T09:00:00.000Z',
    },
    {
      'id': _ins3,
      'flowId': _flo1,
      'flowName': MockDataText.flow1Name,
      'companyId': companyId,
      'status': 'completed',
      'startedById': _uid2,
      'startedByName': 'Marcus Thompson',
      'currentNodeId': 'n005',
      'currentNodeLabel': MockDataText.nodeEnd,
      'progressPercent': 100,
      'metadata': {
        'client_name': MockDataText.instanceMetaClientBlueSky,
        'project_type': 'web_app',
      },
      'completedAt': '2026-04-22T16:00:00.000Z',
      'createdAt': '2026-04-18T10:00:00.000Z',
      'updatedAt': '2026-04-22T16:00:00.000Z',
    },
  ];
}
