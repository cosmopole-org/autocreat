import 'package:flutter_test/flutter_test.dart';
import 'package:autocreat/data/api_client.dart';
import 'package:dio/dio.dart';

void main() {
  group('ApiException', () {
    test('constructs with message', () {
      final ex = ApiException(message: 'Something went wrong', statusCode: 500);
      expect(ex.message, 'Something went wrong');
      expect(ex.statusCode, 500);
    });

    test('toString includes message and status', () {
      final ex = ApiException(message: 'Not found', statusCode: 404);
      expect(ex.toString(), contains('Not found'));
      expect(ex.toString(), contains('404'));
    });

    test('fromDioError - connection timeout', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      final ex = ApiException.fromDioError(dioErr);
      expect(ex.message, 'Connection timeout');
      expect(ex.statusCode, isNull);
    });

    test('fromDioError - receive timeout', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.receiveTimeout,
      );
      final ex = ApiException.fromDioError(dioErr);
      expect(ex.message, 'Request timeout');
    });

    test('fromDioError - connection error', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );
      final ex = ApiException.fromDioError(dioErr);
      expect(ex.message, 'No internet connection');
    });

    test('fromDioError - server error with message field', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 422,
          data: {'message': 'Validation failed'},
        ),
        type: DioExceptionType.badResponse,
      );
      final ex = ApiException.fromDioError(dioErr);
      expect(ex.message, 'Validation failed');
      expect(ex.statusCode, 422);
    });

    test('fromDioError - server error with error field', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'error': 'Unauthorized'},
        ),
        type: DioExceptionType.badResponse,
      );
      final ex = ApiException.fromDioError(dioErr);
      expect(ex.message, 'Unauthorized');
      expect(ex.statusCode, 401);
    });

    test('fromDioError - unknown error falls back', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.unknown,
      );
      final ex = ApiException.fromDioError(dioErr);
      expect(ex.message, 'An error occurred');
    });
  });
}
