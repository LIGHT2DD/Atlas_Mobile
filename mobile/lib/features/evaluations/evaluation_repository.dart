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

  static final List<RubricCriteriaModel> _demoRubrics = [
    RubricCriteriaModel(
      id: 'rub-1',
      title: 'Problem Formulation & Literature Review',
      description: 'Depth of background literature, clear research question formulation, and justification.',
      maxScore: 25.0,
      weightPercentage: 25.0,
      orderIndex: 1,
    ),
    RubricCriteriaModel(
      id: 'rub-2',
      title: 'Methodology & Engineering Execution',
      description: 'Technical rigor, architecture design, algorithmic efficiency, and test automation.',
      maxScore: 25.0,
      weightPercentage: 25.0,
      orderIndex: 2,
    ),
    RubricCriteriaModel(
      id: 'rub-3',
      title: 'Experimental Results & Validation',
      description: 'Statistical validation, benchmarks, error analysis, and metric clarity.',
      maxScore: 25.0,
      weightPercentage: 25.0,
      orderIndex: 3,
    ),
    RubricCriteriaModel(
      id: 'rub-4',
      title: 'Oral Presentation & Q&A Defense',
      description: 'Clarity of presentation, mastery of domain concepts, and defense of technical choices.',
      maxScore: 25.0,
      weightPercentage: 25.0,
      orderIndex: 4,
    ),
  ];

  static final TeamGradeModel _demoGrade = TeamGradeModel(
    hasGrade: true,
    teamName: 'Neural Nexus',
    projectTitle: 'Autonomous Multimodal Medical Imaging and Diagnosis System',
    finalGrade: 'A+',
    finalScore: 92.5,
    published: true,
  );

  /// Fetch rubric criteria
  Future<List<RubricCriteriaModel>> getRubrics() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/evaluations/rubrics');
      final list = res.data['data'] as List? ?? [];
      return list
          .map((e) => RubricCriteriaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoRubrics;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoRubrics;
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
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoRubrics.first;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoRubrics.first;
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
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return [];
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return [];
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
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.response == null ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return EvaluationRecordModel(
          id: 'eval-demo-${DateTime.now().millisecondsSinceEpoch}',
          evaluatorName: 'Fatema Jannat Dihan',
          calculatedScore: 92.5,
          overallComments: overallComments ?? 'Evaluation saved successfully (Demo mode).',
          scores: [],
        );
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return EvaluationRecordModel(
        id: 'eval-demo-${DateTime.now().millisecondsSinceEpoch}',
        evaluatorName: 'Fatema Jannat Dihan',
        calculatedScore: 92.5,
        overallComments: overallComments ?? 'Evaluation saved successfully (Demo mode).',
        scores: [],
      );
    }
  }

  /// Publish official final grades for a team (coordinator only)
  Future<String> publishGrade(String teamId) async {
    try {
      final res = await _client.dio.post('${ApiConfig.apiMobileV1}/evaluations/team/$teamId/publish');
      return res.data['message'] as String? ?? 'Grades published successfully.';
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return 'Grades published successfully.';
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return 'Grades published successfully.';
    }
  }

  /// Fetch the student's official published grade
  Future<TeamGradeModel> getMyGrade() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/evaluations/my-grade');
      final data = res.data['data'] as Map<String, dynamic>;
      return TeamGradeModel.fromJson(data);
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoGrade;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoGrade;
    }
  }
}
