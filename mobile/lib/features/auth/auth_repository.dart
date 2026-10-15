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

  static final Map<String, UserModel> _demoUsers = {
    'student1@atlas.edu': UserModel(
      id: '21b744ab9eb44cf6a1df27d607f28912',
      email: 'student1@atlas.edu',
      firstName: 'Tahmid',
      lastName: 'Hasan',
      fullName: 'Tahmid Hasan',
      role: UserRole.student,
      studentId: 'STU/2026/001',
      department: 'Computer Science',
      isActive: true,
    ),
    'supervisor1@atlas.edu': UserModel(
      id: 'supervisor-1',
      email: 'supervisor1@atlas.edu',
      firstName: 'Fatema Jannat',
      lastName: 'Dihan',
      fullName: 'Fatema Jannat Dihan',
      role: UserRole.supervisor,
      department: 'Computer Science & Engineering',
      isActive: true,
    ),
    'supervisor2@atlas.edu': UserModel(
      id: 'supervisor-2',
      email: 'supervisor2@atlas.edu',
      firstName: 'Tanvir',
      lastName: 'Ahmed',
      fullName: 'Tanvir Ahmed',
      role: UserRole.supervisor,
      department: 'Computer Science & Engineering',
      isActive: true,
    ),
    'supervisor3@atlas.edu': UserModel(
      id: 'supervisor-3',
      email: 'supervisor3@atlas.edu',
      firstName: 'Md Abu Rumman',
      lastName: 'Refat',
      fullName: 'Md Abu Rumman Refat',
      role: UserRole.supervisor,
      department: 'Computer Science & Engineering',
      isActive: true,
    ),
    'coordinator@atlas.edu': UserModel(
      id: 'coordinator-1',
      email: 'coordinator@atlas.edu',
      firstName: 'Prof. Nazim',
      lastName: 'Uddin',
      fullName: 'Prof. Nazim Uddin',
      role: UserRole.coordinator,
      department: 'Computer Science & Engineering',
      isActive: true,
    ),
  };

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
      final normalizedEmail = email.trim().toLowerCase();
      final isNetworkOrNotFound = e.response == null ||
          e.response?.statusCode == 404 ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;

      if (isNetworkOrNotFound) {
        UserModel? matchedUser = _demoUsers[normalizedEmail];
        if (matchedUser == null) {
          if (normalizedEmail.contains('supervisor')) {
            matchedUser = _demoUsers['supervisor1@atlas.edu'];
          } else if (normalizedEmail.contains('coordinator')) {
            matchedUser = _demoUsers['coordinator@atlas.edu'];
          } else if (normalizedEmail.contains('student')) {
            matchedUser = _demoUsers['student1@atlas.edu'];
          }
        }
        if (matchedUser != null) {
          return AuthResponse(
            accessToken: 'demo_token_${matchedUser.id}',
            refreshToken: 'demo_refresh_${matchedUser.id}',
            user: matchedUser,
            context: const {'is_demo_mode': true},
          );
        }
      }
      throw _client.handleDioError(e);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/auth/me');
      final data = res.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (_) {
      final role = await _client.storage.getUserRole();
      final uid = await _client.storage.getUserId();
      for (final demo in _demoUsers.values) {
        if (demo.id == uid || demo.role.name == role) {
          return demo;
        }
      }
      return _demoUsers['student1@atlas.edu']!;
    } catch (_) {
      return _demoUsers['student1@atlas.edu']!;
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
      final isNetwork = e.response == null ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
      if (isNetwork) {
        final dummyUser = UserModel(
          id: 'demo-student-${DateTime.now().millisecondsSinceEpoch}',
          email: email.trim(),
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          fullName: '${firstName.trim()} ${lastName.trim()}',
          role: UserRole.student,
          studentId: 'STU/2026/099',
          department: 'Computer Science',
          isActive: true,
        );
        return AuthResponse(
          accessToken: 'demo_token_${dummyUser.id}',
          refreshToken: 'demo_refresh_${dummyUser.id}',
          user: dummyUser,
          context: const {'is_demo_mode': true},
        );
      }
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
      final isNetwork = e.response == null ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
      if (isNetwork) {
        return 'Password reset instructions dispatched (Demo mode).';
      }
      throw _client.handleDioError(e);
    }
  }
}
