class MilestoneModel {
  final String id;
  final String title;
  final String? description;
  final String? dueDate;
  final double maxScore;
  final double weightPercentage;
  final String status;
  final bool isOverdue;

  MilestoneModel({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    required this.maxScore,
    required this.weightPercentage,
    required this.status,
    required this.isOverdue,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    return MilestoneModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: json['due_date'] as String?,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 100.0,
      weightPercentage: (json['weight_percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      isOverdue: json['is_overdue'] as bool? ?? false,
    );
  }
}

class SubmissionModel {
  final String id;
  final String title;
  final String? description;
  final String milestoneId;
  final String? milestoneTitle;
  final String teamId;
  final String? teamName;
  final String submittedByName;
  final String? codeUrl;
  final String? filePath;
  final int version;
  final bool isLate;
  final String status;
  final double? score;
  final String? feedback;
  final String? submittedAt;

  SubmissionModel({
    required this.id,
    required this.title,
    this.description,
    required this.milestoneId,
    this.milestoneTitle,
    required this.teamId,
    this.teamName,
    required this.submittedByName,
    this.codeUrl,
    this.filePath,
    required this.version,
    required this.isLate,
    required this.status,
    this.score,
    this.feedback,
    this.submittedAt,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      milestoneId: json['milestone_id'] as String? ?? '',
      milestoneTitle: json['milestone_title'] as String?,
      teamId: json['team_id'] as String? ?? '',
      teamName: json['team_name'] as String?,
      submittedByName: json['submitted_by_name'] as String? ?? 'Unknown',
      codeUrl: json['code_url'] as String?,
      filePath: json['file_path'] as String?,
      version: json['version'] as int? ?? 1,
      isLate: json['is_late'] as bool? ?? false,
      status: json['status'] as String? ?? 'submitted',
      score: (json['score'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      submittedAt: json['submitted_at'] as String?,
    );
  }
}
