import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../models/user.dart';
import '../api_client.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<List<User>> getUsers({String? companyId}) async {
    try {
      final response = await _apiClient.get(
        AppConstants.usersEndpoint,
        queryParameters: companyId != null ? {'companyId': companyId} : null,
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<User> getUser(String id) async {
    try {
      final response =
          await _apiClient.get('${AppConstants.usersEndpoint}/$id');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    try {
      final response =
          await _apiClient.post(AppConstants.usersEndpoint, data: data);
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<User> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient
          .put('${AppConstants.usersEndpoint}/$id', data: data);
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _apiClient.delete('${AppConstants.usersEndpoint}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<User> assignRole(String userId, String roleId) async {
    try {
      final response = await _apiClient.patch(
        '${AppConstants.usersEndpoint}/$userId/role',
        data: {'roleId': roleId},
      );
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
