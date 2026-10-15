import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/proposal_model.dart';
import '../auth/auth_controller.dart';

final proposalRepositoryProvider = Provider<ProposalRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProposalRepository(client);
});

class ProposalRepository {
  final ApiClient _client;

  ProposalRepository(this._client);

  /// Get the proposal details, version history, and reviews for a team
  Future<ProposalModel?> getProposalByTeam(String teamId) async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/proposals/team/$teamId');
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return ProposalModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Proposal not drafted or submitted yet
      }
      throw _client.handleDioError(e);
    }
  }

  /// Submit or revise a proposal with optional document file bytes
  Future<ProposalModel> submitProposal({
    required String teamId,
    required String title,
    required String abstractText,
    String? changeSummary,
    Uint8List? documentBytes,
    String? documentFileName,
  }) async {
    try {
      final Map<String, dynamic> formMap = {
        'team_id': teamId,
        'title': title.trim(),
        'abstract_text': abstractText.trim(),
        if (changeSummary != null && changeSummary.isNotEmpty)
          'change_summary': changeSummary.trim(),
      };

      if (documentBytes != null && documentFileName != null) {
        formMap['file'] = MultipartFile.fromBytes(
          documentBytes,
          filename: documentFileName,
        );
      }

      final formData = FormData.fromMap(formMap);

      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/proposals/submit',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      final data = res.data['data'] as Map<String, dynamic>;
      return ProposalModel.fromJson(data);
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Submit supervisor review decision
  Future<String> reviewProposal({
    required String proposalId,
    required String decision, // "approved", "changes_requested", "rejected"
    required String comments,
  }) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/proposals/$proposalId/review',
        data: {
          'decision': decision,
          'comments': comments.trim(),
        },
      );
      return res.data['message'] as String? ?? 'Review recorded successfully.';
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
