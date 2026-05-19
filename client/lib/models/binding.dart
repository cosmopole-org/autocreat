// Plain Dart models for form-model bindings and letter assignments.
// No freezed/build_runner required.

class FormModelBindingRule {
  final String id;
  final String bindingId;
  final String? sourceNodeId;
  final String formFieldKey;
  final String modelDefinitionId;
  final String modelInstanceKey;
  final String modelFieldKey;

  const FormModelBindingRule({
    required this.id,
    required this.bindingId,
    this.sourceNodeId,
    required this.formFieldKey,
    required this.modelDefinitionId,
    required this.modelInstanceKey,
    required this.modelFieldKey,
  });

  factory FormModelBindingRule.fromJson(Map<String, dynamic> json) =>
      FormModelBindingRule(
        id: json['id']?.toString() ?? '',
        bindingId: json['bindingId']?.toString() ?? '',
        sourceNodeId: json['sourceNodeId']?.toString(),
        formFieldKey: json['formFieldKey']?.toString() ?? '',
        modelDefinitionId: json['modelDefinitionId']?.toString() ?? '',
        modelInstanceKey: json['modelInstanceKey']?.toString() ?? 'default',
        modelFieldKey: json['modelFieldKey']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bindingId': bindingId,
        if (sourceNodeId != null) 'sourceNodeId': sourceNodeId,
        'formFieldKey': formFieldKey,
        'modelDefinitionId': modelDefinitionId,
        'modelInstanceKey': modelInstanceKey,
        'modelFieldKey': modelFieldKey,
      };

  FormModelBindingRule copyWith({
    String? id,
    String? bindingId,
    String? sourceNodeId,
    String? formFieldKey,
    String? modelDefinitionId,
    String? modelInstanceKey,
    String? modelFieldKey,
  }) =>
      FormModelBindingRule(
        id: id ?? this.id,
        bindingId: bindingId ?? this.bindingId,
        sourceNodeId: sourceNodeId ?? this.sourceNodeId,
        formFieldKey: formFieldKey ?? this.formFieldKey,
        modelDefinitionId: modelDefinitionId ?? this.modelDefinitionId,
        modelInstanceKey: modelInstanceKey ?? this.modelInstanceKey,
        modelFieldKey: modelFieldKey ?? this.modelFieldKey,
      );
}

class FormModelBinding {
  final String id;
  final String flowNodeId;
  final String name;
  final String? storeAtNodeId;
  final List<FormModelBindingRule> rules;

  const FormModelBinding({
    required this.id,
    required this.flowNodeId,
    required this.name,
    this.storeAtNodeId,
    required this.rules,
  });

  factory FormModelBinding.empty(String nodeId) => FormModelBinding(
        id: '',
        flowNodeId: nodeId,
        name: 'Binding',
        rules: [],
      );

  factory FormModelBinding.fromJson(Map<String, dynamic> json) {
    final rawRules = json['rules'];
    final rules = rawRules is List
        ? rawRules
            .whereType<Map<String, dynamic>>()
            .map(FormModelBindingRule.fromJson)
            .toList()
        : <FormModelBindingRule>[];
    return FormModelBinding(
      id: json['id']?.toString() ?? '',
      flowNodeId: json['flowNodeId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Binding',
      storeAtNodeId: json['storeAtNodeId']?.toString(),
      rules: rules,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'flowNodeId': flowNodeId,
        'name': name,
        if (storeAtNodeId != null && storeAtNodeId!.isNotEmpty)
          'storeAtNodeId': storeAtNodeId,
        'rules': rules.map((r) => r.toJson()).toList(),
      };

  FormModelBinding copyWith({
    String? id,
    String? flowNodeId,
    String? name,
    String? storeAtNodeId,
    List<FormModelBindingRule>? rules,
  }) =>
      FormModelBinding(
        id: id ?? this.id,
        flowNodeId: flowNodeId ?? this.flowNodeId,
        name: name ?? this.name,
        storeAtNodeId: storeAtNodeId ?? this.storeAtNodeId,
        rules: rules ?? this.rules,
      );
}

class VariableBindingEntry {
  final String? sourceNodeId;
  final String formFieldKey;

  const VariableBindingEntry({
    this.sourceNodeId,
    required this.formFieldKey,
  });

  factory VariableBindingEntry.fromJson(Map<String, dynamic> json) =>
      VariableBindingEntry(
        sourceNodeId: json['sourceNodeId']?.toString(),
        formFieldKey: json['formFieldKey']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (sourceNodeId != null && sourceNodeId!.isNotEmpty)
          'sourceNodeId': sourceNodeId,
        'formFieldKey': formFieldKey,
      };

  VariableBindingEntry copyWith({String? sourceNodeId, String? formFieldKey}) =>
      VariableBindingEntry(
        sourceNodeId: sourceNodeId ?? this.sourceNodeId,
        formFieldKey: formFieldKey ?? this.formFieldKey,
      );
}

class NodeLetterAssignment {
  final String id;
  final String flowNodeId;
  final String letterTemplateId;
  final String letterName;
  final List<String> letterVariables;
  final bool autoGenerateOnApprove;
  final bool allowBeforeApprove;
  final Map<String, VariableBindingEntry> variableBindings;

  const NodeLetterAssignment({
    required this.id,
    required this.flowNodeId,
    required this.letterTemplateId,
    required this.letterName,
    required this.letterVariables,
    required this.autoGenerateOnApprove,
    required this.allowBeforeApprove,
    required this.variableBindings,
  });

  factory NodeLetterAssignment.fromJson(Map<String, dynamic> json) {
    final rawVb = json['variableBindings'];
    final Map<String, VariableBindingEntry> vb = {};
    if (rawVb is Map) {
      rawVb.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          vb[k.toString()] = VariableBindingEntry.fromJson(v);
        }
      });
    }
    final rawVars = json['letterVariables'];
    final vars = rawVars is List ? rawVars.map((e) => e.toString()).toList() : <String>[];
    return NodeLetterAssignment(
      id: json['id']?.toString() ?? '',
      flowNodeId: json['flowNodeId']?.toString() ?? '',
      letterTemplateId: json['letterTemplateId']?.toString() ?? '',
      letterName: json['letterName']?.toString() ?? '',
      letterVariables: vars,
      autoGenerateOnApprove: json['autoGenerateOnApprove'] == true,
      allowBeforeApprove: json['allowBeforeApprove'] != false,
      variableBindings: vb,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'letterTemplateId': letterTemplateId,
        'autoGenerateOnApprove': autoGenerateOnApprove,
        'allowBeforeApprove': allowBeforeApprove,
        'variableBindings':
            variableBindings.map((k, v) => MapEntry(k, v.toJson())),
      };

  NodeLetterAssignment copyWith({
    String? id,
    String? flowNodeId,
    String? letterTemplateId,
    String? letterName,
    List<String>? letterVariables,
    bool? autoGenerateOnApprove,
    bool? allowBeforeApprove,
    Map<String, VariableBindingEntry>? variableBindings,
  }) =>
      NodeLetterAssignment(
        id: id ?? this.id,
        flowNodeId: flowNodeId ?? this.flowNodeId,
        letterTemplateId: letterTemplateId ?? this.letterTemplateId,
        letterName: letterName ?? this.letterName,
        letterVariables: letterVariables ?? this.letterVariables,
        autoGenerateOnApprove:
            autoGenerateOnApprove ?? this.autoGenerateOnApprove,
        allowBeforeApprove: allowBeforeApprove ?? this.allowBeforeApprove,
        variableBindings: variableBindings ?? this.variableBindings,
      );
}

class StepGeneratedLetter {
  final String id;
  final String assignmentId;
  final String letterTemplateId;
  final String letterName;
  final String generatedContent;
  final String trigger;
  final String generatedById;
  final DateTime createdAt;

  const StepGeneratedLetter({
    required this.id,
    required this.assignmentId,
    required this.letterTemplateId,
    required this.letterName,
    required this.generatedContent,
    required this.trigger,
    required this.generatedById,
    required this.createdAt,
  });

  factory StepGeneratedLetter.fromJson(Map<String, dynamic> json) =>
      StepGeneratedLetter(
        id: json['id']?.toString() ?? '',
        assignmentId: json['assignmentId']?.toString() ?? '',
        letterTemplateId: json['letterTemplateId']?.toString() ?? '',
        letterName: json['letterName']?.toString() ?? '',
        generatedContent: json['generatedContent']?.toString() ?? '',
        trigger: json['trigger']?.toString() ?? 'manual',
        generatedById: json['generatedById']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}
