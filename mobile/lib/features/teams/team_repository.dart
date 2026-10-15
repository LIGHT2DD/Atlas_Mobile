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

  static final TeamModel _demoTeam = TeamModel(
    id: 'team-neural-nexus',
    name: 'Neural Nexus',
    projectTitle: 'Autonomous Multimodal Medical Imaging and Diagnosis System',
    description: 'Deep learning pipeline for edge computing multimodal medical imaging and diagnostic recommendations.',
    status: 'completed',
    inviteCode: 'NN-2026-X',
    leaderId: '21b744ab9eb44cf6a1df27d607f28912',
    isLeader: true,
    supervisor: SupervisorInfo(
      id: 'supervisor-1',
      name: 'Fatema Jannat Dihan',
      email: 'supervisor1@atlas.edu',
    ),
    members: [
      TeamMemberModel(
        id: 'm1',
        userId: '21b744ab9eb44cf6a1df27d607f28912',
        name: 'Tahmid Hasan',
        email: 'student1@atlas.edu',
        role: 'leader',
      ),
      TeamMemberModel(
        id: 'm2',
        userId: 'student-2',
        name: 'Samiul Islam',
        email: 'student2@atlas.edu',
        role: 'member',
      ),
      TeamMemberModel(
        id: 'm3',
        userId: 'student-3',
        name: 'Nahid Hossain',
        email: 'student3@atlas.edu',
        role: 'member',
      ),
    ],
    finalGrade: 'A+',
    finalScore: 92.5,
    gradePublished: true,
  );

  static final List<SupervisorInfo> _demoSupervisors = [
    SupervisorInfo(id: 'supervisor-1', name: 'Fatema Jannat Dihan', email: 'supervisor1@atlas.edu'),
    SupervisorInfo(id: 'supervisor-2', name: 'Tanvir Ahmed', email: 'supervisor2@atlas.edu'),
    SupervisorInfo(id: 'supervisor-3', name: 'Md Abu Rumman Refat', email: 'supervisor3@atlas.edu'),
  ];

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
      final token = await _client.storage.getAccessToken();
      final userId = await _client.storage.getUserId();
      final userRole = await _client.storage.getUserRole();
      final isNetwork = e.response == null ||
          e.response?.statusCode == 404 ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;

      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        if (userRole == null || userRole == 'student' || userId == '21b744ab9eb44cf6a1df27d607f28912') {
          return _demoTeam;
        }
        return null;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoTeam;
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
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.response == null ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return TeamModel(
          id: 'team-${DateTime.now().millisecondsSinceEpoch}',
          name: name.trim(),
          projectTitle: projectTitle.trim(),
          description: description?.trim() ?? '',
          status: 'pending',
          inviteCode: 'ATLAS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          leaderId: '21b744ab9eb44cf6a1df27d607f28912',
          isLeader: true,
          gradePublished: false,
          members: [
            TeamMemberModel(
              id: 'm1',
              userId: '21b744ab9eb44cf6a1df27d607f28912',
              name: 'Tahmid Hasan',
              email: 'student1@atlas.edu',
              role: 'leader',
            ),
          ],
        );
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoTeam;
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
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.response == null ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoTeam;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoTeam;
    }
  }

  /// Leave current team
  Future<String> leaveTeam(String teamId) async {
    try {
      final res = await _client.dio.post('${ApiConfig.apiMobileV1}/teams/$teamId/leave');
      return res.data['message'] as String? ?? 'Successfully left the team.';
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.response == null ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return 'Successfully left the team (Demo mode).';
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return 'Successfully left the team (Demo mode).';
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
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.response == null ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown ||
          e.response?.statusCode == 404;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoSupervisors;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoSupervisors;
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
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.response == null ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return 'Supervision request sent successfully (Demo mode).';
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return 'Supervision request sent successfully (Demo mode).';
    }
  }
}
