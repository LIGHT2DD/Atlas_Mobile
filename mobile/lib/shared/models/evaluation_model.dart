class RubricCriteriaModel {
  final String id;
  final String title;
  final String? description;
  final double maxScore;
  final double weightPercentage;
  final int orderIndex;

  RubricCriteriaModel({
    required this.id,
    required this.title,
    this.description,
    required this.maxScore,
    required this.weightPercentage,
    required this.orderIndex,
  });

  factory RubricCriteriaModel.fromJson(Map<String, dynamic> json) {
    return RubricCriteriaModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 25.0,
      weightPercentage: (json['weight_percentage'] as num?)?.toDouble() ?? 25.0,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }
}

class EvaluationScoreModel {
  final String criteriaId;
  final String? criteriaTitle;
  final double score;
  final double? maxScore;

  EvaluationScoreModel({
    required this.criteriaId,
    this.criteriaTitle,
    required this.score,
    this.maxScore,
  });

  factory EvaluationScoreModel.fromJson(Map<String, dynamic> json) {
    return EvaluationScoreModel(
      criteriaId: json['criteria_id'] as String? ?? '',
      criteriaTitle: json['criteria_title'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      maxScore: (json['max_score'] as num?)?.toDouble(),
    );
  }
}

class EvaluationRecordModel {
  final String id;
  final String evaluatorName;
  final double calculatedScore;
  final String? overallComments;
  final List<EvaluationScoreModel> scores;

  EvaluationRecordModel({
    required this.id,
    required this.evaluatorName,
    required this.calculatedScore,
    this.overallComments,
    required this.scores,
  });

  factory EvaluationRecordModel.fromJson(Map<String, dynamic> json) {
    final sList = (json['scores'] as List?)
            ?.map((e) => EvaluationScoreModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return EvaluationRecordModel(
      id: json['id'] as String? ?? '',
      evaluatorName: json['evaluator_name'] as String? ?? 'Faculty Evaluator',
      calculatedScore: (json['calculated_score'] as num?)?.toDouble() ?? 0.0,
      overallComments: json['overall_comments'] as String?,
      scores: sList,
    );
  }
}

class TeamGradeModel {
  final bool hasGrade;
  final String? teamName;
  final String? projectTitle;
  final String? finalGrade;
  final double? finalScore;
  final bool published;
  final String? reason;

  TeamGradeModel({
    required this.hasGrade,
    this.teamName,
    this.projectTitle,
    this.finalGrade,
    this.finalScore,
    required this.published,
    this.reason,
  });

  factory TeamGradeModel.fromJson(Map<String, dynamic> json) {
    return TeamGradeModel(
      hasGrade: json['has_grade'] as bool? ?? false,
      teamName: json['team_name'] as String?,
      projectTitle: json['project_title'] as String?,
      finalGrade: json['final_grade'] as String?,
      finalScore: (json['final_score'] as num?)?.toDouble(),
      published: json['published'] as bool? ?? false,
      reason: json['reason'] as String?,
    );
  }
}
