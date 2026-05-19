import 'package:freezed_annotation/freezed_annotation.dart';

part 'letter_template.freezed.dart';
part 'letter_template.g.dart';

@freezed
class LetterTemplate with _$LetterTemplate {
  const factory LetterTemplate({
    required String id,
    required String name,
    String? description,
    String? companyId,
    @Default('') String content,
    @Default({}) Map<String, dynamic> deltaContent,
    @Default([]) List<String> variables,
    @Default('draft') String status,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _LetterTemplate;

  factory LetterTemplate.fromJson(Map<String, dynamic> json) =>
      _$LetterTemplateFromJson(json);
}
