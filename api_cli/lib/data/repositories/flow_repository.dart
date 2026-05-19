import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../models/flow.dart';
import '../api_client.dart';

const _instancesEndpoint = '/instances';

class FlowRepository {
  final ApiClient _apiClient;

  FlowRepository(this._apiClient);

  Future<List<Flow>> getFlows({String? companyId}) async {
    try {
      final response = await _apiClient.get(
        AppConstants.flowsEndpoint,
        queryParameters: companyId != null ? {'companyId': companyId} : null,
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => Flow.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Flow> getFlow(String id) async {
    try {
      final response = await _apiClient.get('${AppConstants.flowsEndpoint}/$id');
      return Flow.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Flow> createFlow(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(AppConstants.flowsEndpoint, data: data);
      return Flow.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Flow> updateFlow(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('${AppConstants.flowsEndpoint}/$id', data: data);
      return Flow.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteFlow(String id) async {
    try {
      await _apiClient.delete('${AppConstants.flowsEndpoint}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Flow> saveFlowGraph(String id, List<FlowNode> nodes, List<FlowEdge> edges) async {
    try {
      final response = await _apiClient.put(
        '${AppConstants.flowsEndpoint}/$id/graph',
        data: {
          'nodes': nodes.map((n) => n.toJson()).toList(),
          'edges': edges.map((e) => e.toJson()).toList(),
        },
      );
      return Flow.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ---------- Flow Instances ----------

  Future<List<FlowInstance>> listInstances({String? companyId}) async {
    try {
      final response = await _apiClient.get(
        _instancesEndpoint,
        queryParameters: companyId != null ? {'companyId': companyId} : null,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => FlowInstance.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FlowInstance> startInstance(String flowId, {String? companyId}) async {
    try {
      final response = await _apiClient.post(
        _instancesEndpoint,
        data: {
          'flowId': flowId,
          if (companyId != null) 'companyId': companyId,
        },
      );
      return FlowInstance.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FlowInstance> getInstance(String id) async {
    try {
      final response = await _apiClient.get('$_instancesEndpoint/$id');
      return FlowInstance.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyTasks({String? companyId}) async {
    try {
      final response = await _apiClient.get(
        '$_instancesEndpoint/my-tasks',
        queryParameters: companyId != null ? {'companyId': companyId} : null,
      );
      final list = response.data as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FlowInstance> advanceInstance(
      String id, Map<String, dynamic> formData) async {
    try {
      final response = await _apiClient.post(
        '$_instancesEndpoint/$id/advance',
        data: {'formData': formData},
      );
      return FlowInstance.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FlowInstance> rejectInstance(String id,
      {String? comment, String? rejectToNodeId}) async {
    try {
      final response = await _apiClient.post(
        '$_instancesEndpoint/$id/reject',
        data: {
          if (comment != null) 'comment': comment,
          if (rejectToNodeId != null) 'rejectToNodeId': rejectToNodeId,
        },
      );
      return FlowInstance.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
