import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../widgets/neumorphic/neumorphic.dart';
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
    final neuTheme = context.neuTheme;
    final notifsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: NeuAppBar(
        title: 'Notifications',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: NeuIconButton(
              icon: TablerIcons.checks,
              tooltip: 'Mark all as read',
              onPressed: () async {
                final repo = ref.read(notificationsRepositoryProvider);
                await repo.markAllAsRead();
                ref.invalidate(notificationsListProvider);
                if (context.mounted) {
                  NeuToast.show(
                    context,
                    message: 'All notifications marked as read.',
                    type: NeuToastType.info,
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeuIconButton(
              icon: TablerIcons.rotate_clockwise,
              tooltip: 'Refresh Notifications',
              onPressed: () => ref.refresh(notificationsListProvider),
            ),
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
                  icon: TablerIcons.bell,
                  title: 'All Caught Up!',
                  subtitle:
                      'You have no pending notifications. Updates regarding proposals, submissions, and defenses will appear here.',
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: neuTheme.accentColor,
            backgroundColor: neuTheme.baseColor,
            onRefresh: () async => ref.refresh(notificationsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final n = notifications[index];
                final isUnread = !n.isRead;

                return NeuContainer(
                  depthType: isUnread ? NeuDepth.concave : NeuDepth.convex,
                  depth: isUnread ? 2.5 : 3.0,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(16),
                  onTap: () async {
                    if (isUnread) {
                      final repo = ref.read(notificationsRepositoryProvider);
                      await repo.markAsRead(n.id);
                      ref.invalidate(notificationsListProvider);
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NeuContainer(
                        shape: BoxShape.circle,
                        width: 42,
                        height: 42,
                        depthType: NeuDepth.convex,
                        depth: 2.5,
                        alignment: Alignment.center,
                        child: Icon(
                          _getNotificationIcon(n.type),
                          color: isUnread ? neuTheme.accentColor : neuTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title ?? 'System Notice',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                      color: neuTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: neuTheme.accentColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: neuTheme.accentColor.withValues(alpha: 0.6),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.content,
                              style: TextStyle(
                                fontSize: 13,
                                color: neuTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            if (n.createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                n.createdAt!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: neuTheme.textSecondary.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
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
        return TablerIcons.article;
      case 'milestone':
        return TablerIcons.flag;
      case 'defense':
        return TablerIcons.armchair;
      case 'grade':
        return TablerIcons.award;
      default:
        return TablerIcons.bell;
    }
  }
}
