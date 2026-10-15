import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import '../../shared/models/milestone_model.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/status_badge.dart';
import '../auth/auth_controller.dart';
import '../teams/team_repository.dart';
import 'milestone_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

final milestonesListProvider = FutureProvider.autoDispose<List<MilestoneModel>>((ref) async {
  final repo = ref.watch(milestoneRepositoryProvider);
  return repo.getMilestones();
});

final teamSubmissionsProvider =
    FutureProvider.autoDispose.family<List<SubmissionModel>, String>((ref, teamId) async {
  final repo = ref.watch(milestoneRepositoryProvider);
  return repo.getSubmissionsByTeam(teamId);
});

class MilestonesScreen extends ConsumerWidget {
  final String? teamId;

  const MilestonesScreen({super.key, this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isCoordinator = user?.role.isCoordinator ?? false;
    final isSupervisor = user?.role.isSupervisor ?? false;

    // If teamId is passed (e.g. from supervisor reviewing team), use it.
    if (teamId != null && teamId!.isNotEmpty) {
      return _MilestoneContent(
        targetTeamId: teamId!,
        isCoordinator: isCoordinator,
        isSupervisor: isSupervisor,
      );
    }

    // Otherwise if student, look up own team
    final neuTheme = context.neuTheme;
    final myTeamAsync = ref.watch(myTeamFutureProvider);
    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: NeuAppBar(
        title: 'Milestones & Deliverables',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeuIconButton(
              icon: TablerIcons.rotate_clockwise,
              tooltip: 'Refresh Milestones',
              onPressed: () {
                ref.invalidate(milestonesListProvider);
                ref.invalidate(myTeamFutureProvider);
              },
            ),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: myTeamAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading team data...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(myTeamFutureProvider),
        ),
        data: (team) {
          return _MilestoneContent(
            targetTeamId: team?.id,
            isCoordinator: isCoordinator,
            isSupervisor: isSupervisor,
          );
        },
      ),
      floatingActionButton: isCoordinator
          ? IosNeuFAB(
              tooltip: 'Create New Milestone',
              onPressed: () {
                context.push('/milestones/create').then((_) {
                  ref.invalidate(milestonesListProvider);
                });
              },
            )
          : null,
    );
  }
}

class _MilestoneContent extends ConsumerWidget {
  final String? targetTeamId;
  final bool isCoordinator;
  final bool isSupervisor;

  const _MilestoneContent({
    this.targetTeamId,
    required this.isCoordinator,
    required this.isSupervisor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neuTheme = context.neuTheme;
    final milestonesAsync = ref.watch(milestonesListProvider);
    final submissionsAsync = targetTeamId != null
        ? ref.watch(teamSubmissionsProvider(targetTeamId!))
        : null;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(milestonesListProvider);
        if (targetTeamId != null) {
          ref.invalidate(teamSubmissionsProvider(targetTeamId!));
        }
      },
      child: milestonesAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading academic milestones...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(milestonesListProvider),
        ),
        data: (milestones) {
          if (milestones.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: TablerIcons.flag,
                  title: 'No Milestones Configured',
                  subtitle:
                      'No academic deliverables or milestones have been published for this semester yet.',
                ),
              ),
            );
          }

          final submissions = submissionsAsync?.value ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              final ms = milestones[index];
              final matchingSubmissions =
                  submissions.where((s) => s.milestoneId == ms.id).toList();

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
                              ms.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: neuTheme.textPrimary,
                              ),
                            ),
                          ),
                          StatusBadge(status: ms.isOverdue ? 'rejected' : ms.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (ms.description != null && ms.description!.isNotEmpty) ...[
                        Text(
                          ms.description!,
                          style: TextStyle(fontSize: 13, color: neuTheme.textSecondary),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        children: [
                          const Icon(TablerIcons.calendar_event, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            ms.dueDate != null ? 'Due: ${ms.dueDate}' : 'No fixed deadline',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ms.isOverdue ? AppColors.error : AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          const Icon(TablerIcons.chart_pie, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Weight: ${ms.weightPercentage}% (Max ${ms.maxScore.toInt()} pts)',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),

                      // Submission / Deliverable section
                      const Divider(height: 24),
                      if (matchingSubmissions.isEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Not yet submitted',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            if (targetTeamId != null && !isCoordinator && !isSupervisor) ...[
                              NeuButton(
                                icon: TablerIcons.upload,
                                text: 'Submit Deliverable',
                                isAccent: true,
                                height: 42,
                                borderRadius: BorderRadius.circular(21),
                                onPressed: () {
                                  context
                                      .push('/milestones/submit', extra: {
                                    'milestone_id': ms.id,
                                    'team_id': targetTeamId,
                                    'milestone_title': ms.title,
                                  }).then((_) {
                                    ref.invalidate(teamSubmissionsProvider(targetTeamId!));
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ] else ...[
                        ...matchingSubmissions.map((sub) {
                          return IosNeuCard(
                            isSunken: true,
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sub.title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    StatusBadge(status: sub.status),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (sub.isLate)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      'Late Submission',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (sub.codeUrl != null && sub.codeUrl!.isNotEmpty)
                                  Text(
                                    'Repository: ${sub.codeUrl}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.accent),
                                  ),
                                if (sub.score != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(TablerIcons.sparkles, color: AppColors.warning, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Grade: ${sub.score} / ${ms.maxScore}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (sub.feedback != null && sub.feedback!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Feedback: ${sub.feedback}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: neuTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                ],
                                if ((isSupervisor || isCoordinator) && sub.score == null) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: NeuButton(
                                      icon: TablerIcons.certificate,
                                      text: 'Grade Deliverable',
                                      isAccent: true,
                                      height: 40,
                                      borderRadius: BorderRadius.circular(20),
                                      onPressed: () {
                                        context
                                            .push('/milestones/grade', extra: {
                                          'submission_id': sub.id,
                                          'title': sub.title,
                                          'max_score': ms.maxScore,
                                        }).then((_) {
                                          if (targetTeamId != null) {
                                            ref.invalidate(teamSubmissionsProvider(targetTeamId!));
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
