import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/evaluation_model.dart';
import '../auth/auth_controller.dart';

final evaluationRepositoryProvider = Provider<EvaluationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return EvaluationRepository(client);
});

class EvaluationRepository {
  final ApiClient _client;

  EvaluationRepository(this._client);

  /// Fetch rubric criteria
  Future<List<RubricCriteriaModel>> getRubrics() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/evaluations/rubrics');
      final list = res.data['data'] as List? ?? [];
      return list
          .map((e) => RubricCriteriaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Create a rubric criterion (coordinator only)
  Future<RubricCriteriaModel> createRubricCriteria({
    required String title,
    String? description,
    double maxScore = 25.0,
    double weightPercentage = 25.0,
    int orderIndex = 0,
  }) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/evaluations/rubrics',
        data: {
          'title': title.trim(),
          if (description != null && description.isNotEmpty)
            'description': description.trim(),
          'max_score': maxScore,
          'weight_percentage': weightPercentage,
          'order_index': orderIndex,
        },
      );
      final data = res.data['data'] as Map<String, dynamic>;
      return RubricCriteriaModel.fromJson(data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Get evaluation records for a specific team
  Future<List<EvaluationRecordModel>> getTeamEvaluations(String teamId) async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/evaluations/team/$teamId');
      final list = res.data['data'] as List? ?? [];
      return list
          .map((e) => EvaluationRecordModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Submit formal evaluation scores for a team
  Future<EvaluationRecordModel> submitEvaluation({
    required String teamId,
    String? overallComments,
    required List<Map<String, dynamic>> scores,
  }) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/evaluations/team/$teamId',
        data: {
          if (overallComments != null && overallComments.isNotEmpty)
            'overall_comments': overallComments.trim(),
          'scores': scores,
        },
      );
      final data = res.data['data'] as Map<String, dynamic>;
      return EvaluationRecordModel.fromJson(data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Publish official final grades for a team (coordinator only)
  Future<String> publishGrade(String teamId) async {
    try {
      final res = await _client.dio.post('${ApiConfig.apiMobileV1}/evaluations/team/$teamId/publish');
      return res.data['message'] as String? ?? 'Grades published successfully.';
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Fetch the student's official published grade
  Future<TeamGradeModel> getMyGrade() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/evaluations/my-grade');
      final data = res.data['data'] as Map<String, dynamic>;
      return TeamGradeModel.fromJson(data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
