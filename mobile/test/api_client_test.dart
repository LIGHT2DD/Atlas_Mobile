import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:atlas_mobile/core/network/api_client.dart';
import 'package:atlas_mobile/core/storage/secure_storage.dart';
import 'package:atlas_mobile/core/errors/api_exceptions.dart';

void main() {
  group('ApiClient Core & Interceptor Tests', () {
    late SecureStorageService storage;
    late ApiClient client;

    setUp(() {
      storage = SecureStorageService();
      client = ApiClient(storage: storage);
    });

    test('ApiClient initializes with correct timeouts and headers', () {
      expect(client.dio.options.headers['Accept'], equals('application/json'));
      expect(client.dio.options.connectTimeout, equals(const Duration(seconds: 15)));
      expect(client.dio.options.receiveTimeout, equals(const Duration(seconds: 15)));
      expect(client.dio.interceptors.length, greaterThanOrEqualTo(2));
    });

    test('handleDioError maps timeout and network connection errors properly', () {
      final reqOptions = RequestOptions(path: '/test');

      final connectTimeoutError = DioException(
        requestOptions: reqOptions,
        type: DioExceptionType.connectionTimeout,
      );
      expect(client.handleDioError(connectTimeoutError), isA<NetworkException>());

      final connError = DioException(
        requestOptions: reqOptions,
        type: DioExceptionType.connectionError,
      );
      expect(client.handleDioError(connError), isA<NetworkException>());
    });

    test('handleDioError maps HTTP 401, 403 and status codes to appropriate exceptions', () {
      final reqOptions = RequestOptions(path: '/test');

      final unauthorizedError = DioException(
        requestOptions: reqOptions,
        response: Response(
          requestOptions: reqOptions,
          statusCode: 401,
          data: {'message': 'Invalid token'},
        ),
      );
      expect(client.handleDioError(unauthorizedError), isA<UnauthorizedException>());

      final forbiddenError = DioException(
        requestOptions: reqOptions,
        response: Response(
          requestOptions: reqOptions,
          statusCode: 403,
          data: {'message': 'Forbidden access'},
        ),
      );
      expect(client.handleDioError(forbiddenError), isA<ForbiddenException>());

      final notFoundError = DioException(
        requestOptions: reqOptions,
        response: Response(
          requestOptions: reqOptions,
          statusCode: 404,
          data: {'message': 'Resource not found'},
        ),
      );
      final ex = client.handleDioError(notFoundError);
      expect(ex, isA<ApiException>());
      expect(ex.statusCode, equals(404));
    });
  });
}
