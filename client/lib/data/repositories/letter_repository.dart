import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../models/letter_template.dart';
import '../api_client.dart';

class LetterRepository {
  final ApiClient _apiClient;

  LetterRepository(this._apiClient);

  Future<List<LetterTemplate>> getLetters({String? companyId}) async {
    try {
      final response = await _apiClient.get(
        AppConstants.lettersEndpoint,
        queryParameters: companyId != null ? {'companyId': companyId} : null,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => LetterTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<LetterTemplate> getLetter(String id) async {
    try {
      final response =
          await _apiClient.get('${AppConstants.lettersEndpoint}/$id');
      return LetterTemplate.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<LetterTemplate> createLetter(Map<String, dynamic> data) async {
    try {
      final response =
          await _apiClient.post(AppConstants.lettersEndpoint, data: data);
      return LetterTemplate.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<LetterTemplate> updateLetter(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient
          .put('${AppConstants.lettersEndpoint}/$id', data: data);
      return LetterTemplate.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteLetter(String id) async {
    try {
      await _apiClient.delete('${AppConstants.lettersEndpoint}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
