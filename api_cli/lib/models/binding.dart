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
        id: json['id'] as String? ?? '',
        bindingId: json['bindingId'] as String? ?? '',
        sourceNodeId: json['sourceNodeId'] as String?,
        formFieldKey: json['formFieldKey'] as String? ?? '',
        modelDefinitionId: json['modelDefinitionId'] as String? ?? '',
        modelInstanceKey: json['modelInstanceKey'] as String? ?? 'default',
        modelFieldKey: json['modelFieldKey'] as String? ?? '',
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

  factory FormModelBinding.fromJson(Map<String, dynamic> json) =>
      FormModelBinding(
        id: json['id'] as String? ?? '',
        flowNodeId: json['flowNodeId'] as String? ?? '',
        name: json['name'] as String? ?? 'Binding',
        storeAtNodeId: json['storeAtNodeId'] as String?,
        rules: (json['rules'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(FormModelBindingRule.fromJson)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'flowNodeId': flowNodeId,
        'name': name,
        if (storeAtNodeId != null) 'storeAtNodeId': storeAtNodeId,
        'rules': rules.map((r) => r.toJson()).toList(),
      };
}

class VariableBindingEntry {
  final String? sourceNodeId;
  final String formFieldKey;

  const VariableBindingEntry({this.sourceNodeId, required this.formFieldKey});

  factory VariableBindingEntry.fromJson(Map<String, dynamic> json) =>
      VariableBindingEntry(
        sourceNodeId: json['sourceNodeId'] as String?,
        formFieldKey: json['formFieldKey'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        if (sourceNodeId != null) 'sourceNodeId': sourceNodeId,
        'formFieldKey': formFieldKey,
      };
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
    final vbRaw = json['variableBindings'] as Map<String, dynamic>? ?? {};
    final vb = vbRaw.map(
      (k, v) => MapEntry(k, VariableBindingEntry.fromJson(v as Map<String, dynamic>)),
    );
    return NodeLetterAssignment(
      id: json['id'] as String? ?? '',
      flowNodeId: json['flowNodeId'] as String? ?? '',
      letterTemplateId: json['letterTemplateId'] as String? ?? '',
      letterName: json['letterName'] as String? ?? '',
      letterVariables: (json['letterVariables'] as List<dynamic>? ?? []).cast<String>(),
      autoGenerateOnApprove: json['autoGenerateOnApprove'] as bool? ?? false,
      allowBeforeApprove: json['allowBeforeApprove'] as bool? ?? true,
      variableBindings: vb,
    );
  }
}

class StepGeneratedLetter {
  final String id;
  final String assignmentId;
  final String letterTemplateId;
  final String letterName;
  final String generatedContent;
  final String trigger;
  final String generatedById;
  final DateTime? createdAt;

  const StepGeneratedLetter({
    required this.id,
    required this.assignmentId,
    required this.letterTemplateId,
    required this.letterName,
    required this.generatedContent,
    required this.trigger,
    required this.generatedById,
    this.createdAt,
  });

  factory StepGeneratedLetter.fromJson(Map<String, dynamic> json) =>
      StepGeneratedLetter(
        id: json['id'] as String? ?? '',
        assignmentId: json['assignmentId'] as String? ?? '',
        letterTemplateId: json['letterTemplateId'] as String? ?? '',
        letterName: json['letterName'] as String? ?? '',
        generatedContent: json['generatedContent'] as String? ?? '',
        trigger: json['trigger'] as String? ?? 'manual',
        generatedById: json['generatedById'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
