import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../auth/auth_controller.dart';
import '../teams/team_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final teamAsync = ref.watch(myTeamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Workspace'),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.bell),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myTeamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${user?.firstName ?? 'Candidate'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Track your academic capstone progression from proposal to final oral defense.',
                      style: TextStyle(color: AppColors.divider, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Team Status Card
              teamAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => AtlasCard(
                  child: Text('Error loading team: $e', style: const TextStyle(color: AppColors.error)),
                ),
                data: (team) {
                  if (team == null) {
                    return AtlasCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(TablerIcons.user_plus, color: AppColors.accent, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Form Your Thesis Team',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You do not have an active thesis team yet. Create a new team as leader or join using an invite code.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push('/teams/create'),
                                  icon: const Icon(TablerIcons.plus, size: 18),
                                  label: const Text('Create Team'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push('/teams/join'),
                                  icon: const Icon(TablerIcons.link, size: 18),
                                  label: const Text('Join with Code'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return AtlasCard(
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            StatusBadge(status: team.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          team.projectTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(TablerIcons.users, size: 18, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  '${team.members.length} Members',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            if (team.supervisor != null)
                              Row(
                                children: [
                                  const Icon(TablerIcons.school, size: 18, color: AppColors.accent),
                                  const SizedBox(width: 6),
                                  Text(
                                    team.supervisor!.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                'No Supervisor Assigned',
                                style: TextStyle(fontSize: 12, color: AppColors.warning),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Quick Actions Grid
              const Text(
                'LIFECYCLE MODULES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _actionTile(
                    context,
                    icon: TablerIcons.file_description,
                    title: 'Thesis Proposal',
                    subtitle: 'Draft & Revisions',
                    color: const Color(0xFFE0E7FF),
                    iconColor: AppColors.accent,
                    route: '/proposals',
                  ),
                  _actionTile(
                    context,
                    icon: TablerIcons.flag,
                    title: 'Milestones',
                    subtitle: 'Code & Reports',
                    color: const Color(0xFFDCFCE7),
                    iconColor: AppColors.success,
                    route: '/milestones',
                  ),
                  _actionTile(
                    context,
                    icon: TablerIcons.gavel,
                    title: 'Defense Hearing',
                    subtitle: 'Venue & Panel',
                    color: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    route: '/defenses',
                  ),
                  _actionTile(
                    context,
                    icon: TablerIcons.award,
                    title: 'Official Grades',
                    subtitle: 'Score Transcript',
                    color: const Color(0xFFEDE9FE),
                    iconColor: const Color(0xFF7C3AED),
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
    required Color color,
    required Color iconColor,
    required String route,
  }) {
    return AtlasCard(
      onTap: () => context.push(route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
