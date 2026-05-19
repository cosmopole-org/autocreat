import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../models/task.dart';
import '../api_client.dart';

class TaskRepository {
  final ApiClient _apiClient;

  TaskRepository(this._apiClient);

  Future<List<MyTask>> getMyTasks({String? companyId}) async {
    try {
      final response = await _apiClient.get(
        AppConstants.myTasksEndpoint,
        queryParameters: companyId != null ? {'companyId': companyId} : null,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => MyTask.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<MyTask> getTaskDetail(
      {required String instanceId,
      required String nodeId,
      String? companyId}) async {
    try {
      final response = await _apiClient.get(
        AppConstants.taskDetailEndpoint,
        queryParameters: {
          'instanceId': instanceId,
          'nodeId': nodeId,
          if (companyId != null) 'companyId': companyId,
        },
      );
      return MyTask.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<UserBrief>> getUsersForRole(String roleId) async {
    try {
      final response = await _apiClient
          .get('${AppConstants.rolesEndpoint}/$roleId/role-users');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => UserBrief.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> submitTask({
    required String instanceId,
    required Map<String, dynamic> formData,
    String? nextUserId,
    bool useRoundRobin = false,
  }) async {
    try {
      final response = await _apiClient.post(
        '${AppConstants.instancesEndpoint}/$instanceId/advance',
        data: {
          'formData': formData,
          if (nextUserId != null) 'nextUserId': nextUserId,
          'useRoundRobin': useRoundRobin,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> rejectTask({
    required String instanceId,
    String? comment,
    String? rejectToNodeId,
  }) async {
    try {
      final response = await _apiClient.post(
        '${AppConstants.instancesEndpoint}/$instanceId/reject',
        data: {
          if (comment != null) 'comment': comment,
          if (rejectToNodeId != null) 'rejectToNodeId': rejectToNodeId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
