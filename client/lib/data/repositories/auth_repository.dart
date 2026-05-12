import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';
import '../../models/user.dart';
import '../api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthRepository(this._apiClient, this._storage);

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );
      final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      await _saveTokens(auth.accessToken, auth.refreshToken, auth.user.id);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? companyName,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConstants.registerEndpoint,
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          if (companyName != null) 'companyName': companyName,
          if (phone != null) 'phone': phone,
        },
      );
      final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      await _saveTokens(auth.accessToken, auth.refreshToken, auth.user.id);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<User> getMe() async {
    try {
      final response = await _apiClient.get(AppConstants.meEndpoint);
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(AppConstants.logoutEndpoint);
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: AppConstants.accessTokenKey);
  }

  Future<void> _saveTokens(
      String accessToken, String refreshToken, String userId) async {
    await Future.wait([
      _storage.write(key: AppConstants.accessTokenKey, value: accessToken),
      _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
      _storage.write(key: AppConstants.userIdKey, value: userId),
    ]);
  }
}
