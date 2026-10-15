import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/proposal_model.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/status_badge.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import '../auth/auth_controller.dart';
import '../teams/team_repository.dart';
import 'proposal_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

final proposalFutureProvider =
    FutureProvider.autoDispose.family<ProposalModel?, String>((ref, teamId) async {
  final repo = ref.watch(proposalRepositoryProvider);
  return repo.getProposalByTeam(teamId);
});

class ProposalsScreen extends ConsumerWidget {
  final String? teamId;

  const ProposalsScreen({super.key, this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isStudent = user?.role.isStudent ?? true;
    final isSupervisor = user?.role.isSupervisor ?? false;

    // If teamId is passed, use it directly. Otherwise look up current user's team.
    if (teamId != null && teamId!.isNotEmpty) {
      return _ProposalView(teamId: teamId!, isStudent: isStudent, isSupervisor: isSupervisor);
    }

    // Lookup current student team
    final myTeamAsync = ref.watch(myTeamFutureProvider);
    return Scaffold(
      appBar: const NeuAppBar(
        title: 'Thesis Proposal',
      ),
      drawer: const AtlasDrawer(),
      body: myTeamAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading team context...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(myTeamFutureProvider),
        ),
        data: (team) {
          if (team == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: TablerIcons.user_off,
                  title: 'No Team Found',
                  subtitle: 'You must form or join a thesis team before drafting a proposal.',
                  actionLabel: 'Go to Team Management',
                  onAction: () => context.go('/teams/my-team'),
                ),
              ),
            );
          }
          return _ProposalView(teamId: team.id, isStudent: isStudent, isSupervisor: isSupervisor);
        },
      ),
    );
  }
}

class _ProposalView extends ConsumerWidget {
  final String teamId;
  final bool isStudent;
  final bool isSupervisor;

  const _ProposalView({
    required this.teamId,
    required this.isStudent,
    required this.isSupervisor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neuTheme = context.neuTheme;
    final proposalAsync = ref.watch(proposalFutureProvider(teamId));

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: NeuAppBar(
        title: 'Thesis Proposal Details',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeuIconButton(
              icon: TablerIcons.rotate_clockwise,
              tooltip: 'Refresh Proposal',
              onPressed: () => ref.refresh(proposalFutureProvider(teamId)),
            ),
          ),
        ],
      ),
      body: proposalAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading proposal status...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(proposalFutureProvider(teamId)),
        ),
        data: (proposal) {
          if (proposal == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: TablerIcons.file_description,
                  title: 'No Proposal Submitted',
                  subtitle: isStudent
                      ? 'Prepare your research proposal draft, outline the objectives, and submit for faculty review.'
                      : 'This team has not submitted a research proposal yet.',
                  actionLabel: isStudent ? 'Draft & Submit Proposal' : null,
                  onAction: isStudent
                      ? () => context.push('/proposals/submit', extra: teamId).then((_) {
                            ref.invalidate(proposalFutureProvider(teamId));
                          })
                      : null,
                ),
              ),
            );
          }

          final canSubmitRevision = isStudent &&
              (proposal.status == 'changes_requested' ||
                  proposal.status == 'rejected' ||
                  proposal.status == 'draft');

          final canReview = isSupervisor &&
              (proposal.status == 'submitted' || proposal.status == 'under_review');

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(proposalFutureProvider(teamId)),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Header Status Card
                AtlasCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Version ${proposal.currentVersion}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          StatusBadge(status: proposal.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        proposal.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: neuTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Abstract & Research Objectives',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: neuTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        proposal.abstractText,
                        style: TextStyle(
                          fontSize: 14,
                          color: neuTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Reviewer Decisions & Comments
                AtlasCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(TablerIcons.message_circle, size: 20, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Faculty Evaluation & Feedback',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: neuTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (proposal.reviews.isEmpty) ...[
                        Text(
                          'No formal faculty reviews have been submitted for this proposal yet.',
                          style: TextStyle(fontSize: 13, color: neuTheme.textSecondary),
                        ),
                      ] else ...[
                        ...proposal.reviews.map((r) {
                          return IosNeuCard(
                            isSunken: true,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      r.reviewerName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: neuTheme.textPrimary,
                                      ),
                                    ),
                                    StatusBadge(status: r.decision),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  r.comments,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: neuTheme.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Version History Card
                AtlasCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(TablerIcons.history, size: 20, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Version History',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: neuTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...proposal.versions.map((v) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.infoBg,
                                child: Text(
                                  'v${v.versionNumber}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (v.changeSummary != null && v.changeSummary!.isNotEmpty)
                                      Text(
                                        'Changes: ${v.changeSummary}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: neuTheme.textSecondary,
                                        ),
                                      ),
                                    Text(
                                      'Submitted by ${v.submittedByName}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                if (canSubmitRevision) ...[
                  IosNeuButton(
                    icon: TablerIcons.file_pencil,
                    text: 'Submit Revised Proposal',
                    isPrimary: true,
                    height: 50,
                    borderRadius: BorderRadius.circular(25),
                    onPressed: () {
                      context.push('/proposals/submit', extra: teamId).then((_) {
                        ref.invalidate(proposalFutureProvider(teamId));
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                if (canReview) ...[
                  IosNeuButton(
                    icon: TablerIcons.message_report,
                    text: 'Submit Review Decision',
                    isPrimary: true,
                    height: 50,
                    borderRadius: BorderRadius.circular(25),
                    onPressed: () {
                      context.push('/proposals/review/${proposal.id}').then((_) {
                        ref.invalidate(proposalFutureProvider(teamId));
                      });
                    },
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
