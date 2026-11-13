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
  });
}
