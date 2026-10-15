import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/status_badge.dart';
import '../auth/auth_controller.dart';
import '../teams/team_repository.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neuTheme = context.neuTheme;
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final teamAsync = ref.watch(myTeamProvider);

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: NeuAppBar(
        title: 'Student Workspace',
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
          ref.invalidate(myTeamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Extruded Banner
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
                          Row(
                            children: [
                              Text(
                                'Welcome back, ',
                                style: TextStyle(
                                  color: neuTheme.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                user?.firstName ?? 'Candidate',
                                style: TextStyle(
                                  color: neuTheme.accentColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Academic Thesis Progression',
                            style: TextStyle(
                              color: neuTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your milestone deliverables, reviews, and oral defense hearing.',
                            style: TextStyle(
                              color: neuTheme.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    NeuContainer(
                      shape: BoxShape.circle,
                      width: 52,
                      height: 52,
                      depthType: NeuDepth.convex,
                      depth: 3.0,
                      alignment: Alignment.center,
                      child: Icon(TablerIcons.school, color: neuTheme.accentColor, size: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Team Status Card
              teamAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => NeuContainer(
                  depthType: NeuDepth.concave,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading team: $e', style: TextStyle(color: neuTheme.dangerColor)),
                ),
                data: (team) {
                  if (team == null) {
                    return NeuContainer(
                      depthType: NeuDepth.convex,
                      depth: 3.5,
                      borderRadius: BorderRadius.circular(20),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              NeuContainer(
                                shape: BoxShape.circle,
                                width: 42,
                                height: 42,
                                depthType: NeuDepth.concave,
                                alignment: Alignment.center,
                                child: Icon(TablerIcons.user_plus, color: neuTheme.accentColor, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Form Your Thesis Team',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: neuTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'You do not have an active thesis team yet. Create a new team as leader or join using an invite code.',
                            style: TextStyle(fontSize: 13, color: neuTheme.textSecondary, height: 1.4),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: NeuButton(
                                  text: 'Create Team',
                                  icon: TablerIcons.plus,
                                  isAccent: true,
                                  height: 44,
                                  onPressed: () => context.push('/teams/create'),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: NeuButton(
                                  text: 'Join with Code',
                                  icon: TablerIcons.link,
                                  height: 44,
                                  onPressed: () => context.push('/teams/join'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return NeuContainer(
                    depthType: NeuDepth.convex,
                    depth: 4.0,
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.all(20),
                    onTap: () => context.push('/teams/my-team'),
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: neuTheme.textPrimary,
                                ),
                              ),
                            ),
                            StatusBadge(status: team.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          team.projectTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: neuTheme.textSecondary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(
                            color: neuTheme.darkShadow.withValues(alpha: 0.3),
                            thickness: 1,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(TablerIcons.users, size: 18, color: neuTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  '${team.members.length} Members',
                                  style: TextStyle(fontSize: 13, color: neuTheme.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            if (team.supervisor != null)
                              Row(
                                children: [
                                  Icon(TablerIcons.school, size: 18, color: neuTheme.accentColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    team.supervisor!.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: neuTheme.accentColor,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'No Supervisor Assigned',
                                style: TextStyle(fontSize: 12, color: neuTheme.warningColor, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Lifecycle Modules Header
              Text(
                'LIFECYCLE MODULES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: neuTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),

              // Tactile 2x2 Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.25,
                children: [
                  _actionTile(
                    context,
                    icon: TablerIcons.file_description,
                    title: 'Thesis Proposal',
                    subtitle: 'Draft & Revisions',
                    iconColor: neuTheme.accentColor,
                    route: '/proposals',
                  ),
                  _actionTile(
                    context,
                    icon: TablerIcons.flag,
                    title: 'Milestones',
                    subtitle: 'Code & Reports',
                    iconColor: neuTheme.successColor,
                    route: '/milestones',
                  ),
                  _actionTile(
                    context,
                    icon: TablerIcons.gavel,
                    title: 'Defense Hearing',
                    subtitle: 'Venue & Panel',
                    iconColor: neuTheme.warningColor,
                    route: '/defenses',
                  ),
                  _actionTile(
                    context,
                    icon: TablerIcons.award,
                    title: 'Official Grades',
                    subtitle: 'Score Transcript',
                    iconColor: const Color(0xFF9F7AEA),
                    route: '/grades',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required String route,
  }) {
    final neuTheme = context.neuTheme;

    return NeuContainer(
      depthType: NeuDepth.convex,
      depth: 3.5,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(16),
      onTap: () => context.push(route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          NeuContainer(
            shape: BoxShape.circle,
            width: 42,
            height: 42,
            depthType: NeuDepth.convex,
            depth: 2.5,
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: neuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: neuTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
