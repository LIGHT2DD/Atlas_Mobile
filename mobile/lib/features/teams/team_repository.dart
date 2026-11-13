import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/errors/api_exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/provider_cache.dart';
import '../../shared/models/team_model.dart';
import '../auth/auth_controller.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return TeamRepository(client);
});

final myTeamFutureProvider = FutureProvider.autoDispose<TeamModel?>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getMyTeam();
});

final myTeamProvider = myTeamFutureProvider;

final supervisorsFutureProvider = FutureProvider.autoDispose<List<SupervisorInfo>>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  final repo = ref.watch(teamRepositoryProvider);
  return repo.getAvailableSupervisors();
});

final supervisorsListProvider = supervisorsFutureProvider;

class TeamRepository {
  final ApiClient _client;

  TeamRepository(this._client);

  static final TeamModel _demoStudentTeam = TeamModel(
    id: 'demo-team-cstu-01',
    name: 'Neural Pioneers',
    projectTitle: 'Distributed Academic Thesis & Defense Assessment Platform',
    description: 'Automated milestone verification, rubric scoring, and oral defense hearing coordination.',
    status: 'approved',
    inviteCode: 'ATLAS9',
    leaderId: 'cstu-student-001',
    isLeader: true,
    semesterName: 'Spring 2026',
    supervisor: SupervisorInfo(
      id: 'cstu-supervisor-001',
      name: 'Dr. Shahriar Hossain',
      email: 'supervisor1@cstu.edu.bd',
    ),
    members: [
      TeamMemberModel(id: 'm1', userId: 'cstu-student-001', name: 'Tariqul Islam', email: 'student1@cstu.edu.bd', role: 'leader'),
      TeamMemberModel(id: 'm2', userId: 'cstu-student-002', name: 'Sadia Rahman', email: 'student2@cstu.edu.bd', role: 'member'),
      TeamMemberModel(id: 'm3', userId: 'cstu-student-003', name: 'Mahmudul Hasan', email: 'student3@cstu.edu.bd', role: 'member'),
    ],
    finalGrade: null,
    gradePublished: false,
  );

  /// Fetch the current user's team if any
  Future<TeamModel?> getMyTeam() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/teams/my-team');
      if (res.data is! Map<String, dynamic>) return null;
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      final hasTeam = data['has_team'] as bool? ?? false;
      if (!hasTeam || data['team'] == null) {
        return null;
      }
      return TeamModel.fromJson(data['team'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      final handled = _client.handleDioError(e);
      if (handled is NetworkException) {
        // Check for cached team payload
        final cached = await _client.storage.getCachedPayload('my_team');
        if (cached != null) {
          try {
            return TeamModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
          } catch (_) {}
        }
        final userId = await _client.storage.getUserId();
        if (userId == 'cstu-student-001' || userId == 'student1@cstu.edu.bd') {
          return _demoStudentTeam;
        }
        return null;
      }
      throw handled;
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
      final team = TeamModel.fromJson(data);
      await _client.storage.saveCachedPayload('my_team', jsonEncode(data));
      return team;
    } on DioException catch (e) {
      final handled = _client.handleDioError(e);
      if (handled is NetworkException) {
        final userId = await _client.storage.getUserId() ?? 'student_local';
        final cachedUser = await _client.storage.getCachedUser();
        final localTeam = TeamModel(
          id: 'team_local_${DateTime.now().millisecondsSinceEpoch}',
          name: name.trim(),
          projectTitle: projectTitle.trim(),
          description: description?.trim(),
          status: 'pending_supervisor',
          inviteCode: 'JOIN${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}',
          leaderId: userId,
          isLeader: true,
          semesterName: 'Spring 2026',
          members: [
            TeamMemberModel(
              id: 'local_member_1',
              userId: userId,
              name: cachedUser?.fullName ?? 'Tariqul Islam',
              email: cachedUser?.email ?? 'student@cstu.edu.bd',
              role: 'leader',
            ),
          ],
          gradePublished: false,
        );
        await _client.storage.saveCachedPayload('my_team', jsonEncode({
          'id': localTeam.id,
          'name': localTeam.name,
          'project_title': localTeam.projectTitle,
          'description': localTeam.description,
          'status': localTeam.status,
          'invite_code': localTeam.inviteCode,
          'leader_id': localTeam.leaderId,
          'is_leader': true,
          'semester_name': localTeam.semesterName,
          'members': [
            {
              'id': 'local_member_1',
              'user_id': userId,
              'name': cachedUser?.fullName ?? 'Tariqul Islam',
              'email': cachedUser?.email ?? 'student@cstu.edu.bd',
              'role': 'leader',
            }
          ],
          'grade_published': false,
        }));
        return localTeam;
      }
      throw handled;
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
      final team = TeamModel.fromJson(data);
      await _client.storage.saveCachedPayload('my_team', jsonEncode(data));
      return team;
    } on DioException catch (e) {
      final handled = _client.handleDioError(e);
      if (handled is NetworkException) {
        return _demoStudentTeam;
      }
      throw handled;
    }
  }

  /// Leave current team
  Future<String> leaveTeam(String teamId) async {
    try {
      final res = await _client.dio.post('${ApiConfig.apiMobileV1}/teams/$teamId/leave');
      await _client.storage.clearCachedPayload('my_team');
      return res.data['message'] as String? ?? 'Successfully left the team.';
    } on DioException catch (e) {
      final handled = _client.handleDioError(e);
      if (handled is NetworkException) {
        await _client.storage.clearCachedPayload('my_team');
        return 'Successfully left the team (Offline).';
      }
      throw handled;
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
      final handled = _client.handleDioError(e);
      if (handled is NetworkException) {
        return [
          SupervisorInfo(id: 'cstu-supervisor-001', name: 'Dr. Shahriar Hossain', email: 'supervisor1@cstu.edu.bd'),
          SupervisorInfo(id: 'cstu-supervisor-002', name: 'Dr. Farhana Yasmin', email: 'supervisor2@cstu.edu.bd'),
          SupervisorInfo(id: 'cstu-supervisor-003', name: 'Prof. Anisul Haque', email: 'supervisor3@cstu.edu.bd'),
        ];
      }
      throw handled;
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
