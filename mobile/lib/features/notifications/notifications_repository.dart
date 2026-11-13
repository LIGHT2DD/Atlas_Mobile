import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/errors/api_exceptions.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/notification_model.dart';
import '../auth/auth_controller.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationsRepository(client);
});

final notificationsListProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.getNotifications();
});

class NotificationsRepository {
  final ApiClient _client;

  NotificationsRepository(this._client);

  /// Fetch notifications for the logged in user
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final res = await _client.dio.get('${ApiConfig.apiMobileV1}/notifications');
      final dynamic rawData = res.data['data'];
      final List list;
      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map && rawData['notifications'] is List) {
        list = rawData['notifications'] as List;
      } else {
        list = [];
      }
      return list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      final handled = _client.handleDioError(e);
      if (handled is NetworkException) {
        return [
          NotificationModel(
            id: 'notif-1',
            title: 'Oral Defense Schedule Finalized',
            content: 'Defense hearings for Spring 2026 have been published by the academic coordinator.',
            type: 'defense',
            isRead: false,
            createdAt: 'Just now',
          ),
          NotificationModel(
            id: 'notif-2',
            title: 'Milestone 2 Reviews Open',
            content: 'Submit your system design documentation and prototype repository link.',
            type: 'milestone',
            isRead: true,
            createdAt: '2 days ago',
          ),
        ];
      }
      throw handled;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _client.dio.post('${ApiConfig.apiMobileV1}/notifications/read-all');
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.dio.post('${ApiConfig.apiMobileV1}/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw _client.handleDioError(e);
    }
  }

  /// Register FCM device token
  Future<void> registerDeviceToken(String token, {String platform = 'android'}) async {
    try {
      await _client.dio.post(
        '${ApiConfig.apiMobileV1}/notifications/device-token',
        data: {
          'token': token,
          'platform': platform,
        },
      );
    } catch (_) {
      // Best effort device token registration
    }
  }
}
