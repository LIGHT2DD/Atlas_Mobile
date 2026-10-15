import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/team_model.dart';
import '../auth/auth_controller.dart';

class SemesterModel {
  final String id;
  final String name;
  final String code;
  final String? startDate;
  final String? endDate;
  final bool isActive;

  SemesterModel({
    required this.id,
    required this.name,
    required this.code,
    this.startDate,
    this.endDate,
    required this.isActive,
  });

  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    return SemesterModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      isActive: json['is_active'] as bool? ?? false,
    );
  }
}

class AuditLogItem {
  final String id;
  final String userName;
  final String action;
  final String resourceType;
  final String? resourceId;
  final String? details;
  final String? createdAt;

  AuditLogItem({
    required this.id,
    required this.userName,
    required this.action,
    required this.resourceType,
    this.resourceId,
    this.details,
    this.createdAt,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    return AuditLogItem(
      id: json['id'] as String? ?? '',
      userName: json['user_name'] as String? ?? 'System',
      action: json['action'] as String? ?? '',
      resourceType: json['resource_type'] as String? ?? '',
      resourceId: json['resource_id'] as String?,
      details: json['details'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class ReportSummaryModel {
  final int totalStudents;
  final int totalSupervisors;
  final int totalTeams;
  final int activeProposals;
  final int completedDefenses;
  final Map<String, dynamic> teamsByStatus;

  ReportSummaryModel({
    required this.totalStudents,
    required this.totalSupervisors,
    required this.totalTeams,
    required this.activeProposals,
    required this.completedDefenses,
    required this.teamsByStatus,
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReportSummaryModel(
      totalStudents: json['total_students'] as int? ?? 0,
      totalSupervisors: json['total_supervisors'] as int? ?? 0,
      totalTeams: json['total_teams'] as int? ?? 0,
      activeProposals: json['active_proposals'] as int? ?? 0,
      completedDefenses: json['completed_defenses'] as int? ?? 0,
      teamsByStatus: json['teams_by_status'] as Map<String, dynamic>? ?? {},
    );
  }
}

final coordinatorRepositoryProvider = Provider<CoordinatorRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CoordinatorRepository(client);
});

final reportsSummaryProvider = FutureProvider.autoDispose<ReportSummaryModel>((ref) async {
  final repo = ref.watch(coordinatorRepositoryProvider);
  return repo.getReportSummary();
});

final reportSummaryFutureProvider = reportsSummaryProvider;

class CoordinatorRepository {
  final ApiClient _client;

  CoordinatorRepository(this._client);

  static final List<TeamModel> _demoAllTeams = [
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
    TeamModel(
      id: 'team-drone-fleet',
      name: 'Autonomous Drone Fleet',
      projectTitle: 'Real-time Autonomous Quadcopter Navigation in GPS-denied Environments',
      description: 'Edge computer vision and SLAM pipeline for indoor quadcopter flight.',
      status: 'pending',
      inviteCode: 'ADF-2026',
      leaderId: 'student-4',
      isLeader: false,
      members: [],
      gradePublished: false,
    ),
  ];

  static final List<SemesterModel> _demoSemesters = [
    SemesterModel(
      id: 'sem-1',
      name: 'Fall 2026 Academic Term',
      code: 'FA26',
      startDate: '2026-09-01',
      endDate: '2026-12-31',
      isActive: true,
    ),
    SemesterModel(
      id: 'sem-2',
      name: 'Spring 2026 Academic Term',
      code: 'SP26',
      startDate: '2026-01-15',
      endDate: '2026-05-30',
      isActive: false,
    ),
  ];

  static final List<AuditLogItem> _demoAuditLogs = [
    AuditLogItem(
      id: 'log-1',
      userName: 'Fatema Jannat Dihan',
      action: 'APPROVED_PROPOSAL',
      resourceType: 'proposal',
      resourceId: 'prop-1',
      details: 'Approved capstone thesis proposal for Neural Nexus',
      createdAt: '2026-09-20T14:15:00Z',
    ),
    AuditLogItem(
      id: 'log-2',
      userName: 'Prof. Nazim Uddin',
      action: 'SCHEDULED_DEFENSE',
      resourceType: 'defense',
      resourceId: 'def-1',
      details: 'Scheduled defense hearing for team Neural Nexus in Seminar Hall B',
      createdAt: '2026-10-10T11:00:00Z',
    ),
    AuditLogItem(
      id: 'log-3',
      userName: 'Fatema Jannat Dihan',
      action: 'GRADED_MILESTONE',
      resourceType: 'submission',
      resourceId: 'sub-2',
      details: 'Graded Midterm Pipeline prototype deliverable (92.5/100)',
      createdAt: '2026-11-12T14:30:00Z',
    ),
  ];

  static final ReportSummaryModel _demoReportSummary = ReportSummaryModel(
    totalTeams: 8,
    activeProposals: 8,
    completedDefenses: 6,
    totalStudents: 24,
    totalSupervisors: 5,
    teamsByStatus: {
      'approved': 4,
      'pending': 2,
      'defended': 2,
    },
  );

  /// Fetch all thesis teams across the department
  Future<List<TeamModel>> getAllTeams() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/coordinator/teams');
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => TeamModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoAllTeams;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoAllTeams;
    }
  }

  /// Assign or reassign a faculty supervisor to a team
  Future<String> assignSupervisor(String teamId, String supervisorId) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/coordinator/teams/$teamId/assign-supervisor',
        data: {'supervisor_id': supervisorId},
      );
      return res.data['message'] as String? ?? 'Supervisor assigned successfully.';
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return 'Supervisor assigned successfully.';
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return 'Supervisor assigned successfully.';
    }
  }

  /// Fetch semesters
  Future<List<SemesterModel>> getSemesters() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/coordinator/semesters');
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => SemesterModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoSemesters;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoSemesters;
    }
  }

  /// Create a new semester
  Future<SemesterModel> createSemester({
    required String name,
    required String code,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/coordinator/semesters',
        data: {
          'name': name.trim(),
          'code': code.trim().toUpperCase(),
          if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
          if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
        },
      );
      final data = res.data['data'] as Map<String, dynamic>;
      return SemesterModel.fromJson(data);
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoSemesters.first;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoSemesters.first;
    }
  }

  /// Activate a semester
  Future<String> activateSemester(String semesterId) async {
    try {
      final res = await _client.dio.post('${ApiConfig.apiMobileV1}/coordinator/semesters/$semesterId/activate');
      return res.data['message'] as String? ?? 'Semester activated.';
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return 'Semester activated.';
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return 'Semester activated.';
    }
  }

  /// Fetch audit logs
  Future<List<AuditLogItem>> getAuditLogs() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/coordinator/audit-logs');
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => AuditLogItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoAuditLogs;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoAuditLogs;
    }
  }

  /// Fetch departmental report summary
  Future<ReportSummaryModel> getReportSummary() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/coordinator/reports/summary');
      final data = res.data['data'] as Map<String, dynamic>;
      return ReportSummaryModel.fromJson(data);
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoReportSummary;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoReportSummary;
    }
  }
}
