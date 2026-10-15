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
import '../../widgets/neumorphic/neumorphic.dart';
import '../evaluations/evaluation_repository.dart';
import '../teams/team_repository.dart';
import 'coordinator_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

final allTeamsFutureProvider = FutureProvider.autoDispose<List<TeamModel>>((ref) async {
  final repo = ref.watch(coordinatorRepositoryProvider);
  return repo.getAllTeams();
});

class CoordinatorTeamsScreen extends ConsumerWidget {
  const CoordinatorTeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neuTheme = context.neuTheme;
    final teamsAsync = ref.watch(allTeamsFutureProvider);

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: NeuAppBar(
        title: 'All Thesis Teams',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeuIconButton(
              icon: TablerIcons.rotate_clockwise,
              tooltip: 'Refresh Teams',
              onPressed: () => ref.refresh(allTeamsFutureProvider),
            ),
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
                  icon: TablerIcons.users,
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
                  padding: const EdgeInsets.only(bottom: 14.0),
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
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: neuTheme.textPrimary,
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
                            const Icon(TablerIcons.users, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${team.members.length} members',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 16),
                            const Icon(TablerIcons.school, size: 14, color: AppColors.textMuted),
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
                            IosNeuButton(
                              icon: TablerIcons.user_plus,
                              text: 'Assign',
                              isPrimary: false,
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              onPressed: () => _assignSupervisorDialog(context, ref, team),
                            ),
                            IosNeuButton(
                              icon: TablerIcons.article,
                              text: 'Proposal',
                              isPrimary: false,
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              onPressed: () {
                                context.push('/proposals', extra: team.id);
                              },
                            ),
                            IosNeuButton(
                              icon: TablerIcons.flag,
                              text: 'Milestones',
                              isPrimary: false,
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              onPressed: () {
                                context.push('/milestones', extra: team.id);
                              },
                            ),
                            IosNeuButton(
                              icon: TablerIcons.message_report,
                              text: 'Score',
                              isPrimary: true,
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              onPressed: () {
                                context.push('/evaluations/score', extra: {
                                  'team_id': team.id,
                                  'team_name': team.name,
                                });
                              },
                            ),
                            if (!team.gradePublished) ...[
                              IosNeuButton(
                                icon: TablerIcons.upload,
                                text: 'Publish',
                                isPrimary: true,
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
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
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final neuTheme = context.neuTheme;
          final supervisorsAsync = ref.watch(supervisorsFutureProvider);
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: IosNeuCard(
              isLarge: true,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Assign Supervisor: ${team.name}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: neuTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  supervisorsAsync.when(
                    loading: () => const SizedBox(height: 80, child: LoadingIndicator()),
                    error: (e, _) => Text('Error loading faculty: $e', style: TextStyle(color: neuTheme.textPrimary)),
                    data: (supervisors) {
                      return SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: supervisors.length,
                          itemBuilder: (context, i) {
                            final s = supervisors[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: IosNeuCard(
                                isSunken: true,
                                padding: const EdgeInsets.all(12),
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
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: IosNeuColors.inactiveBadge,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(TablerIcons.user, size: 18, color: neuTheme.textPrimary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: neuTheme.textPrimary)),
                                          Text(s.email, style: TextStyle(fontSize: 12, color: neuTheme.textSecondary)),
                                        ],
                                      ),
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
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IosNeuButton(
                      text: 'Cancel',
                      isPrimary: false,
                      height: 40,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ],
              ),
            ),
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
