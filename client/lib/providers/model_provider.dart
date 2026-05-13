import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/demo_data.dart';
import '../data/repositories/model_repository.dart';
import '../models/model_definition.dart';
import 'auth_provider.dart';
import 'demo_provider.dart';

final modelRepositoryProvider = Provider<ModelRepository>((ref) {
  return ModelRepository(ref.watch(apiClientProvider));
});

final modelsProvider =
    FutureProvider.family<List<ModelDefinition>, String?>((ref, companyId) async {
  final isDemo = ref.watch(isDemoModeProvider);
  if (isDemo) return DemoData.models.map(ModelDefinition.fromJson).toList();
  return ref.watch(modelRepositoryProvider).getModels(companyId: companyId);
});

final modelDetailProvider =
    FutureProvider.family<ModelDefinition, String>((ref, id) async {
  final isDemo = ref.watch(isDemoModeProvider);
  if (isDemo) {
    final match = DemoData.models.firstWhere(
      (m) => m['id'] == id,
      orElse: () => DemoData.models.first,
    );
    return ModelDefinition.fromJson(match);
  }
  return ref.watch(modelRepositoryProvider).getModel(id);
});

class ModelEditorNotifier extends Notifier<ModelEditorState> {
  @override
  ModelEditorState build() => ModelEditorState.empty();

  void loadModel(ModelDefinition model) {
    state = ModelEditorState(
      model: model,
      fields: List.from(model.fields),
      isDirty: false,
    );
  }

  void newModel(String companyId) {
    state = ModelEditorState(
      model: ModelDefinition(id: '', name: 'New Model', companyId: companyId),
      fields: [],
      isDirty: false,
    );
  }

  void addField(ModelField field) {
    state = state.copyWith(fields: [...state.fields, field], isDirty: true);
  }

  void updateField(ModelField field) {
    state = state.copyWith(
      fields: state.fields.map((f) => f.id == field.id ? field : f).toList(),
      isDirty: true,
    );
  }

  void deleteField(String fieldId) {
    state = state.copyWith(
      fields: state.fields.where((f) => f.id != fieldId).toList(),
      isDirty: true,
    );
  }

  void updateModelMeta(String name, String? description) {
    if (state.model == null) return;
    state = state.copyWith(
      model: state.model!.copyWith(name: name, description: description),
      isDirty: true,
    );
  }

  Future<ModelDefinition> save(ModelRepository repo) async {
    if (state.model == null) throw Exception('No model loaded');
    final modelData = state.model!.copyWith(fields: state.fields);
    ModelDefinition saved;
    if (modelData.id.isEmpty) {
      saved = await repo.createModel(modelData.toJson());
    } else {
      saved = await repo.updateModel(modelData.id, modelData.toJson());
    }
    state = state.copyWith(model: saved, isDirty: false);
    return saved;
  }
}

class ModelEditorState {
  final ModelDefinition? model;
  final List<ModelField> fields;
  final bool isDirty;

  const ModelEditorState({
    this.model,
    required this.fields,
    required this.isDirty,
  });

  factory ModelEditorState.empty() =>
      const ModelEditorState(fields: [], isDirty: false);

  ModelEditorState copyWith({
    ModelDefinition? model,
    List<ModelField>? fields,
    bool? isDirty,
  }) {
    return ModelEditorState(
      model: model ?? this.model,
      fields: fields ?? this.fields,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

final modelEditorProvider =
    NotifierProvider<ModelEditorNotifier, ModelEditorState>(
        ModelEditorNotifier.new);
