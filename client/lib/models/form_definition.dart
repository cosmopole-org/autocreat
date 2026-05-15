import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/mock_ui_text.dart';

part 'form_definition.freezed.dart';
part 'form_definition.g.dart';

enum FormFieldType {
  text,
  number,
  textarea,
  dropdown,
  multiselect,
  checkbox,
  radio,
  date,
  time,
  file,
  image,
  color,
  switchField,
  table,
  rating,
  signature,
}

extension FormFieldTypeExt on FormFieldType {
  String get displayName {
    switch (this) {
      case FormFieldType.text: return MockUiText.textField;
      case FormFieldType.number: return MockUiText.number;
      case FormFieldType.textarea: return MockUiText.textArea;
      case FormFieldType.dropdown: return MockUiText.dropdown;
      case FormFieldType.multiselect: return MockUiText.multiSelect;
      case FormFieldType.checkbox: return MockUiText.checkbox;
      case FormFieldType.radio: return MockUiText.radioGroup;
      case FormFieldType.date: return MockUiText.datePicker;
      case FormFieldType.time: return MockUiText.timePicker;
      case FormFieldType.file: return MockUiText.fileUpload;
      case FormFieldType.image: return MockUiText.imageUpload;
      case FormFieldType.color: return MockUiText.colorPicker;
      case FormFieldType.switchField: return MockUiText.switchText;
      case FormFieldType.table: return MockUiText.table;
      case FormFieldType.rating: return MockUiText.rating;
      case FormFieldType.signature: return MockUiText.signature;
    }
  }
}

@freezed
class FormFieldOption with _$FormFieldOption {
  const factory FormFieldOption({
    required String value,
    required String label,
  }) = _FormFieldOption;

  factory FormFieldOption.fromJson(Map<String, dynamic> json) =>
      _$FormFieldOptionFromJson(json);
}

@freezed
class FormFieldValidation with _$FormFieldValidation {
  const factory FormFieldValidation({
    int? minLength,
    int? maxLength,
    double? min,
    double? max,
    String? pattern,
    String? patternMessage,
    bool? isEmail,
    bool? isUrl,
    bool? isPhone,
  }) = _FormFieldValidation;

  factory FormFieldValidation.fromJson(Map<String, dynamic> json) =>
      _$FormFieldValidationFromJson(json);
}

@freezed
class AppFormField with _$AppFormField {
  const factory AppFormField({
    required String id,
    required FormFieldType type,
    required String label,
    String? placeholder,
    String? helpText,
    @Default(false) bool required,
    @Default(false) bool readOnly,
    @Default(false) bool hidden,
    dynamic defaultValue,
    @Default([]) List<FormFieldOption> options,
    FormFieldValidation? validation,
    String? modelFieldBinding,
    int? order,
    Map<String, dynamic>? metadata,
  }) = _AppFormField;

  factory AppFormField.fromJson(Map<String, dynamic> json) =>
      _$AppFormFieldFromJson(json);
}

@freezed
class FormDefinition with _$FormDefinition {
  const factory FormDefinition({
    required String id,
    required String name,
    String? description,
    String? companyId,
    String? modelId,
    @Default([]) List<AppFormField> fields,
    @Default('draft') String status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FormDefinition;

  factory FormDefinition.fromJson(Map<String, dynamic> json) =>
      _$FormDefinitionFromJson(json);
}
