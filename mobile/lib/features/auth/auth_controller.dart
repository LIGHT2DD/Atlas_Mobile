import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/models/user_model.dart';
import '../coordinator/coordinator_repository.dart';
import '../defenses/defense_repository.dart';
import '../evaluations/evaluation_repository.dart';
import '../milestones/milestone_repository.dart';
import '../supervisor/supervisor_repository.dart';
import '../teams/team_repository.dart';
import 'auth_repository.dart';

export '../../core/storage/secure_storage.dart' show secureStorageProvider;

// Providers

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
  final Ref _ref;

  AuthController(this._repo, this._storage, this._ref) : super(const AuthState()) {
    checkAuthStatus();
  }

  void _invalidateUserData() {
    _ref.invalidate(myTeamFutureProvider);
    _ref.invalidate(supervisorsFutureProvider);
    _ref.invalidate(supervisorRequestsProvider);
    _ref.invalidate(supervisedTeamsProvider);
    _ref.invalidate(reportsSummaryProvider);
    _ref.invalidate(milestonesListProvider);
    _ref.invalidate(defensesListProvider);
    _ref.invalidate(myGradeFutureProvider);
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
      _invalidateUserData();
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

      // Clear any previous session leftovers before committing new tokens
      await _storage.clearAuth();

      await _storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      await _storage.saveUserMeta(
        userId: authResponse.user.id,
        role: authResponse.user.role.name,
      );

      _invalidateUserData();

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

      // Clear any previous session leftovers before committing new tokens
      await _storage.clearAuth();

      await _storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      await _storage.saveUserMeta(
        userId: authResponse.user.id,
        role: authResponse.user.role.name,
      );

      _invalidateUserData();

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
    _invalidateUserData();
    state = const AuthState(isInitialized: true, isAuthenticated: false);
  }

  void onSessionExpired() {
    final wasAuthenticated = state.isAuthenticated;
    _storage.clearAuth();
    _invalidateUserData();
    state = AuthState(
      isInitialized: true,
      isAuthenticated: false,
      errorMessage: wasAuthenticated ? 'Your session has expired. Please sign in again.' : null,
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
  return AuthController(repo, storage, ref);
});
