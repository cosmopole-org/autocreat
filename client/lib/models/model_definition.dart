import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/mock_ui_text.dart';

part 'model_definition.freezed.dart';
part 'model_definition.g.dart';

enum ModelFieldType {
  string,
  integer,
  float,
  boolean,
  date,
  dateTime,
  file,
  reference,
}

extension ModelFieldTypeExt on ModelFieldType {
  String get displayName {
    switch (this) {
      case ModelFieldType.string: return MockUiText.string;
      case ModelFieldType.integer: return MockUiText.integer;
      case ModelFieldType.float: return MockUiText.float;
      case ModelFieldType.boolean: return MockUiText.boolean;
      case ModelFieldType.date: return MockUiText.date;
      case ModelFieldType.dateTime: return MockUiText.dateTime;
      case ModelFieldType.file: return MockUiText.file;
      case ModelFieldType.reference: return MockUiText.reference;
    }
  }
}

@freezed
class ModelField with _$ModelField {
  const factory ModelField({
    required String id,
    required String name,
    required ModelFieldType type,
    @Default(false) bool required,
    @Default(false) bool unique,
    dynamic defaultValue,
    String? referenceModelId,
    String? description,
    int? order,
  }) = _ModelField;

  factory ModelField.fromJson(Map<String, dynamic> json) =>
      _$ModelFieldFromJson(json);
}

@freezed
class ModelDefinition with _$ModelDefinition {
  const factory ModelDefinition({
    required String id,
    required String name,
    String? description,
    String? companyId,
    @Default([]) List<ModelField> fields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ModelDefinition;

  factory ModelDefinition.fromJson(Map<String, dynamic> json) =>
      _$ModelDefinitionFromJson(json);
}
