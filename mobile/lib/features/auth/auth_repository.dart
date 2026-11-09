import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/user_model.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final Map<String, dynamic>? context;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.context,
  });
}

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<AuthResponse> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
          'remember_me': rememberMe,
        },
      );

      final data = res.data['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      final context = data['context'] as Map<String, dynamic>?;

      return AuthResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
        context: context,
      );
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/auth/me');
      final data = res.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<AuthResponse> registerStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/auth/register',
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'email': email.trim(),
          'password': password,
          'confirm_password': confirmPassword,
        },
      );

      final data = res.data['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      return AuthResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
      );
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('${ApiConfig.apiMobileV1}/auth/logout');
    } catch (_) {
      // Best-effort logout on server
    }
  }

  Future<String> forgotPassword(String email) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/auth/forgot-password',
        data: {'email': email.trim()},
      );
      return res.data['message'] as String? ?? 'Reset email dispatched.';
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
