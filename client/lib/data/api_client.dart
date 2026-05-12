import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.fullBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage, _dio),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugLog(obj.toString()),
      ),
    ]);
  }

  void debugLog(String message) {
    // ignore: avoid_print
    print('[ApiClient] $message');
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path,
        queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> uploadFile<T>(
    String path,
    FormData formData, {
    void Function(int, int)? onSendProgress,
  }) {
    return _dio.post<T>(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onSendProgress,
    );
  }
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken =
            await _storage.read(key: AppConstants.refreshTokenKey);
        if (refreshToken == null) {
          handler.next(err);
          return;
        }

        final response = await _dio.post(
          AppConstants.refreshEndpoint,
          data: {'refreshToken': refreshToken},
        );

        final newToken = response.data['accessToken'];
        await _storage.write(
            key: AppConstants.accessTokenKey, value: newToken);

        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);
        return;
      } catch (_) {
        await _storage.deleteAll();
      }
    }
    handler.next(err);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  factory ApiException.fromDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    String message = 'An error occurred';

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? message;
    } else if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = 'Request timeout';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return ApiException(message: message, statusCode: statusCode, data: data);
  }

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}
