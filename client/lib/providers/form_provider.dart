import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/demo_data.dart';
import '../data/repositories/form_repository.dart';
import '../models/form_definition.dart';
import 'auth_provider.dart';
import 'demo_provider.dart';

final formRepositoryProvider = Provider<FormRepository>((ref) {
  return FormRepository(ref.watch(apiClientProvider));
});

final formsProvider =
    FutureProvider.family<List<FormDefinition>, String?>((ref, companyId) async {
  final isDemo = ref.watch(isDemoModeProvider);
  if (isDemo) return DemoData.forms.map(FormDefinition.fromJson).toList();
  return ref.watch(formRepositoryProvider).getForms(companyId: companyId);
});

final formDetailProvider =
    FutureProvider.family<FormDefinition, String>((ref, id) async {
  final isDemo = ref.watch(isDemoModeProvider);
  if (isDemo) {
    final match = DemoData.forms.firstWhere(
      (f) => f['id'] == id,
      orElse: () => DemoData.forms.first,
    );
    return FormDefinition.fromJson(match);
  }
  return ref.watch(formRepositoryProvider).getForm(id);
});

class FormEditorNotifier extends Notifier<FormEditorState> {
  @override
  FormEditorState build() => FormEditorState.empty();

  void loadForm(FormDefinition form) {
    state = FormEditorState(
      form: form,
      fields: List.from(form.fields),
      selectedFieldId: null,
      isDirty: false,
    );
  }

  void newForm(String companyId) {
    state = FormEditorState(
      form: FormDefinition(
        id: '',
        name: 'Untitled Form',
        companyId: companyId,
      ),
      fields: [],
      selectedFieldId: null,
      isDirty: false,
    );
  }

  void addField(AppFormField field) {
    state = state.copyWith(
      fields: [...state.fields, field],
      isDirty: true,
    );
  }

  void updateField(AppFormField field) {
    state = state.copyWith(
      fields: state.fields.map((f) => f.id == field.id ? field : f).toList(),
      isDirty: true,
    );
  }

  void deleteField(String fieldId) {
    state = state.copyWith(
      fields: state.fields.where((f) => f.id != fieldId).toList(),
      selectedFieldId:
          state.selectedFieldId == fieldId ? null : state.selectedFieldId,
      isDirty: true,
    );
  }

  void selectField(String? fieldId) {
    state = state.copyWith(selectedFieldId: fieldId);
  }

  void reorderFields(int oldIndex, int newIndex) {
    final fields = List<AppFormField>.from(state.fields);
    final item = fields.removeAt(oldIndex);
    fields.insert(newIndex, item);
    state = state.copyWith(fields: fields, isDirty: true);
  }

  void updateFormMeta(String name, String? description) {
    if (state.form == null) return;
    state = state.copyWith(
      form: state.form!.copyWith(name: name, description: description),
      isDirty: true,
    );
  }

  Future<FormDefinition> save(FormRepository repo) async {
    if (state.form == null) throw Exception('No form loaded');
    final formData = state.form!.copyWith(fields: state.fields);
    FormDefinition saved;
    if (formData.id.isEmpty) {
      saved = await repo.createForm(formData.toJson());
    } else {
      saved = await repo.updateForm(formData.id, formData.toJson());
    }
    state = state.copyWith(form: saved, isDirty: false);
    return saved;
  }
}

class FormEditorState {
  final FormDefinition? form;
  final List<AppFormField> fields;
  final String? selectedFieldId;
  final bool isDirty;

  const FormEditorState({
    this.form,
    required this.fields,
    this.selectedFieldId,
    required this.isDirty,
  });

  factory FormEditorState.empty() => const FormEditorState(
        fields: [],
        isDirty: false,
      );

  FormEditorState copyWith({
    FormDefinition? form,
    List<AppFormField>? fields,
    String? selectedFieldId,
    bool? isDirty,
  }) {
    return FormEditorState(
      form: form ?? this.form,
      fields: fields ?? this.fields,
      selectedFieldId: selectedFieldId ?? this.selectedFieldId,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  AppFormField? get selectedField {
    if (selectedFieldId == null) return null;
    try {
      return fields.firstWhere((f) => f.id == selectedFieldId);
    } catch (_) {
      return null;
    }
  }
}

final formEditorProvider =
    NotifierProvider<FormEditorNotifier, FormEditorState>(
        FormEditorNotifier.new);
