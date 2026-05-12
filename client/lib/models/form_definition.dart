import 'package:freezed_annotation/freezed_annotation.dart';

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
      case FormFieldType.text: return 'Text';
      case FormFieldType.number: return 'Number';
      case FormFieldType.textarea: return 'Text Area';
      case FormFieldType.dropdown: return 'Dropdown';
      case FormFieldType.multiselect: return 'Multi-Select';
      case FormFieldType.checkbox: return 'Checkbox';
      case FormFieldType.radio: return 'Radio Group';
      case FormFieldType.date: return 'Date Picker';
      case FormFieldType.time: return 'Time Picker';
      case FormFieldType.file: return 'File Upload';
      case FormFieldType.image: return 'Image Upload';
      case FormFieldType.color: return 'Color Picker';
      case FormFieldType.switchField: return 'Switch';
      case FormFieldType.table: return 'Table';
      case FormFieldType.rating: return 'Rating';
      case FormFieldType.signature: return 'Signature';
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
class FormField with _$FormField {
  const factory FormField({
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
  }) = _FormField;

  factory FormField.fromJson(Map<String, dynamic> json) =>
      _$FormFieldFromJson(json);
}

@freezed
class FormDefinition with _$FormDefinition {
  const factory FormDefinition({
    required String id,
    required String name,
    String? description,
    String? companyId,
    String? modelId,
    @Default([]) List<FormField> fields,
    @Default('draft') String status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FormDefinition;

  factory FormDefinition.fromJson(Map<String, dynamic> json) =>
      _$FormDefinitionFromJson(json);
}
