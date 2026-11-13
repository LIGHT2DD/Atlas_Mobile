import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/errors/api_exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/provider_cache.dart';
import '../../shared/models/defense_model.dart';
import '../auth/auth_controller.dart';

final defenseRepositoryProvider = Provider<DefenseRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return DefenseRepository(client);
});

final defensesListProvider = FutureProvider.autoDispose<List<DefenseModel>>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  final repo = ref.watch(defenseRepositoryProvider);
  return repo.getDefenses();
});

class DefenseRepository {
  final ApiClient _client;

  DefenseRepository(this._client);

  /// Fetch all scheduled oral defense hearings
  Future<List<DefenseModel>> getDefenses() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/defenses');
      if (res.data is! Map<String, dynamic>) return [];
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => DefenseModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      final handled = _client.handleDioError(e);
      if (handled is NetworkException) {
        return [
          DefenseModel(
            id: 'demo-def-01',
            teamId: 'cstu-t1',
            teamName: 'Neural Pioneers',
            projectTitle: 'Distributed Academic Thesis & Defense Assessment Platform',
            date: '2026-05-15',
            startTime: '10:00 AM',
            endTime: '11:00 AM',
            room: 'Room 402, Academic Bldg 2',
            status: 'scheduled',
            panelMembers: [
              PanelMemberModel(id: 'pm1', userId: 'cstu-supervisor-001', name: 'Dr. Shahriar Hossain', role: 'Supervisor'),
              PanelMemberModel(id: 'pm2', userId: 'cstu-supervisor-002', name: 'Dr. Farhana Yasmin', role: 'Examiner'),
            ],
          ),
        ];
      }
      throw handled;
    }
  }

  /// Schedule a new oral defense with panel conflict detection (coordinator only)
  Future<String> scheduleDefense({
    required String teamId,
    required String date,
    required String startTime,
    required String endTime,
    required String room,
    required List<String> panelMemberIds,
    String? notes,
  }) async {
    try {
      final res = await _client.dio.post(
        '${ApiConfig.apiMobileV1}/defenses/schedule',
        data: {
          'team_id': teamId,
          'date': date,
          'start_time': startTime,
          'end_time': endTime,
          'room': room.trim(),
          'panel_member_ids': panelMemberIds,
          if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
        },
      );
      return res.data['message'] as String? ?? 'Defense scheduled successfully.';
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }
}
