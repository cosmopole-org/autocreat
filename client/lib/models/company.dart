import 'package:freezed_annotation/freezed_annotation.dart';

part 'company.freezed.dart';
part 'company.g.dart';

@freezed
class Company with _$Company {
  const factory Company({
    required String id,
    required String name,
    String? logo,
    String? description,
    String? website,
    String? industry,
    String? ownerId,
    @Default('active') String status,
    @Default(0) int memberCount,
    @Default(0) int flowCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Company;

  factory Company.fromJson(Map<String, dynamic> json) => _$CompanyFromJson(json);
}
