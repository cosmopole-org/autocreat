import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../models/model_definition.dart';
import '../api_client.dart';

class ModelRepository {
  final ApiClient _apiClient;

  ModelRepository(this._apiClient);

  Future<List<ModelDefinition>> getModels({String? companyId}) async {
    try {
      final response = await _apiClient.get(
        AppConstants.modelsEndpoint,
        queryParameters: companyId != null ? {'companyId': companyId} : null,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ModelDefinition.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ModelDefinition> getModel(String id) async {
    try {
      final response =
          await _apiClient.get('${AppConstants.modelsEndpoint}/$id');
      return ModelDefinition.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ModelDefinition> createModel(Map<String, dynamic> data) async {
    try {
      final response =
          await _apiClient.post(AppConstants.modelsEndpoint, data: data);
      return ModelDefinition.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ModelDefinition> updateModel(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient
          .put('${AppConstants.modelsEndpoint}/$id', data: data);
      return ModelDefinition.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteModel(String id) async {
    try {
      await _apiClient.delete('${AppConstants.modelsEndpoint}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
