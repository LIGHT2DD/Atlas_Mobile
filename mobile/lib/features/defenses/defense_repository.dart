import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/defense_model.dart';
import '../auth/auth_controller.dart';

final defenseRepositoryProvider = Provider<DefenseRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return DefenseRepository(client);
});

class DefenseRepository {
  final ApiClient _client;

  DefenseRepository(this._client);

  /// Fetch all scheduled oral defense hearings
  Future<List<DefenseModel>> getDefenses() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/defenses');
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => DefenseModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _client.handleDioError(e);
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
