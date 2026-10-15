import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/team_model.dart';
import '../auth/auth_controller.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return TeamRepository(client);
});

final myTeamFutureProvider = FutureProvider.autoDispose<TeamModel?>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getMyTeam();
});

final myTeamProvider = myTeamFutureProvider;

final supervisorsFutureProvider = FutureProvider.autoDispose<List<SupervisorInfo>>((ref) async {
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getAvailableSupervisors();
});

final supervisorsListProvider = supervisorsFutureProvider;

class TeamRepository {
  final ApiClient _client;

  TeamRepository(this._client);

  /// Fetch the current user's team if any
  Future<TeamModel?> getMyTeam() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/teams/my-team');
      final data = res.data['data'] as Map<String, dynamic>;
      final hasTeam = data['has_team'] as bool? ?? false;
      if (!hasTeam || data['team'] == null) {
        return null;
      }
      return TeamModel.fromJson(data['team'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Create a new thesis team
  Future<TeamModel> createTeam({
    required String name,
    required String projectTitle,
    String? description,
  }) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/teams',
        data: {
          'name': name.trim(),
          'project_title': projectTitle.trim(),
          if (description != null && description.isNotEmpty)
            'description': description.trim(),
        },
      );
      final data = res.data['data'] as Map<String, dynamic>;
      return TeamModel.fromJson(data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Join an existing team with an invite code
  Future<TeamModel> joinTeam(String inviteCode) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/teams/join',
        data: {'invite_code': inviteCode.trim().toUpperCase()},
      );
      final data = res.data['data'] as Map<String, dynamic>;
      return TeamModel.fromJson(data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Leave current team
  Future<String> leaveTeam(String teamId) async {
    try {
      final res = await _client.dio.post('${ApiConfig.apiMobileV1}/teams/$teamId/leave');
      return res.data['message'] as String? ?? 'Successfully left the team.';
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Fetch list of available faculty supervisors
  Future<List<SupervisorInfo>> getAvailableSupervisors() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/teams/supervisors');
      final list = res.data['data'] as List? ?? [];
      return list
          .map((e) => SupervisorInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Submit supervisor guidance request
  Future<String> requestSupervisor({
    required String teamId,
    required String supervisorId,
    required String message,
  }) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/teams/$teamId/request-supervisor',
        data: {
          'supervisor_id': supervisorId,
          'message': message.trim(),
        },
      );
      return res.data['message'] as String? ?? 'Supervision request sent successfully.';
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
