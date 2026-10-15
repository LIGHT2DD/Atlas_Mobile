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
          options.baseUrl = ApiConfig.baseUrl;
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

    // Auto-retry interceptor for transient network failures on idempotent GET requests
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) async {
          final requestOptions = error.requestOptions;
          final retryCount = (requestOptions.extra['retry_count'] as int?) ?? 0;

          final isGet = requestOptions.method.toUpperCase() == 'GET';
          final isTransient = error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              (error.response?.statusCode != null &&
                  [502, 503, 504].contains(error.response!.statusCode));

          if (isGet && isTransient && retryCount < 2) {
            requestOptions.extra['retry_count'] = retryCount + 1;
            final backoffMs = (retryCount + 1) * 600;
            await Future<void>.delayed(Duration(milliseconds: backoffMs));
            try {
              final response = await dio.fetch(requestOptions);
              return handler.resolve(response);
            } catch (e) {
              if (e is DioException) {
                return handler.next(e);
              }
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
      // Refresh failed: clear invalid session
      await storage.clearAuth();
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
      String? extractedMessage;
      List<String>? errors;

      if (data is Map<String, dynamic>) {
        if (data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
          extractedMessage = (data['message'] as String).trim();
        } else if (data['detail'] is String && (data['detail'] as String).trim().isNotEmpty) {
          extractedMessage = (data['detail'] as String).trim();
        } else if (data['detail'] is List) {
          final listMsgs = (data['detail'] as List).map((e) {
            if (e is Map && e['msg'] != null) return e['msg'].toString();
            return e.toString();
          }).where((s) => s.isNotEmpty).toList();
          if (listMsgs.isNotEmpty) {
            extractedMessage = listMsgs.join(', ');
            errors = listMsgs;
          }
        } else if (data['error'] is String && (data['error'] as String).trim().isNotEmpty) {
          extractedMessage = (data['error'] as String).trim();
        }

        if (data['errors'] is List) {
          errors = (data['errors'] as List).map((e) => e.toString()).toList();
          if (extractedMessage == null && errors.isNotEmpty) {
            extractedMessage = errors.first;
          }
        }
      } else if (data is String && data.trim().isNotEmpty) {
        final trimmed = data.trim();
        if (!trimmed.toLowerCase().contains('<html') && !trimmed.toLowerCase().contains('<!doctype')) {
          extractedMessage = trimmed;
        }
      }

      final statusCode = response.statusCode;
      String fallbackMessage;
      switch (statusCode) {
        case 400:
          fallbackMessage = 'Invalid request. Please verify your credentials or input.';
          break;
        case 401:
          fallbackMessage = 'Invalid institutional email or password.';
          break;
        case 403:
          fallbackMessage = 'You do not have permission to perform this action.';
          break;
        case 404:
          fallbackMessage = 'Requested account or resource was not found.';
          break;
        case 409:
          fallbackMessage = 'A data conflict occurred. Please refresh and try again.';
          break;
        case 422:
          fallbackMessage = 'Validation failed. Please check the entered data.';
          break;
        case 500:
        case 502:
        case 503:
        case 504:
          fallbackMessage = 'ATLAS server is currently unavailable. Please ensure the backend is running.';
          break;
        default:
          fallbackMessage = 'An unexpected server error occurred.';
      }

      final message = extractedMessage ?? fallbackMessage;

      switch (statusCode) {
        case 401:
          return UnauthorizedException(message: message);
        case 403:
          return ForbiddenException(message: message);
        case 409:
          return ConflictException(message: message);
        default:
          return ApiException(
            message: message,
            statusCode: statusCode,
            errors: errors,
          );
      }
    }

    final netMsg = (error.message != null &&
            error.message!.isNotEmpty &&
            !error.message!.contains('XMLHttpRequest'))
        ? error.message!
        : 'Cannot connect to ATLAS server. Please check your network or ensure the backend is running.';
    return NetworkException(message: netMsg);
  }
}
