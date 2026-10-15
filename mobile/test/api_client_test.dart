import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:atlas_mobile/core/network/api_client.dart';
import 'package:atlas_mobile/core/storage/secure_storage.dart';
import 'package:atlas_mobile/core/errors/api_exceptions.dart';
import 'package:atlas_mobile/core/config/api_config.dart';

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
      expect(client.dio.options.connectTimeout, equals(const Duration(seconds: 5)));
      expect(client.dio.options.receiveTimeout, equals(const Duration(seconds: 8)));
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

    test('handleDioError maps HTTP 409 to ConflictException', () {
      final reqOptions = RequestOptions(path: '/test');
      final conflictError = DioException(
        requestOptions: reqOptions,
        response: Response(
          requestOptions: reqOptions,
          statusCode: 409,
          data: {'message': 'Team name already exists'},
        ),
      );
      final ex = client.handleDioError(conflictError);
      expect(ex, isA<ConflictException>());
      expect(ex.message, equals('Team name already exists'));
    });

    test('handleDioError extracts error details array from validation 422', () {
      final reqOptions = RequestOptions(path: '/submit');
      final valError = DioException(
        requestOptions: reqOptions,
        response: Response(
          requestOptions: reqOptions,
          statusCode: 422,
          data: {
            'detail': [
              {'msg': 'Field "title" cannot be blank'},
              {'msg': 'Field "score" must be greater than 0'}
            ]
          },
        ),
      );
      final ex = client.handleDioError(valError);
      expect(ex.message, contains('Field "title" cannot be blank'));
    });

    test('handleDioError maps 500 and 503 to server unavailable message', () {
      final reqOptions = RequestOptions(path: '/metrics');
      final serverError = DioException(
        requestOptions: reqOptions,
        response: Response(
          requestOptions: reqOptions,
          statusCode: 503,
          data: null,
        ),
      );
      final ex = client.handleDioError(serverError);
      expect(ex.message, contains('ATLAS server is currently unavailable'));
    });

    test('handleDioError maps unknown exception with null response to NetworkException', () {
      final reqOptions = RequestOptions(path: '/ping');
      final unknownError = DioException(
        requestOptions: reqOptions,
        type: DioExceptionType.unknown,
        response: null,
      );
      final ex = client.handleDioError(unknownError);
      expect(ex, isA<NetworkException>());
    });

    test('ApiConfig allows runtime base URL override', () {
      ApiConfig.setCustomBaseUrl('http://custom-host:9000');
      expect(ApiConfig.baseUrl, equals('http://custom-host:9000'));
      ApiConfig.setCustomBaseUrl(null);
    });
  });
}
