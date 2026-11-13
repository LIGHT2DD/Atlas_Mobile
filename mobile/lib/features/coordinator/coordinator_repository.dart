import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/errors/api_exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/provider_cache.dart';
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

class CoordinatorUserItem {
  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String role;
  final String? departmentId;
  final String? departmentName;
  final bool isActive;
  final String? createdAt;

  CoordinatorUserItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.role,
    this.departmentId,
    this.departmentName,
    required this.isActive,
    this.createdAt,
  });

  factory CoordinatorUserItem.fromJson(Map<String, dynamic> json) {
    return CoordinatorUserItem(
      id: json['id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'supervisor',
      departmentId: json['department_id'] as String?,
      departmentName: json['department_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );
  }
}

final coordinatorRepositoryProvider = Provider<CoordinatorRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CoordinatorRepository(client);
});

final coordinatorUsersProvider = FutureProvider.family<List<CoordinatorUserItem>, String?>((ref, role) async {
  ref.cacheFor(const Duration(minutes: 5));
  final repo = ref.watch(coordinatorRepositoryProvider);
  return repo.getUsers(role: role);
});

final reportsSummaryProvider = FutureProvider.autoDispose<ReportSummaryModel>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
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
      if (e.response?.statusCode == 404) {
        return [];
      }
      final handled = _client.handleDioError(e);
      if (handled is NetworkException) {
        return [
          TeamModel(
            id: 'cstu-t1',
            name: 'Neural Pioneers',
            projectTitle: 'Distributed Academic Thesis & Defense Assessment Platform',
            status: 'approved',
            inviteCode: 'ATLAS9',
            leaderId: 'cstu-student-001',
            isLeader: false,
            semesterName: 'Spring 2026',
            members: [
              TeamMemberModel(id: 'm1', userId: 'cstu-student-001', name: 'Tariqul Islam', email: 'student1@cstu.edu.bd', role: 'leader'),
              TeamMemberModel(id: 'm2', userId: 'cstu-student-002', name: 'Sadia Rahman', email: 'student2@cstu.edu.bd', role: 'member'),
            ],
            gradePublished: false,
          ),
          TeamModel(
            id: 'cstu-t2',
            name: 'Bioinformatics Vision',
            projectTitle: 'Deep Learning for Genomic Sequence Classification',
            status: 'approved',
            inviteCode: 'GENOM1',
            leaderId: 'cstu-student-004',
            isLeader: false,
            semesterName: 'Spring 2026',
            members: [
              TeamMemberModel(id: 'm4', userId: 'cstu-student-004', name: 'Farhan Ahmed', email: 'student4@cstu.edu.bd', role: 'leader'),
            ],
            gradePublished: false,
          ),
        ];
      }
      throw handled;
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
      if (e.response?.statusCode == 404) {
        return [];
      }
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
      if (e.response?.statusCode == 404) {
        return [];
      }
      final handled = _client.handleDioError(e);
      if (handled is NetworkException) {
        return [
          AuditLogItem(
            id: 'log-1',
            userName: 'Dr. Shahriar Hossain',
            action: 'Milestone Review Completed',
            resourceType: 'Milestone',
            details: 'Approved proposal document for Neural Pioneers',
            createdAt: 'Today, 2:30 PM',
          ),
          AuditLogItem(
            id: 'log-2',
            userName: 'Academic Coordinator',
            action: 'Defense Hearing Scheduled',
            resourceType: 'Defense',
            details: 'Room 402, Academic Bldg 2',
            createdAt: 'Yesterday, 10:15 AM',
          ),
        ];
      }
      throw handled;
    }
  }

  /// Fetch departmental report summary
  Future<ReportSummaryModel> getReportSummary() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/coordinator/reports/summary');
      final data = res.data['data'] as Map<String, dynamic>;
      return ReportSummaryModel.fromJson(data);
    } on DioException catch (e) {
      final handled = _client.handleDioError(e);
      if (handled is NetworkException) {
        return ReportSummaryModel(
          totalStudents: 48,
          totalSupervisors: 12,
          totalTeams: 16,
          activeProposals: 6,
          completedDefenses: 8,
          teamsByStatus: {
            'approved': 12,
            'pending': 4,
          },
        );
      }
      throw handled;
    }
  }

  /// Fetch faculty supervisors and coordinators
  Future<List<CoordinatorUserItem>> getUsers({String? role}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (role != null) queryParams['role'] = role;
      final res = await _client.dio.get(
        '${ApiConfig.apiMobileV1}/coordinator/users',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final raw = res.data['data'];
      final list = raw is List ? raw : [];
      return list.map((e) => CoordinatorUserItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final handled = _client.handleDioError(e);
      if (handled is NetworkException) {
        return [
          CoordinatorUserItem(
            id: 'cstu-coordinator-001',
            firstName: 'Academic',
            lastName: 'Coordinator',
            fullName: 'Academic Coordinator',
            email: 'coordinator@cstu.edu.bd',
            role: 'coordinator',
            departmentName: 'Computer Science & Telecom Engineering',
            isActive: true,
          ),
          CoordinatorUserItem(
            id: 'cstu-supervisor-001',
            firstName: 'Dr. Shahriar',
            lastName: 'Hossain',
            fullName: 'Dr. Shahriar Hossain',
            email: 'supervisor1@cstu.edu.bd',
            role: 'supervisor',
            departmentName: 'Computer Science & Telecom Engineering',
            isActive: true,
          ),
          CoordinatorUserItem(
            id: 'cstu-supervisor-002',
            firstName: 'Dr. Farhana',
            lastName: 'Yasmin',
            fullName: 'Dr. Farhana Yasmin',
            email: 'supervisor2@cstu.edu.bd',
            role: 'supervisor',
            departmentName: 'Computer Science & Telecom Engineering',
            isActive: true,
          ),
        ];
      }
      throw handled;
    }
  }

  /// Create a new supervisor or coordinator (Option A with security checks)
  Future<CoordinatorUserItem> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
    String? departmentId,
    String? currentPassword,
  }) async {
    try {
      final payload = {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
        if (departmentId != null && departmentId.isNotEmpty) 'department_id': departmentId,
        if (currentPassword != null && currentPassword.isNotEmpty) 'current_password': currentPassword,
      };

      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/coordinator/users',
        data: payload,
      );

      final data = res.data['data'] as Map<String, dynamic>;
      return CoordinatorUserItem.fromJson(data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
