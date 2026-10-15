class TeamMemberModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String? joinedAt;

  TeamMemberModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.joinedAt,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      joinedAt: json['joined_at'] as String?,
    );
  }
}

class SupervisorInfo {
  final String id;
  final String name;
  final String email;

  SupervisorInfo({
    required this.id,
    required this.name,
    required this.email,
  });

  factory SupervisorInfo.fromJson(Map<String, dynamic> json) {
    return SupervisorInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class TeamModel {
  final String id;
  final String name;
  final String projectTitle;
  final String? description;
  final String status;
  final String inviteCode;
  final String leaderId;
  final bool isLeader;
  final String? semesterId;
  final String? semesterName;
  final SupervisorInfo? supervisor;
  final List<TeamMemberModel> members;
  final String? finalGrade;
  final double? finalScore;
  final bool gradePublished;

  TeamModel({
    required this.id,
    required this.name,
    required this.projectTitle,
    this.description,
    required this.status,
    required this.inviteCode,
    required this.leaderId,
    required this.isLeader,
    this.semesterId,
    this.semesterName,
    this.supervisor,
    required this.members,
    this.finalGrade,
    this.finalScore,
    required this.gradePublished,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final membersList = (json['members'] as List?)
            ?.map((e) => TeamMemberModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    SupervisorInfo? sup;
    if (json['supervisor'] != null && json['supervisor'] is Map<String, dynamic>) {
      sup = SupervisorInfo.fromJson(json['supervisor'] as Map<String, dynamic>);
    }

    return TeamModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      projectTitle: json['project_title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'forming',
      inviteCode: json['invite_code'] as String? ?? '',
      leaderId: json['leader_id'] as String? ?? '',
      isLeader: json['is_leader'] as bool? ?? false,
      semesterId: json['semester_id'] as String?,
      semesterName: json['semester_name'] as String?,
      supervisor: sup,
      members: membersList,
      finalGrade: json['final_grade'] as String?,
      finalScore: (json['final_score'] as num?)?.toDouble(),
      gradePublished: json['grade_published'] as bool? ?? false,
    );
  }
}
