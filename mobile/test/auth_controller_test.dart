import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas_mobile/core/errors/api_exceptions.dart';
import 'package:atlas_mobile/core/network/api_client.dart';
import 'package:atlas_mobile/core/storage/secure_storage.dart';
import 'package:atlas_mobile/features/auth/auth_controller.dart';
import 'package:atlas_mobile/features/auth/auth_repository.dart';
import 'package:atlas_mobile/shared/models/user_model.dart';

class MockAuthRepository extends AuthRepository {
  MockAuthRepository() : super(ApiClient(storage: SecureStorageService()));

  UserModel? mockUser;
  Exception? errorToThrow;

  @override
  Future<UserModel> getProfile() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return mockUser ??
        UserModel(
          id: 'user-123',
          email: 'student@cstu.edu.bd',
          firstName: 'Tariqul',
          lastName: 'Islam',
          fullName: 'Tariqul Islam',
          role: UserRole.student,
          isActive: true,
        );
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    final user = mockUser ??
        UserModel(
          id: 'user-123',
          email: email,
          firstName: 'Tariqul',
          lastName: 'Islam',
          fullName: 'Tariqul Islam',
          role: UserRole.student,
          isActive: true,
        );
    return AuthResponse(
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      user: user,
    );
  }

  @override
  Future<AuthResponse> registerStudent({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    final user = UserModel(
      id: 'reg-user-123',
      email: email,
      firstName: firstName,
      lastName: lastName,
      fullName: '$firstName $lastName'.trim(),
      role: UserRole.student,
      isActive: true,
    );
    return AuthResponse(
      accessToken: 'reg-access-token',
      refreshToken: 'reg-refresh-token',
      user: user,
    );
  }
}

void main() {
  group('AuthController Offline & Auth Status Tests', () {
    late SecureStorageService storage;
    late MockAuthRepository repo;

    setUp(() {
      storage = SecureStorageService();
      repo = MockAuthRepository();
    });

    test('checkAuthStatus with no stored token sets isAuthenticated: false', () async {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.checkAuthStatus();

      final state = container.read(authControllerProvider);
      expect(state.isInitialized, isTrue);
      expect(state.isAuthenticated, isFalse);
      expect(state.isOffline, isFalse);
      expect(state.user, isNull);
    });

    test('checkAuthStatus with valid token and online server sets isAuthenticated: true and isOffline: false', () async {
      await storage.saveTokens(accessToken: 'valid-token', refreshToken: 'valid-refresh');

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.checkAuthStatus();

      final state = container.read(authControllerProvider);
      expect(state.isInitialized, isTrue);
      expect(state.isAuthenticated, isTrue);
      expect(state.isOffline, isFalse);
      expect(state.user, isNotNull);
      expect(state.user!.email, equals('student@cstu.edu.bd'));
      expect(await storage.getAccessToken(), equals('valid-token'));
    });

    test('checkAuthStatus with NetworkException preserves tokens and enters offline mode', () async {
      await storage.saveTokens(accessToken: 'saved-token', refreshToken: 'saved-refresh');
      await storage.saveUserMeta(userId: 'u-offline-1', role: 'supervisor');
      repo.errorToThrow = NetworkException(message: 'Connection timed out');

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.checkAuthStatus();

      final state = container.read(authControllerProvider);
      expect(state.isInitialized, isTrue);
      expect(state.isAuthenticated, isTrue, reason: 'Should remain authenticated in offline mode');
      expect(state.isOffline, isTrue, reason: 'Should flag offline status');
      expect(state.user, isNotNull);
      expect(state.user!.id, equals('u-offline-1'));
      expect(state.user!.role, equals(UserRole.supervisor));

      // Crucial: tokens must NOT be cleared from storage
      expect(await storage.getAccessToken(), equals('saved-token'));
      expect(await storage.getRefreshToken(), equals('saved-refresh'));
    });

    test('checkAuthStatus with 401 UnauthorizedException clears tokens and logs out', () async {
      await storage.saveTokens(accessToken: 'expired-token', refreshToken: 'expired-refresh');
      repo.errorToThrow = UnauthorizedException(message: 'Token expired');

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.checkAuthStatus();

      final state = container.read(authControllerProvider);
      expect(state.isInitialized, isTrue);
      expect(state.isAuthenticated, isFalse);
      expect(state.isOffline, isFalse);
      expect(state.user, isNull);

      // Verify tokens were cleared on 401
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('login with demo coordinator credentials on NetworkException enters offline mode without error', () async {
      repo.errorToThrow = NetworkException(message: 'Cannot connect to ATLAS server');

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final success = await controller.login(
        email: 'coordinator@cstu.edu.bd',
        password: 'Password123',
      );

      expect(success, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.isOffline, isTrue);
      expect(state.user, isNotNull);
      expect(state.user!.role, equals(UserRole.coordinator));
      expect(state.user!.fullName, equals('Academic Coordinator'));
      expect(state.errorMessage, isNull);
    });

    test('login with demo student credentials on NetworkException enters offline mode without error', () async {
      repo.errorToThrow = NetworkException(message: 'Cannot connect to ATLAS server');

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final success = await controller.login(
        email: 'student1@cstu.edu.bd',
        password: 'Password123',
      );

      expect(success, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.isOffline, isTrue);
      expect(state.user, isNotNull);
      expect(state.user!.role, equals(UserRole.student));
      expect(state.user!.fullName, equals('Tariqul Islam'));
      expect(state.errorMessage, isNull);
    });

    test('register when server is offline succeeds locally, then logs in seamlessly without error', () async {
      repo.errorToThrow = NetworkException(message: 'Cannot connect to ATLAS server');

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      // 1. Register a new user while offline
      final regSuccess = await controller.register(
        firstName: 'Tariqul',
        lastName: 'Islam',
        email: 'newstudent@cstu.edu.bd',
        password: 'MyPassword123',
        confirmPassword: 'MyPassword123',
      );

      expect(regSuccess, isTrue);
      var state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.isOffline, isTrue);
      expect(state.user!.email, equals('newstudent@cstu.edu.bd'));
      expect(state.user!.fullName, equals('Tariqul Islam'));

      // 2. Logout
      await controller.logout();
      state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);

      // 3. Login with newly registered offline credentials
      final loginSuccess = await controller.login(
        email: 'newstudent@cstu.edu.bd',
        password: 'MyPassword123',
      );

      expect(loginSuccess, isTrue);
      state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.isOffline, isTrue);
      expect(state.user!.email, equals('newstudent@cstu.edu.bd'));
      expect(state.user!.fullName, equals('Tariqul Islam'));
      expect(state.errorMessage, isNull);
    });

    test('login with unknown credentials when server is offline returns clear message', () async {
      repo.errorToThrow = NetworkException(message: 'Cannot connect to ATLAS server');

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final success = await controller.login(
        email: 'unknown@cstu.edu.bd',
        password: 'WrongPassword',
      );

      expect(success, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, contains('Demo Account or registered credentials'));
    });
  });
}
