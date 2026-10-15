import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../errors/api_exceptions.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService storage;
  void Function()? onSessionExpired;

  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshCompleters = [];

  ApiClient({
    required this.storage,
    String? customBaseUrl,
    this.onSessionExpired,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: customBaseUrl ?? ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // If 401 Unauthorized, attempt refresh token rotation once
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login') &&
              !error.requestOptions.path.contains('/auth/refresh')) {
            final newAccessToken = await _handleTokenRefresh();
            if (newAccessToken != null) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';
              try {
                final response = await dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.reject(error);
              }
            } else {
              await storage.clearAuth();
              onSessionExpired?.call();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _handleTokenRefresh() async {
    if (_isRefreshing) {
      final completer = Completer<String?>();
      _refreshCompleters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null) {
        _notifyCompleters(null);
        return null;
      }

      final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      final res = await refreshDio.post(
        '${ApiConfig.apiMobileV1}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        final newAccess = res.data['data']['access_token'] as String;
        final newRefresh = res.data['data']['refresh_token'] as String;
        await storage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
        _notifyCompleters(newAccess);
        return newAccess;
      }
    } catch (_) {
      // Refresh failed
    } finally {
      _isRefreshing = false;
    }

    _notifyCompleters(null);
    return null;
  }

  void _notifyCompleters(String? token) {
    for (final c in _refreshCompleters) {
      if (!c.isCompleted) c.complete(token);
    }
    _refreshCompleters.clear();
  }

  ApiException handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException();
    }

    final response = error.response;
    if (response != null) {
      final data = response.data;
      String message = 'An unexpected server error occurred.';
      List<String>? errors;

      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ?? message;
        if (data['errors'] is List) {
          errors = (data['errors'] as List).map((e) => e.toString()).toList();
        }
      }

      switch (response.statusCode) {
        case 401:
          return UnauthorizedException(message: message);
        case 403:
          return ForbiddenException(message: message);
        case 409:
          return ConflictException(message: message);
        default:
          return ApiException(
            message: message,
            statusCode: response.statusCode,
            errors: errors,
          );
      }
    }

    return ApiException(message: error.message ?? 'Unknown network failure');
  }
}
