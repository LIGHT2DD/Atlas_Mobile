class PanelMemberModel {
  final String id;
  final String userId;
  final String name;
  final String role;

  PanelMemberModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.role,
  });

  factory PanelMemberModel.fromJson(Map<String, dynamic> json) {
    return PanelMemberModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Faculty Examiner',
      role: json['role'] as String? ?? 'member',
    );
  }
}

class DefenseModel {
  final String id;
  final String teamId;
  final String teamName;
  final String projectTitle;
  final String? date;
  final String startTime;
  final String endTime;
  final String room;
  final String status;
  final String? notes;
  final List<PanelMemberModel> panelMembers;

  DefenseModel({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.projectTitle,
    this.date,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.status,
    this.notes,
    required this.panelMembers,
  });

  factory DefenseModel.fromJson(Map<String, dynamic> json) {
    final panel = (json['panel_members'] as List?)
            ?.map((e) => PanelMemberModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DefenseModel(
      id: json['id'] as String? ?? '',
      teamId: json['team_id'] as String? ?? '',
      teamName: json['team_name'] as String? ?? 'Unknown',
      projectTitle: json['project_title'] as String? ?? '',
      date: json['date'] as String?,
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      room: json['room'] as String? ?? '',
      status: json['status'] as String? ?? 'scheduled',
      notes: json['notes'] as String?,
      panelMembers: panel,
    );
  }
}
