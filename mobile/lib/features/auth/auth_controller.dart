import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/models/user_model.dart';
import 'auth_repository.dart';

// Providers
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final client = ApiClient(storage: storage);
  client.onSessionExpired = () {
    ref.read(authControllerProvider.notifier).onSessionExpired();
  };
  return client;
});

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthRepository(client);
});

class AuthState {
  final bool isLoading;
  final bool isInitialized;
  final bool isAuthenticated;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isInitialized = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isInitialized,
    bool? isAuthenticated,
    UserModel? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final SecureStorageService _storage;

  AuthController(this._repo, this._storage) : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          isAuthenticated: false,
        );
        return;
      }

      final user = await _repo.getProfile();
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        isAuthenticated: true,
        user: user,
      );
    } catch (_) {
      await _storage.clearAuth();
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        isAuthenticated: false,
      );
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authResponse = await _repo.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      await _storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      await _storage.saveUserMeta(
        userId: authResponse.user.id,
        role: authResponse.user.role.name,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: authResponse.user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authResponse = await _repo.registerStudent(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      await _storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      await _storage.saveUserMeta(
        userId: authResponse.user.id,
        role: authResponse.user.role.name,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: authResponse.user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {}
    await _storage.clearAuth();
    state = const AuthState(isInitialized: true, isAuthenticated: false);
  }

  void onSessionExpired() {
    state = const AuthState(
      isInitialized: true,
      isAuthenticated: false,
      errorMessage: 'Your session has expired. Please sign in again.',
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final StateNotifierProvider<AuthController, AuthState> authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthController(repo, storage);
});
