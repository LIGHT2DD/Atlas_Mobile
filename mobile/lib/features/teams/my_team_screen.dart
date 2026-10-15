import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import '../../shared/models/team_model.dart';
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
    final neuTheme = context.neuTheme;
    final teamAsync = ref.watch(myTeamFutureProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: NeuAppBar(
        title: 'My Thesis Team',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeuIconButton(
              icon: TablerIcons.rotate_clockwise,
              tooltip: 'Refresh Team Data',
              onPressed: () => ref.refresh(myTeamFutureProvider),
            ),
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
                  icon: TablerIcons.user_off,
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
            color: neuTheme.accentColor,
            backgroundColor: neuTheme.baseColor,
            onRefresh: () async => ref.refresh(myTeamFutureProvider),
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                // Team Overview Header Card
                NeuContainer(
                  depthType: NeuDepth.convex,
                  depth: 4.0,
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(20),
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
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: neuTheme.textPrimary,
                              ),
                            ),
                          ),
                          StatusBadge(status: team.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        team.projectTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: neuTheme.accentColor,
                        ),
                      ),
                      if (team.description != null && team.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          team.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: neuTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Divider(
                          color: neuTheme.darkShadow.withValues(alpha: 0.3),
                          thickness: 1,
                        ),
                      ),

                      // Sunken Invite Code Box
                      NeuContainer(
                        depthType: NeuDepth.concave,
                        borderRadius: BorderRadius.circular(14),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Team Invite Code',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: neuTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  team.inviteCode,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.5,
                                    color: neuTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            NeuIconButton(
                              icon: TablerIcons.copy,
                              size: 38,
                              iconSize: 18,
                              tooltip: 'Copy Invite Code',
                              iconColor: neuTheme.accentColor,
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: team.inviteCode));
                                NeuToast.show(
                                  context,
                                  message: 'Invite code copied to clipboard!',
                                  type: NeuToastType.info,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Faculty Supervisor Card
                NeuContainer(
                  depthType: NeuDepth.convex,
                  depth: 3.5,
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(TablerIcons.school, size: 20, color: neuTheme.accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'Academic Supervisor',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: neuTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (team.supervisor != null) ...[
                        Row(
                          children: [
                            NeuContainer(
                              shape: BoxShape.circle,
                              width: 44,
                              height: 44,
                              depthType: NeuDepth.convex,
                              alignment: Alignment.center,
                              child: Icon(TablerIcons.user, color: neuTheme.accentColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.supervisor!.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: neuTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    team.supervisor!.email,
                                    style: TextStyle(fontSize: 12, color: neuTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const StatusBadge(
                              status: 'assigned',
                              customLabel: 'Assigned',
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'No faculty supervisor has been assigned to this team yet.',
                          style: TextStyle(fontSize: 13, color: neuTheme.textSecondary),
                        ),
                        if (isLeader) ...[
                          const SizedBox(height: 16),
                          NeuButton(
                            text: 'Request Faculty Supervisor',
                            icon: TablerIcons.user_plus,
                            isAccent: true,
                            height: 44,
                            onPressed: () {
                              context.push('/teams/request-supervisor', extra: team.id).then((_) {
                                ref.invalidate(myTeamFutureProvider);
                              });
                            },
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Team Members Card
                NeuContainer(
                  depthType: NeuDepth.convex,
                  depth: 3.5,
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(TablerIcons.users, size: 20, color: neuTheme.accentColor),
                              const SizedBox(width: 8),
                              Text(
                                'Team Roster',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: neuTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${team.members.length} Member(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: neuTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...team.members.map((m) {
                        final memberIsLeader = m.role == 'leader' || m.userId == team.leaderId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: NeuContainer(
                            depthType: NeuDepth.flat,
                            borderRadius: BorderRadius.circular(12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                NeuContainer(
                                  shape: BoxShape.circle,
                                  width: 36,
                                  height: 36,
                                  depthType: NeuDepth.convex,
                                  depth: 2.0,
                                  alignment: Alignment.center,
                                  child: Text(
                                    m.name.isNotEmpty ? m.name[0].toUpperCase() : 'U',
                                    style: TextStyle(
                                      color: memberIsLeader ? neuTheme.accentColor : neuTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: neuTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        m.email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: neuTheme.textSecondary,
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
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Leave Team Button
                Center(
                  child: NeuButton(
                    text: 'Leave Team',
                    icon: TablerIcons.logout,
                    isDanger: true,
                    height: 44,
                    width: 170,
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
    final neuTheme = context.neuTheme;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: IosNeuCard(
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leave Team?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: neuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to depart from "${team.name}"? If you are the leader and sole member, this action will disassociate the team.',
                style: TextStyle(fontSize: 14, color: neuTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IosNeuButton(
                    text: 'Cancel',
                    isPrimary: false,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  const SizedBox(width: 12),
                  IosNeuButton(
                    text: 'Confirm Leave',
                    isPrimary: true,
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      try {
                        final repo = ref.read(teamRepositoryProvider);
                        final msg = await repo.leaveTeam(team.id);
                        if (context.mounted) {
                          NeuToast.show(context, message: msg, type: NeuToastType.info);
                          ref.invalidate(myTeamFutureProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          NeuToast.show(context, message: e.toString(), type: NeuToastType.error);
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
