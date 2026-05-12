import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../models/company.dart';
import '../api_client.dart';

class CompanyRepository {
  final ApiClient _apiClient;

  CompanyRepository(this._apiClient);

  Future<List<Company>> getCompanies() async {
    try {
      final response = await _apiClient.get(AppConstants.companiesEndpoint);
      final list = response.data as List<dynamic>;
      return list.map((e) => Company.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Company> getCompany(String id) async {
    try {
      final response = await _apiClient.get('${AppConstants.companiesEndpoint}/$id');
      return Company.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Company> createCompany(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(AppConstants.companiesEndpoint, data: data);
      return Company.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Company> updateCompany(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('${AppConstants.companiesEndpoint}/$id', data: data);
      return Company.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteCompany(String id) async {
    try {
      await _apiClient.delete('${AppConstants.companiesEndpoint}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
