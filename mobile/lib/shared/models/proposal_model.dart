class ProposalVersionModel {
  final String id;
  final int versionNumber;
  final String title;
  final String? abstractText;
  final String? documentPath;
  final String? changeSummary;
  final String submittedByName;
  final String? submittedAt;

  ProposalVersionModel({
    required this.id,
    required this.versionNumber,
    required this.title,
    this.abstractText,
    this.documentPath,
    this.changeSummary,
    required this.submittedByName,
    this.submittedAt,
  });

  factory ProposalVersionModel.fromJson(Map<String, dynamic> json) {
    return ProposalVersionModel(
      id: json['id'] as String? ?? '',
      versionNumber: json['version_number'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      abstractText: json['abstract'] as String?,
      documentPath: json['document_path'] as String?,
      changeSummary: json['change_summary'] as String?,
      submittedByName: json['submitted_by_name'] as String? ?? 'Unknown',
      submittedAt: json['submitted_at'] as String?,
    );
  }
}

class ProposalReviewModel {
  final String id;
  final String reviewerName;
  final String decision;
  final String comments;
  final String? createdAt;

  ProposalReviewModel({
    required this.id,
    required this.reviewerName,
    required this.decision,
    required this.comments,
    this.createdAt,
  });

  factory ProposalReviewModel.fromJson(Map<String, dynamic> json) {
    return ProposalReviewModel(
      id: json['id'] as String? ?? '',
      reviewerName: json['reviewer_name'] as String? ?? 'Faculty Reviewer',
      decision: json['decision'] as String? ?? 'pending',
      comments: json['comments'] as String? ?? '',
      createdAt: json['created_at'] as String?,
    );
  }
}

class ProposalModel {
  final String id;
  final String teamId;
  final String teamName;
  final String title;
  final String abstractText;
  final String status;
  final int currentVersion;
  final String? submittedAt;
  final String? reviewedAt;
  final List<ProposalVersionModel> versions;
  final List<ProposalReviewModel> reviews;

  ProposalModel({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.title,
    required this.abstractText,
    required this.status,
    required this.currentVersion,
    this.submittedAt,
    this.reviewedAt,
    required this.versions,
    required this.reviews,
  });

  factory ProposalModel.fromJson(Map<String, dynamic> json) {
    final vList = (json['versions'] as List?)
            ?.map((e) => ProposalVersionModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final rList = (json['reviews'] as List?)
            ?.map((e) => ProposalReviewModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ProposalModel(
      id: json['id'] as String? ?? '',
      teamId: json['team_id'] as String? ?? '',
      teamName: json['team_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      abstractText: json['abstract'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      currentVersion: json['current_version'] as int? ?? 1,
      submittedAt: json['submitted_at'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
      versions: vList,
      reviews: rList,
    );
  }
}
