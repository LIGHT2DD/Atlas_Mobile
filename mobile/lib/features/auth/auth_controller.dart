import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/api_exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../shared/models/user_model.dart';
import '../coordinator/coordinator_repository.dart';
import '../defenses/defense_repository.dart';
import '../evaluations/evaluation_repository.dart';
import '../milestones/milestone_repository.dart';
import '../supervisor/supervisor_repository.dart';
import '../teams/team_repository.dart';
import '../notifications/notifications_repository.dart';
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
  final bool isOffline;

  const AuthState({
    this.isLoading = false,
    this.isInitialized = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
    this.isOffline = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isInitialized,
    bool? isAuthenticated,
    UserModel? user,
    String? errorMessage,
    bool? isOffline,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isOffline: isOffline ?? this.isOffline,
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
    _ref.invalidate(notificationsListProvider);
  }

  // Pre-configured official demo test accounts
  static final Map<String, UserModel> _demoAccounts = {
    'coordinator@cstu.edu.bd': UserModel(
      id: 'cstu-coordinator-001',
      email: 'coordinator@cstu.edu.bd',
      firstName: 'Academic',
      lastName: 'Coordinator',
      fullName: 'Academic Coordinator',
      role: UserRole.coordinator,
      isActive: true,
    ),
    'admin@cstu.edu.bd': UserModel(
      id: 'cstu-coordinator-001',
      email: 'coordinator@cstu.edu.bd',
      firstName: 'Academic',
      lastName: 'Coordinator',
      fullName: 'Academic Coordinator',
      role: UserRole.coordinator,
      isActive: true,
    ),
    'supervisor1@cstu.edu.bd': UserModel(
      id: 'cstu-supervisor-001',
      email: 'supervisor1@cstu.edu.bd',
      firstName: 'Dr. Shahriar',
      lastName: 'Hossain',
      fullName: 'Dr. Shahriar Hossain',
      role: UserRole.supervisor,
      isActive: true,
    ),
    'supervisor@cstu.edu.bd': UserModel(
      id: 'cstu-supervisor-001',
      email: 'supervisor1@cstu.edu.bd',
      firstName: 'Dr. Shahriar',
      lastName: 'Hossain',
      fullName: 'Dr. Shahriar Hossain',
      role: UserRole.supervisor,
      isActive: true,
    ),
    'student1@cstu.edu.bd': UserModel(
      id: 'cstu-student-001',
      email: 'student1@cstu.edu.bd',
      firstName: 'Tariqul',
      lastName: 'Islam',
      fullName: 'Tariqul Islam',
      role: UserRole.student,
      isActive: true,
    ),
    'student@cstu.edu.bd': UserModel(
      id: 'cstu-student-001',
      email: 'student1@cstu.edu.bd',
      firstName: 'Tariqul',
      lastName: 'Islam',
      fullName: 'Tariqul Islam',
      role: UserRole.student,
      isActive: true,
    ),
  };

  Future<UserModel?> _resolveOfflineUser(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    // 1. Check built-in demo credentials (Password123)
    if (_demoAccounts.containsKey(cleanEmail) &&
        (cleanPass == 'Password123' || cleanPass.toLowerCase() == 'password123')) {
      return _demoAccounts[cleanEmail];
    }

    // 2. Check offline registered accounts
    final account = await _storage.findOfflineAccount(cleanEmail);
    if (account != null) {
      final storedPass = (account['password'] as String? ?? '').trim();
      if (storedPass.isEmpty || storedPass == cleanPass) {
        return UserModel(
          id: account['id'] as String? ?? 'student_local',
          email: account['email'] as String? ?? cleanEmail,
          firstName: account['first_name'] as String? ?? 'Tariqul',
          lastName: account['last_name'] as String? ?? 'Islam',
          fullName: account['full_name'] as String? ??
              '${account['first_name'] ?? 'Tariqul'} ${account['last_name'] ?? 'Islam'}'.trim(),
          role: UserRole.fromString(account['role'] as String? ?? 'student'),
          isActive: true,
        );
      }
    }

    return null;
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
          isOffline: false,
        );
        return;
      }

      try {
        final user = await _repo.getProfile();
        await _storage.saveUserMeta(
          userId: user.id,
          role: user.role.name,
        );
        await _storage.saveCachedUser(user);
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          isAuthenticated: true,
          isOffline: false,
          user: user,
        );
      } on NetworkException {
        // Network connection error while valid token exists: enter offline mode with cached user
        final cachedUser = await _storage.getCachedUser();
        final cachedUserId = await _storage.getUserId();
        final cachedRole = await _storage.getUserRole();
        final role = cachedRole != null ? UserRole.fromString(cachedRole) : UserRole.student;

        final userToUse = cachedUser ??
            UserModel(
              id: cachedUserId ?? 'offline-user',
              email: '',
              firstName: 'Active',
              lastName: 'User',
              fullName: 'Active User',
              role: role,
              isActive: true,
            );

        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          isAuthenticated: true,
          isOffline: true,
          user: userToUse,
        );
      }
    } catch (_) {
      await _storage.clearAuth();
      _invalidateUserData();
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        isAuthenticated: false,
        isOffline: false,
      );
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final cleanEmail = email.trim().toLowerCase();

    try {
      final authResponse = await _repo.login(
        email: cleanEmail,
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
      await _storage.saveCachedUser(authResponse.user);

      // Cache credentials for offline fallback
      await _storage.saveOfflineAccount({
        'id': authResponse.user.id,
        'email': cleanEmail,
        'password': password,
        'first_name': authResponse.user.firstName,
        'last_name': authResponse.user.lastName,
        'full_name': authResponse.user.fullName,
        'role': authResponse.user.role.name,
      });

      _invalidateUserData();

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        isOffline: false,
        user: authResponse.user,
        clearError: true,
      );
      return true;
    } on NetworkException catch (_) {
      // Server unreachable: check demo credentials or locally registered accounts
      final offlineUser = await _resolveOfflineUser(cleanEmail, password);
      if (offlineUser != null) {
        await _storage.clearAuth();
        await _storage.saveTokens(
          accessToken: 'offline_token_${offlineUser.id}',
          refreshToken: 'offline_refresh_${offlineUser.id}',
        );
        await _storage.saveUserMeta(
          userId: offlineUser.id,
          role: offlineUser.role.name,
        );
        await _storage.saveCachedUser(offlineUser);

        _invalidateUserData();

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          isOffline: true,
          user: offlineUser,
          clearError: true,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Cannot connect to ATLAS server. To test offline, please use a Demo Account or registered credentials.',
      );
      return false;
    } catch (e) {
      // If it's a connection-related exception that wasn't wrapped as NetworkException:
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('connect') || errStr.contains('socket') || errStr.contains('timeout')) {
        final offlineUser = await _resolveOfflineUser(cleanEmail, password);
        if (offlineUser != null) {
          await _storage.clearAuth();
          await _storage.saveTokens(
            accessToken: 'offline_token_${offlineUser.id}',
            refreshToken: 'offline_refresh_${offlineUser.id}',
          );
          await _storage.saveUserMeta(
            userId: offlineUser.id,
            role: offlineUser.role.name,
          );
          await _storage.saveCachedUser(offlineUser);

          _invalidateUserData();

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            isOffline: true,
            user: offlineUser,
            clearError: true,
          );
          return true;
        }
      }

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
    final cleanEmail = email.trim().toLowerCase();
    final cleanFirst = firstName.trim();
    final cleanLast = lastName.trim();

    try {
      final authResponse = await _repo.registerStudent(
        firstName: cleanFirst,
        lastName: cleanLast,
        email: cleanEmail,
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
      await _storage.saveCachedUser(authResponse.user);

      // Cache account in offline registry
      await _storage.saveOfflineAccount({
        'id': authResponse.user.id,
        'email': cleanEmail,
        'password': password,
        'first_name': cleanFirst,
        'last_name': cleanLast,
        'full_name': authResponse.user.fullName,
        'role': 'student',
      });

      _invalidateUserData();

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        isOffline: false,
        user: authResponse.user,
        clearError: true,
      );
      return true;
    } on NetworkException catch (_) {
      // Backend is unreachable: register locally in offline storage!
      final fullName = cleanFirst.isEmpty
          ? cleanLast
          : (cleanLast.isEmpty ? cleanFirst : '$cleanFirst $cleanLast');
      final newUserId = 'student_local_${DateTime.now().millisecondsSinceEpoch}';

      final offlineStudent = UserModel(
        id: newUserId,
        email: cleanEmail,
        firstName: cleanFirst,
        lastName: cleanLast,
        fullName: fullName,
        role: UserRole.student,
        isActive: true,
      );

      // Save to local offline accounts registry
      await _storage.saveOfflineAccount({
        'id': newUserId,
        'email': cleanEmail,
        'password': password,
        'first_name': cleanFirst,
        'last_name': cleanLast,
        'full_name': fullName,
        'role': 'student',
      });

      await _storage.clearAuth();
      await _storage.saveTokens(
        accessToken: 'offline_token_$newUserId',
        refreshToken: 'offline_refresh_$newUserId',
      );
      await _storage.saveUserMeta(
        userId: newUserId,
        role: UserRole.student.name,
      );
      await _storage.saveCachedUser(offlineStudent);

      _invalidateUserData();

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        isOffline: true,
        user: offlineStudent,
        clearError: true,
      );
      return true;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('connect') || errStr.contains('socket') || errStr.contains('timeout')) {
        final fullName = cleanFirst.isEmpty
            ? cleanLast
            : (cleanLast.isEmpty ? cleanFirst : '$cleanFirst $cleanLast');
        final newUserId = 'student_local_${DateTime.now().millisecondsSinceEpoch}';

        final offlineStudent = UserModel(
          id: newUserId,
          email: cleanEmail,
          firstName: cleanFirst,
          lastName: cleanLast,
          fullName: fullName,
          role: UserRole.student,
          isActive: true,
        );

        await _storage.saveOfflineAccount({
          'id': newUserId,
          'email': cleanEmail,
          'password': password,
          'first_name': cleanFirst,
          'last_name': cleanLast,
          'full_name': fullName,
          'role': 'student',
        });

        await _storage.clearAuth();
        await _storage.saveTokens(
          accessToken: 'offline_token_$newUserId',
          refreshToken: 'offline_refresh_$newUserId',
        );
        await _storage.saveUserMeta(
          userId: newUserId,
          role: UserRole.student.name,
        );
        await _storage.saveCachedUser(offlineStudent);

        _invalidateUserData();

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          isOffline: true,
          user: offlineStudent,
          clearError: true,
        );
        return true;
      }

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
