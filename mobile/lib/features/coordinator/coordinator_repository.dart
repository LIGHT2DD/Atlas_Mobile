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

  /// Fetch all thesis teams across the department
  Future<List<TeamModel>> getAllTeams() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/coordinator/teams');
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => TeamModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _client.handleDioError(e);
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
      throw _client.handleDioError(e);
    }
  }

  /// Fetch semesters
  Future<List<SemesterModel>> getSemesters() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/coordinator/semesters');
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => SemesterModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _client.handleDioError(e);
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
      throw _client.handleDioError(e);
    }
  }

  /// Activate a semester
  Future<String> activateSemester(String semesterId) async {
    try {
      final res = await _client.dio.post('${ApiConfig.apiMobileV1}/coordinator/semesters/$semesterId/activate');
      return res.data['message'] as String? ?? 'Semester activated.';
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Fetch audit logs
  Future<List<AuditLogItem>> getAuditLogs() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/coordinator/audit-logs');
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => AuditLogItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Fetch departmental report summary
  Future<ReportSummaryModel> getReportSummary() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/coordinator/reports/summary');
      final data = res.data['data'] as Map<String, dynamic>;
      return ReportSummaryModel.fromJson(data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
