import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/team_model.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/status_badge.dart';
import '../evaluations/evaluation_repository.dart';
import '../teams/team_repository.dart';
import 'coordinator_repository.dart';

final allTeamsFutureProvider = FutureProvider.autoDispose<List<TeamModel>>((ref) async {
  final repo = ref.watch(coordinatorRepositoryProvider);
  return repo.getAllTeams();
});

class CoordinatorTeamsScreen extends ConsumerWidget {
  const CoordinatorTeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(allTeamsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Thesis Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(allTeamsFutureProvider),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: teamsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading departmental teams...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(allTeamsFutureProvider),
        ),
        data: (teams) {
          if (teams.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: Icons.groups_3_outlined,
                  title: 'No Registered Teams',
                  subtitle: 'Student project teams will appear here once registered.',
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(allTeamsFutureProvider),
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
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${team.members.length} members',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.school_outlined, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                team.supervisor != null
                                    ? 'Supervisor: ${team.supervisor!.name}'
                                    : 'Supervisor: None Assigned',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: team.supervisor != null
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  fontWeight: team.supervisor != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.person_add, size: 16),
                              label: const Text('Assign Supervisor'),
                              onPressed: () => _assignSupervisorDialog(context, ref, team),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.article_outlined, size: 16),
                              label: const Text('Proposal'),
                              onPressed: () {
                                context.push('/proposals', extra: team.id);
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.flag_outlined, size: 16),
                              label: const Text('Milestones'),
                              onPressed: () {
                                context.push('/milestones', extra: team.id);
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.rate_review_outlined, size: 16),
                              label: const Text('Score'),
                              onPressed: () {
                                context.push('/evaluations/score', extra: {
                                  'team_id': team.id,
                                  'team_name': team.name,
                                });
                              },
                            ),
                            if (!team.gradePublished) ...[
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                icon: const Icon(Icons.publish, size: 16),
                                label: const Text('Publish Grade'),
                                onPressed: () => _publishGrade(context, ref, team),
                              ),
                            ],
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

  void _assignSupervisorDialog(BuildContext context, WidgetRef ref, TeamModel team) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final supervisorsAsync = ref.watch(supervisorsFutureProvider);
          return AlertDialog(
            title: Text('Assign Supervisor: ${team.name}'),
            content: supervisorsAsync.when(
              loading: () => const SizedBox(height: 80, child: LoadingIndicator()),
              error: (e, _) => Text('Error loading faculty: $e'),
              data: (supervisors) {
                return SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: supervisors.length,
                    itemBuilder: (context, i) {
                      final s = supervisors[i];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person, size: 18)),
                        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(s.email, style: const TextStyle(fontSize: 12)),
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          try {
                            final repo = ref.read(coordinatorRepositoryProvider);
                            final msg = await repo.assignSupervisor(team.id, s.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg), backgroundColor: AppColors.success),
                              );
                              ref.invalidate(allTeamsFutureProvider);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _publishGrade(BuildContext context, WidgetRef ref, TeamModel team) async {
    try {
      final repo = ref.read(evaluationRepositoryProvider);
      final msg = await repo.publishGrade(team.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
        ref.invalidate(allTeamsFutureProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
