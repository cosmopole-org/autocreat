import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../models/form_definition.dart';
import '../api_client.dart';

class FormRepository {
  final ApiClient _apiClient;

  FormRepository(this._apiClient);

  Future<List<FormDefinition>> getForms({String? companyId}) async {
    try {
      final response = await _apiClient.get(
        AppConstants.formsEndpoint,
        queryParameters: companyId != null ? {'companyId': companyId} : null,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => FormDefinition.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FormDefinition> getForm(String id) async {
    try {
      final response =
          await _apiClient.get('${AppConstants.formsEndpoint}/$id');
      return FormDefinition.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FormDefinition> createForm(Map<String, dynamic> data) async {
    try {
      final response =
          await _apiClient.post(AppConstants.formsEndpoint, data: data);
      return FormDefinition.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FormDefinition> updateForm(String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _apiClient.put('${AppConstants.formsEndpoint}/$id', data: data);
      return FormDefinition.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteForm(String id) async {
    try {
      await _apiClient.delete('${AppConstants.formsEndpoint}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
