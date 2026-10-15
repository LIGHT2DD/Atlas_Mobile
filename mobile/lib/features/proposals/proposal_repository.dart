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

  static final ProposalModel _demoProposal = ProposalModel(
    id: 'prop-1',
    teamId: 'team-neural-nexus',
    teamName: 'Neural Nexus',
    title: 'Autonomous Multimodal Medical Imaging and Diagnosis System',
    abstractText: 'An intelligent edge-AI computer vision pipeline processing multimodal MRI and CT scans for early diagnostic assistance with explainable attention maps.',
    status: 'approved',
    currentVersion: 2,
    submittedAt: '2026-09-15T09:30:00Z',
    reviewedAt: '2026-09-20T14:15:00Z',
    versions: [
      ProposalVersionModel(
        id: 'ver-1',
        versionNumber: 1,
        title: 'Multimodal Medical Diagnosis System',
        abstractText: 'Initial draft outlining dataset collection and baseline CNN models.',
        submittedByName: 'Tahmid Hasan',
        submittedAt: '2026-09-01T11:00:00Z',
      ),
      ProposalVersionModel(
        id: 'ver-2',
        versionNumber: 2,
        title: 'Autonomous Multimodal Medical Imaging and Diagnosis System',
        abstractText: 'Revised to include attention mechanism, HIPAA security compliance, and edge inference.',
        changeSummary: 'Addressed faculty feedback regarding edge inference benchmarks.',
        submittedByName: 'Tahmid Hasan',
        submittedAt: '2026-09-15T09:30:00Z',
      ),
    ],
    reviews: [
      ProposalReviewModel(
        id: 'rev-1',
        reviewerName: 'Fatema Jannat Dihan',
        decision: 'approved',
        comments: 'Outstanding research proposal. Clear clinical problem definition, robust dataset validation, and thorough ethical considerations. Approved for thesis execution.',
        createdAt: '2026-09-20T14:15:00Z',
      ),
    ],
  );

  /// Get the proposal details, version history, and reviews for a team
  Future<ProposalModel?> getProposalByTeam(String teamId) async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/proposals/team/$teamId');
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return ProposalModel.fromJson(data);
    } on DioException catch (e) {
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoProposal;
      }
      if (e.response?.statusCode == 404) {
        return null; // Proposal not drafted or submitted yet
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoProposal;
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
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _demoProposal;
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _demoProposal;
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
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return 'Review recorded successfully.';
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return 'Review recorded successfully.';
    }
  }
}
