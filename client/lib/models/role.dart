import 'package:freezed_annotation/freezed_annotation.dart';

part 'role.freezed.dart';
part 'role.g.dart';

@freezed
class Permission with _$Permission {
  const factory Permission({
    required String resource,
    @Default(false) bool canCreate,
    @Default(false) bool canRead,
    @Default(false) bool canUpdate,
    @Default(false) bool canDelete,
    @Default([]) List<String> customActions,
  }) = _Permission;

  factory Permission.fromJson(Map<String, dynamic> json) =>
      _$PermissionFromJson(json);
}

@freezed
class RuleSet with _$RuleSet {
  const factory RuleSet({
    required String id,
    required String name,
    String? description,
    @Default([]) List<Map<String, dynamic>> conditions,
    @Default('allow') String action,
  }) = _RuleSet;

  factory RuleSet.fromJson(Map<String, dynamic> json) =>
      _$RuleSetFromJson(json);
}

@freezed
class Role with _$Role {
  const factory Role({
    required String id,
    required String name,
    String? description,
    String? companyId,
    @Default('member') String level,
    @Default([]) List<Permission> permissions,
    @Default([]) List<RuleSet> ruleSets,
    @Default(true) bool isActive,
    @Default(0) int memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Role;

  factory Role.fromJson(Map<String, dynamic> json) => _$RoleFromJson(json);
}
