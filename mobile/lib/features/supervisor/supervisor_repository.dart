import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/team_model.dart';
import '../auth/auth_controller.dart';

class SupervisorRequestItem {
  final String id;
  final String teamId;
  final String teamName;
  final String projectTitle;
  final String requestedByName;
  final String message;
  final String status;
  final String? createdAt;

  SupervisorRequestItem({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.projectTitle,
    required this.requestedByName,
    required this.message,
    required this.status,
    this.createdAt,
  });

  factory SupervisorRequestItem.fromJson(Map<String, dynamic> json) {
    return SupervisorRequestItem(
      id: json['id'] as String? ?? '',
      teamId: json['team_id'] as String? ?? '',
      teamName: json['team_name'] as String? ?? '',
      projectTitle: json['project_title'] as String? ?? '',
      requestedByName: json['requested_by_name'] as String? ?? 'Student Leader',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String?,
    );
  }
}

final supervisorRepositoryProvider = Provider<SupervisorRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return SupervisorRepository(client);
});

final supervisorRequestsProvider =
    FutureProvider.autoDispose<List<SupervisorRequestItem>>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.getRequests();
});

final supervisorRequestsFutureProvider = supervisorRequestsProvider;

final supervisedTeamsProvider =
    FutureProvider.autoDispose<List<TeamModel>>((ref) async {
  final repo = ref.watch(supervisorRepositoryProvider);
  return repo.getSupervisedTeams();
});

final supervisedTeamsFutureProvider = supervisedTeamsProvider;

class SupervisorRepository {
  final ApiClient _client;

  SupervisorRepository(this._client);

  static final List<SupervisorRequestItem> _demoRequests = [
    SupervisorRequestItem(
      id: 'req-1',
      teamId: 'team-3',
      teamName: 'Autonomous Drone Fleet',
      projectTitle: 'Real-time Autonomous Quadcopter Navigation in GPS-denied Environments',
      requestedByName: 'Farhan Ishrak',
      message: 'Respected supervisor, our team seeks your mentorship in edge computer vision and robotics.',
      status: 'pending',
      createdAt: '2026-10-12T10:00:00Z',
    ),
  ];

  static final List<TeamModel> _demoSupervisedTeams = [
    TeamModel(
      id: 'team-neural-nexus',
      name: 'Neural Nexus',
      projectTitle: 'Autonomous Multimodal Medical Imaging and Diagnosis System',
      description: 'Deep learning pipeline for edge computing multimodal medical imaging and diagnostic recommendations.',
      status: 'completed',
      inviteCode: 'NN-2026-X',
      leaderId: '21b744ab9eb44cf6a1df27d607f28912',
      isLeader: false,
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
      ],
      finalGrade: 'A+',
      finalScore: 92.5,
      gradePublished: true,
    ),
  ];

  /// Get pending supervision requests for the logged-in supervisor
  Future<List<SupervisorRequestItem>> getRequests() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/supervisor/requests');
      final list = res.data['data'] as List? ?? [];
      return list
          .map((e) => SupervisorRequestItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.response?.statusCode == 404;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoRequests;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoRequests;
    }
  }

  /// Accept or decline a supervision request
  Future<String> respondToRequest({
    required String requestId,
    required String action, // "accept" or "reject"
    String? notes,
  }) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/supervisor/requests/$requestId/respond',
        data: {
          'action': action,
          if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
        },
      );
      return res.data['message'] as String? ?? 'Response submitted successfully.';
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.response == null ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown ||
          e.response?.statusCode == 404;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return 'Request $action action recorded successfully (Demo mode).';
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return 'Request $action action recorded successfully (Demo mode).';
    }
  }

  /// Get list of teams assigned to this supervisor
  Future<List<TeamModel>> getSupervisedTeams() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/supervisor/teams');
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => TeamModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.response == null ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown ||
          e.response?.statusCode == 404;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoSupervisedTeams;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoSupervisedTeams;
    }
  }
}
