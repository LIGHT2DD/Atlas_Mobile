import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'notifications_repository.dart';

final notificationsListProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.getNotifications();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              final repo = ref.read(notificationsRepositoryProvider);
              await repo.markAllAsRead();
              ref.invalidate(notificationsListProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(notificationsListProvider),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: notifsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading notification stream...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(notificationsListProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'All Caught Up!',
                  subtitle:
                      'You have no pending notifications. Updates regarding proposals, submissions, and defenses will appear here.',
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(notificationsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return ListTile(
                  tileColor: n.isRead ? Colors.transparent : AppColors.infoBg.withAlpha(50),
                  leading: CircleAvatar(
                    backgroundColor: n.isRead ? AppColors.card : AppColors.accent,
                    child: Icon(
                      _getNotificationIcon(n.type),
                      color: n.isRead ? AppColors.textSecondary : Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          n.title ?? 'System Notice',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        n.content,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                      ),
                      if (n.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          n.createdAt!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                  onTap: () async {
                    if (!n.isRead) {
                      final repo = ref.read(notificationsRepositoryProvider);
                      await repo.markAsRead(n.id);
                      ref.invalidate(notificationsListProvider);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'proposal':
        return Icons.article_outlined;
      case 'milestone':
        return Icons.flag_outlined;
      case 'defense':
        return Icons.event_seat_outlined;
      case 'grade':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
