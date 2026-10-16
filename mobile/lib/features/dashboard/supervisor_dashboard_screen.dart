import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../auth/auth_controller.dart';
import '../supervisor/supervisor_repository.dart';

class SupervisorDashboardScreen extends ConsumerWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neuTheme = context.neuTheme;
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final requestsAsync = ref.watch(supervisorRequestsProvider);
    final teamsAsync = ref.watch(supervisedTeamsProvider);

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: NeuAppBar(
        title: 'Faculty Portal',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeuIconButton(
              icon: TablerIcons.bell,
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
            ),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: RefreshIndicator(
        color: neuTheme.accentColor,
        backgroundColor: neuTheme.baseColor,
        onRefresh: () async {
          ref.invalidate(supervisorRequestsProvider);
          ref.invalidate(supervisedTeamsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              NeuContainer(
                depthType: NeuDepth.convex,
                depth: 4.0,
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Prof. ${user?.lastName ?? user?.firstName ?? 'Faculty'}',
                            style: TextStyle(
                              color: neuTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage candidate supervision, milestone grading, and defense committee evaluations.',
                            style: TextStyle(
                              color: neuTheme.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    NeuContainer(
                      shape: BoxShape.circle,
                      width: 54,
                      height: 54,
                      depthType: NeuDepth.convex,
                      depth: 3.0,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/play_store_512.png',
                          width: 46,
                          height: 46,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // KPI Counters
              Row(
                children: [
                  Expanded(
                    child: NeuContainer(
                      depthType: NeuDepth.convex,
                      depth: 3.5,
                      borderRadius: BorderRadius.circular(18),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SUPERVISED TEAMS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: neuTheme.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          teamsAsync.when(
                            loading: () => const Text('...', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                            error: (err, stack) => const Text('0', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                            data: (teams) => Text(
                              '${teams.length}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: neuTheme.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NeuContainer(
                      depthType: NeuDepth.convex,
                      depth: 3.5,
                      borderRadius: BorderRadius.circular(18),
                      padding: const EdgeInsets.all(18),
                      onTap: () => context.push('/supervisor/requests'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PENDING REQUESTS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: neuTheme.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          requestsAsync.when(
                            loading: () => const Text('...', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                            error: (err, stack) => const Text('0', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                            data: (reqs) => Text(
                              '${reqs.length}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: reqs.isNotEmpty ? neuTheme.warningColor : neuTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Supervision Tasks Header
              Text(
                'SUPERVISION TASKS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: neuTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 14),

              _taskCard(
                context,
                title: 'Supervision Requests Inbox',
                description: 'Review student team mentorship invitations',
                icon: TablerIcons.mail_opened,
                badgeCount: requestsAsync.valueOrNull?.length,
                onTap: () => context.push('/supervisor/requests'),
              ),
              const SizedBox(height: 14),

              _taskCard(
                context,
                title: 'Assigned Teams Roster',
                description: 'Review proposals, monitor deliverable milestones',
                icon: TablerIcons.users,
                badgeCount: teamsAsync.valueOrNull?.length,
                onTap: () => context.push('/supervisor/teams'),
              ),
              const SizedBox(height: 14),

              _taskCard(
                context,
                title: 'Deliverables & Submissions',
                description: 'Inspect code repositories and submit grades',
                icon: TablerIcons.clipboard_list,
                onTap: () => context.push('/milestones'),
              ),
              const SizedBox(height: 14),

              _taskCard(
                context,
                title: 'Defense Hearings & Rubrics',
                description: 'Examine candidates and enter multi-criteria scores',
                icon: TablerIcons.gavel,
                onTap: () => context.push('/defenses'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    final neuTheme = context.neuTheme;

    return NeuContainer(
      depthType: NeuDepth.convex,
      depth: 3.5,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      onTap: onTap,
      child: Row(
        children: [
          NeuContainer(
            shape: BoxShape.circle,
            width: 44,
            height: 44,
            depthType: NeuDepth.convex,
            depth: 2.5,
            alignment: Alignment.center,
            child: Icon(icon, color: neuTheme.accentColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: neuTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: neuTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (badgeCount != null && badgeCount > 0) ...[
            NeuBadge(label: '$badgeCount', color: neuTheme.warningColor),
            const SizedBox(width: 8),
          ],
          Icon(TablerIcons.chevron_right, size: 20, color: neuTheme.textSecondary.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}
