import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/status_badge.dart';
import 'supervisor_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class SupervisedTeamsScreen extends ConsumerWidget {
  const SupervisedTeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(supervisedTeamsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervised Teams'),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.rotate_clockwise),
            onPressed: () => ref.refresh(supervisedTeamsFutureProvider),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: teamsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading supervised teams...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(supervisedTeamsFutureProvider),
        ),
        data: (teams) {
          if (teams.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: TablerIcons.users,
                  title: 'No Supervised Teams Yet',
                  subtitle:
                      'Teams that have been assigned to you or whose supervision requests you have accepted will appear here.',
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(supervisedTeamsFutureProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: AtlasCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                team.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            StatusBadge(status: team.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          team.projectTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        if (team.description != null && team.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            team.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(TablerIcons.users, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${team.members.length} members',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 16),
                            if (team.semesterName != null) ...[
                              const Icon(TablerIcons.calendar_event, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                team.semesterName!,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(TablerIcons.article, size: 18),
                              label: const Text('Proposal'),
                              onPressed: () {
                                context.push('/proposals', extra: team.id);
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(TablerIcons.clipboard_check, size: 18),
                              label: const Text('Milestones'),
                              onPressed: () {
                                context.push('/milestones', extra: team.id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
