import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../auth/auth_controller.dart';
import 'team_repository.dart';

class MyTeamScreen extends ConsumerWidget {
  const MyTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(myTeamFutureProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Thesis Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(myTeamFutureProvider),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: teamAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading team details...'),
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
                  icon: Icons.group_off_outlined,
                  title: 'No Team Formed Yet',
                  subtitle:
                      'Join an existing team with an invitation code, or initiate your own project team as leader.',
                  actionLabel: 'Create New Team',
                  onAction: () => context.push('/teams/create').then((_) {
                    ref.invalidate(myTeamFutureProvider);
                  }),
                  secondaryActionLabel: 'Join Team',
                  onSecondaryAction: () => context.push('/teams/join').then((_) {
                    ref.invalidate(myTeamFutureProvider);
                  }),
                ),
              ),
            );
          }

          final isLeader = team.isLeader || (user != null && team.leaderId == user.id);

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myTeamFutureProvider),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Team Overview Header Card
                AtlasCard(
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          StatusBadge(status: team.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        team.projectTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                      if (team.description != null && team.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          team.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      // Invite Code Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Team Invite Code',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  team.inviteCode,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20, color: AppColors.accent),
                              tooltip: 'Copy Invite Code',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: team.inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invite code copied to clipboard!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Faculty Supervisor Card
                AtlasCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.school_outlined, size: 20, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text(
                            'Academic Supervisor',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (team.supervisor != null) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            team.supervisor!.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(team.supervisor!.email),
                          trailing: const StatusBadge(
                            status: 'assigned',
                            customLabel: 'Assigned',
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'No faculty supervisor has been assigned to this team yet.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        if (isLeader) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.person_add_alt),
                              label: const Text('Request Faculty Supervisor'),
                              onPressed: () {
                                context.push('/teams/request-supervisor', extra: team.id).then((_) {
                                  ref.invalidate(myTeamFutureProvider);
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Team Members Card
                AtlasCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.people_outline, size: 20, color: AppColors.accent),
                              SizedBox(width: 8),
                              Text(
                                'Team Roster',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${team.members.length} Member(s)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...team.members.map((m) {
                        final memberIsLeader = m.role == 'leader' || m.userId == team.leaderId;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: memberIsLeader ? AppColors.accent : AppColors.card,
                                child: Text(
                                  m.name.isNotEmpty ? m.name[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    color: memberIsLeader ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      m.email,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (memberIsLeader)
                                const StatusBadge(
                                  status: 'leader',
                                  customLabel: 'Team Leader',
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Leave Team Button
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.exit_to_app, color: AppColors.error),
                    label: const Text(
                      'Leave Team',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => _confirmLeaveTeam(context, ref, team),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmLeaveTeam(BuildContext context, WidgetRef ref, TeamModel team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Team?'),
        content: Text(
          'Are you sure you want to depart from "${team.name}"? If you are the leader and sole member, this action will disassociate the team.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm Leave'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final repo = ref.read(teamRepositoryProvider);
                final msg = await repo.leaveTeam(team.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  ref.invalidate(myTeamFutureProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
