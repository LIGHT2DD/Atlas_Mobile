import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/notification_model.dart';
import '../auth/auth_controller.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationsRepository(client);
});

class NotificationsRepository {
  final ApiClient _client;

  NotificationsRepository(this._client);

  static final List<NotificationModel> _studentDemoNotifications = [
    NotificationModel(
      id: 'notif-s1',
      title: 'Proposal Approved',
      content: 'Your capstone thesis proposal "Autonomous Multimodal Medical Imaging and Diagnosis System" has been formally approved by Fatema Jannat Dihan.',
      type: 'proposal',
      isRead: false,
      createdAt: '15 mins ago',
    ),
    NotificationModel(
      id: 'notif-s2',
      title: 'Milestone Evaluation Published',
      content: 'Midterm Progress Report scored 92.5/100 (Grade A+). Faculty comments: "Exceptional architecture and rigorous test methodology."',
      type: 'grade',
      isRead: false,
      createdAt: '2 hours ago',
    ),
    NotificationModel(
      id: 'notif-s3',
      title: 'Oral Defense Hearing Scheduled',
      content: 'Capstone Oral Defense scheduled for Dec 18, 2026 in Seminar Hall B (10:00 AM - 11:00 AM) before Panel #3.',
      type: 'defense',
      isRead: true,
      createdAt: 'Yesterday',
    ),
    NotificationModel(
      id: 'notif-s4',
      title: 'Upcoming Milestone Deadline',
      content: 'Final Source Code & Technical Documentation deliverable deadline is in 5 days. Ensure Git repo is updated.',
      type: 'milestone',
      isRead: true,
      createdAt: '3 days ago',
    ),
  ];

  static final List<NotificationModel> _supervisorDemoNotifications = [
    NotificationModel(
      id: 'notif-sup1',
      title: 'New Supervision Request',
      content: 'Team "Autonomous Drone Fleet" submitted a supervision invitation for "Real-time Quadcopter Navigation in GPS-denied Environments".',
      type: 'proposal',
      isRead: false,
      createdAt: '30 mins ago',
    ),
    NotificationModel(
      id: 'notif-sup2',
      title: 'Milestone Deliverable Submitted',
      content: 'Team Neural Nexus uploaded their Midterm Progress Report and GitHub repository link for grading.',
      type: 'milestone',
      isRead: false,
      createdAt: '3 hours ago',
    ),
    NotificationModel(
      id: 'notif-sup3',
      title: 'Defense Committee Assignment',
      content: 'You have been appointed as Lead Examiner for Panel #2 oral defense hearings scheduled for Dec 18.',
      type: 'defense',
      isRead: true,
      createdAt: '1 day ago',
    ),
  ];

  static final List<NotificationModel> _coordinatorDemoNotifications = [
    NotificationModel(
      id: 'notif-c1',
      title: 'Academic Term Initialized',
      content: 'Fall 2026 capstone cycle is officially active with 24 registered candidates and 8 teams formed.',
      type: 'system',
      isRead: false,
      createdAt: '1 hour ago',
    ),
    NotificationModel(
      id: 'notif-c2',
      title: 'Defense Schedule Published',
      content: 'Automated defense timetable generated with zero faculty room or panel conflicts.',
      type: 'defense',
      isRead: true,
      createdAt: 'Yesterday',
    ),
  ];

  static List<NotificationModel> _activeDemoNotifications = List.from(_studentDemoNotifications);

  Future<List<NotificationModel>> _resolveDemoNotifications() async {
    final role = await _client.storage.getUserRole();
    if (role == 'supervisor') {
      return _supervisorDemoNotifications;
    } else if (role == 'coordinator') {
      return _coordinatorDemoNotifications;
    }
    return _activeDemoNotifications;
  }

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
      final token = await _client.storage.getAccessToken();
      final isNetwork = e.response == null ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown ||
          e.response?.statusCode == 404;
      if ((token != null && token.startsWith('demo_token_')) || isNetwork) {
        return _resolveDemoNotifications();
      }
      throw _client.handleDioError(e);
    } catch (_) {
      return _resolveDemoNotifications();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _client.dio.post('${ApiConfig.apiMobileV1}/notifications/read-all');
    } catch (_) {
      _activeDemoNotifications = _activeDemoNotifications.map((n) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          content: n.content,
          type: n.type,
          isRead: true,
          link: n.link,
          createdAt: n.createdAt,
        );
      }).toList();
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.dio.post('${ApiConfig.apiMobileV1}/notifications/$notificationId/read');
    } catch (_) {
      _activeDemoNotifications = _activeDemoNotifications.map((n) {
        if (n.id == notificationId) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            content: n.content,
            type: n.type,
            isRead: true,
            link: n.link,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
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
