class UserBrief {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String avatar;

  const UserBrief({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatar = '',
  });

  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  factory UserBrief.fromJson(Map<String, dynamic> json) => UserBrief(
        id: json['id']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        avatar: json['avatar']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'avatar': avatar,
      };
}

class StepHistoryItem {
  final String stepId;
  final String nodeId;
  final String nodeLabel;
  final String nodeType;
  final String status;
  final UserBrief? filledByUser;
  final String roleName;
  final Map<String, dynamic> formData;
  final List<Map<String, dynamic>> formFields;
  final DateTime? completedAt;
  final DateTime? rejectedAt;
  final String rejectionComment;

  const StepHistoryItem({
    required this.stepId,
    required this.nodeId,
    required this.nodeLabel,
    this.nodeType = 'step',
    this.status = 'COMPLETED',
    this.filledByUser,
    this.roleName = '',
    this.formData = const {},
    this.formFields = const [],
    this.completedAt,
    this.rejectedAt,
    this.rejectionComment = '',
  });

  factory StepHistoryItem.fromJson(Map<String, dynamic> json) {
    final raw = json['formData'];
    final Map<String, dynamic> formData =
        (raw is Map<String, dynamic>) ? raw : {};

    final rawFields = json['formFields'];
    final List<Map<String, dynamic>> formFields = rawFields is List
        ? rawFields.whereType<Map<String, dynamic>>().toList()
        : [];

    return StepHistoryItem(
      stepId: json['stepId']?.toString() ?? '',
      nodeId: json['nodeId']?.toString() ?? '',
      nodeLabel: json['nodeLabel']?.toString() ?? '',
      nodeType: json['nodeType']?.toString() ?? 'step',
      status: json['status']?.toString() ?? 'COMPLETED',
      filledByUser: json['filledByUser'] != null
          ? UserBrief.fromJson(json['filledByUser'] as Map<String, dynamic>)
          : null,
      roleName: json['roleName']?.toString() ?? '',
      formData: formData,
      formFields: formFields,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.tryParse(json['rejectedAt'].toString())
          : null,
      rejectionComment: json['rejectionComment']?.toString() ?? '',
    );
  }
}

class StartableFlow {
  final String flowId;
  final String flowName;
  final String flowDescription;
  final String startNodeId;
  final String startNodeLabel;
  final String? formId;
  final String formName;
  final List<Map<String, dynamic>> formFields;

  const StartableFlow({
    required this.flowId,
    required this.flowName,
    this.flowDescription = '',
    required this.startNodeId,
    this.startNodeLabel = '',
    this.formId,
    this.formName = '',
    this.formFields = const [],
  });

  factory StartableFlow.fromJson(Map<String, dynamic> json) {
    final rawFields = json['formFields'];
    final List<Map<String, dynamic>> formFields = rawFields is List
        ? rawFields.whereType<Map<String, dynamic>>().toList()
        : [];
    return StartableFlow(
      flowId: json['flowId']?.toString() ?? '',
      flowName: json['flowName']?.toString() ?? '',
      flowDescription: json['flowDescription']?.toString() ?? '',
      startNodeId: json['startNodeId']?.toString() ?? '',
      startNodeLabel: json['startNodeLabel']?.toString() ?? '',
      formId: json['formId']?.toString(),
      formName: json['formName']?.toString() ?? '',
      formFields: formFields,
    );
  }
}

class MyTask {
  final String stepId;
  final String instanceId;
  final String flowId;
  final String flowName;
  final String nodeId;
  final String nodeLabel;
  final String nodeDescription;
  final String? assignedRoleId;
  final String roleName;
  final String? formId;
  final String formName;
  final List<Map<String, dynamic>> formFields;
  final String? assignedToUserId;
  final UserBrief? startedByUser;
  final String companyId;
  final DateTime? createdAt;
  final DateTime? instanceCreatedAt;
  final List<StepHistoryItem> previousSteps;
  final List<UserBrief> nextNodeRoleUsers;

  const MyTask({
    required this.stepId,
    required this.instanceId,
    required this.flowId,
    this.flowName = '',
    required this.nodeId,
    this.nodeLabel = '',
    this.nodeDescription = '',
    this.assignedRoleId,
    this.roleName = '',
    this.formId,
    this.formName = '',
    this.formFields = const [],
    this.assignedToUserId,
    this.startedByUser,
    required this.companyId,
    this.createdAt,
    this.instanceCreatedAt,
    this.previousSteps = const [],
    this.nextNodeRoleUsers = const [],
  });

  factory MyTask.fromJson(Map<String, dynamic> json) {
    final rawFields = json['formFields'];
    final List<Map<String, dynamic>> formFields = rawFields is List
        ? rawFields.whereType<Map<String, dynamic>>().toList()
        : [];

    final rawSteps = json['previousSteps'];
    final List<StepHistoryItem> previousSteps = rawSteps is List
        ? rawSteps
            .whereType<Map<String, dynamic>>()
            .map(StepHistoryItem.fromJson)
            .toList()
        : [];

    final rawUsers = json['nextNodeRoleUsers'];
    final List<UserBrief> nextNodeRoleUsers = rawUsers is List
        ? rawUsers
            .whereType<Map<String, dynamic>>()
            .map(UserBrief.fromJson)
            .toList()
        : [];

    return MyTask(
      stepId: json['stepId']?.toString() ?? '',
      instanceId: json['instanceId']?.toString() ?? '',
      flowId: json['flowId']?.toString() ?? '',
      flowName: json['flowName']?.toString() ?? '',
      nodeId: json['nodeId']?.toString() ?? '',
      nodeLabel: json['nodeLabel']?.toString() ?? '',
      nodeDescription: json['nodeDescription']?.toString() ?? '',
      assignedRoleId: json['assignedRoleId']?.toString(),
      roleName: json['roleName']?.toString() ?? '',
      formId: json['formId']?.toString(),
      formName: json['formName']?.toString() ?? '',
      formFields: formFields,
      assignedToUserId: json['assignedToUserId']?.toString(),
      startedByUser: json['startedByUser'] != null
          ? UserBrief.fromJson(json['startedByUser'] as Map<String, dynamic>)
          : null,
      companyId: json['companyId']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      instanceCreatedAt: json['instanceCreatedAt'] != null
          ? DateTime.tryParse(json['instanceCreatedAt'].toString())
          : null,
      previousSteps: previousSteps,
      nextNodeRoleUsers: nextNodeRoleUsers,
    );
  }
}
