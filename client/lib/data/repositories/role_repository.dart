import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../models/role.dart';
import '../api_client.dart';

class RoleRepository {
  final ApiClient _apiClient;

  RoleRepository(this._apiClient);

  Future<List<Role>> getRoles({String? companyId}) async {
    try {
      final response = await _apiClient.get(
        AppConstants.rolesEndpoint,
        queryParameters: companyId != null ? {'companyId': companyId} : null,
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => Role.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Role> getRole(String id) async {
    try {
      final response =
          await _apiClient.get('${AppConstants.rolesEndpoint}/$id');
      return Role.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Role> createRole(Map<String, dynamic> data) async {
    try {
      final response =
          await _apiClient.post(AppConstants.rolesEndpoint, data: data);
      return Role.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Role> updateRole(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient
          .put('${AppConstants.rolesEndpoint}/$id', data: data);
      return Role.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      await _apiClient.delete('${AppConstants.rolesEndpoint}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
