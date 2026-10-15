import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/milestone_model.dart';
import '../auth/auth_controller.dart';

final milestoneRepositoryProvider = Provider<MilestoneRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return MilestoneRepository(client);
});

class MilestoneRepository {
  final ApiClient _client;

  MilestoneRepository(this._client);

  /// Fetch all active milestones for the current semester
  Future<List<MilestoneModel>> getMilestones() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/milestones');
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => MilestoneModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Create a milestone (coordinator only)
  Future<MilestoneModel> createMilestone({
    required String title,
    String? description,
    String? dueDate,
    double maxScore = 100.0,
    double weightPercentage = 0.0,
  }) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/milestones',
        data: {
          'title': title.trim(),
          if (description != null && description.isNotEmpty)
            'description': description.trim(),
          if (dueDate != null && dueDate.isNotEmpty) 'due_date': dueDate,
          'max_score': maxScore,
          'weight_percentage': weightPercentage,
        },
      );
      final data = res.data['data'] as Map<String, dynamic>;
      return MilestoneModel.fromJson(data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Get submissions made by a team
  Future<List<SubmissionModel>> getSubmissionsByTeam(String teamId) async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/submissions/team/$teamId');
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => SubmissionModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Submit a deliverable for a milestone
  Future<SubmissionModel> createSubmission({
    required String milestoneId,
    required String teamId,
    required String title,
    String? description,
    String? codeUrl,
    Uint8List? deliverableBytes,
    String? deliverableFileName,
  }) async {
    try {
      final Map<String, dynamic> formMap = {
        'milestone_id': milestoneId,
        'team_id': teamId,
        'title': title.trim(),
        if (description != null && description.isNotEmpty)
          'description': description.trim(),
        if (codeUrl != null && codeUrl.isNotEmpty) 'code_url': codeUrl.trim(),
      };

      if (deliverableBytes != null && deliverableFileName != null) {
        formMap['file'] = MultipartFile.fromBytes(
          deliverableBytes,
          filename: deliverableFileName,
        );
      }

      final formData = FormData.fromMap(formMap);

      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/submissions',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      final data = res.data['data'] as Map<String, dynamic>;
      return SubmissionModel.fromJson(data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Grade a submission (supervisor/coordinator)
  Future<String> gradeSubmission({
    required String submissionId,
    required double score,
    required String feedback,
  }) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/submissions/$submissionId/grade',
        data: {
          'score': score,
          'feedback': feedback.trim(),
        },
      );
      return res.data['message'] as String? ?? 'Submission graded successfully.';
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
