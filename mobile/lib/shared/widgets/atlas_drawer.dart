import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import '../models/user_model.dart';
import '../../features/auth/auth_controller.dart';

class AtlasDrawer extends ConsumerWidget {
  const AtlasDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neuTheme = context.neuTheme;
    final user = ref.watch(authControllerProvider.select((s) => s.user));
    final role = user?.role ?? UserRole.student;
    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = currentThemeMode == ThemeMode.dark;

    return Drawer(
      backgroundColor: neuTheme.baseColor,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            // Scrollable drawer body containing Header, About ATLAS, and Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  // Neumorphic Header Card
                  NeuContainer(
                    depthType: NeuDepth.convex,
                    depth: 3.5,
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            NeuContainer(
                              shape: BoxShape.circle,
                              width: 52,
                              height: 52,
                              depthType: NeuDepth.convex,
                              depth: 3.0,
                              alignment: Alignment.center,
                              child: Text(
                                user != null && user.firstName.isNotEmpty
                                    ? user.firstName[0].toUpperCase()
                                    : 'A',
                                style: TextStyle(
                                  color: neuTheme.accentColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            NeuIconButton(
                              icon: isDark ? TablerIcons.sun : TablerIcons.moon,
                              size: 38,
                              iconSize: 18,
                              tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                              iconColor: isDark ? const Color(0xFFF6E05E) : neuTheme.accentColor,
                              onPressed: () {
                                ref.read(themeModeProvider.notifier).toggleTheme();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user?.fullName ?? 'ATLAS User',
                          style: TextStyle(
                            color: neuTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: neuTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        NeuBadge.fromStatus(role.name),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _drawerItem(
                    context,
                    icon: TablerIcons.layout_dashboard,
                    title: 'Dashboard',
                    route: '/dashboard',
                  ),

                  // Role-specific destinations
                  if (role.isStudent) ...[
                    _drawerItem(
                      context,
                      icon: TablerIcons.users,
                      title: 'My Thesis Team',
                      route: '/teams/my-team',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.file_description,
                      title: 'Thesis Proposal',
                      route: '/proposals',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.flag,
                      title: 'Milestones & Submissions',
                      route: '/milestones',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.armchair,
                      title: 'Oral Defense',
                      route: '/defenses',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.award,
                      title: 'Official Grades',
                      route: '/grades',
                    ),
                  ] else if (role.isSupervisor) ...[
                    _drawerItem(
                      context,
                      icon: TablerIcons.circles_relation,
                      title: 'Supervised Teams',
                      route: '/supervisor/teams',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.mail_opened,
                      title: 'Supervision Requests',
                      route: '/supervisor/requests',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.clipboard_list,
                      title: 'Milestones & Submissions',
                      route: '/milestones',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.gavel,
                      title: 'Defense Hearings',
                      route: '/defenses',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.checklist,
                      title: 'Rubric Evaluations',
                      route: '/evaluations/rubrics',
                    ),
                  ] else if (role.isCoordinator) ...[
                    _drawerItem(
                      context,
                      icon: TablerIcons.users,
                      title: 'All Thesis Teams',
                      route: '/coordinator/teams',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.users_group,
                      title: 'User Management',
                      route: '/coordinator/users',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.calendar,
                      title: 'Academic Semesters',
                      route: '/coordinator/semesters',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.flag,
                      title: 'Milestone Configuration',
                      route: '/milestones',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.clock,
                      title: 'Defense Scheduling',
                      route: '/defenses',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.ruler,
                      title: 'Rubric Matrices',
                      route: '/evaluations/rubrics',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.shield_check,
                      title: 'Audit Logs',
                      route: '/coordinator/audit-logs',
                    ),
                    _drawerItem(
                      context,
                      icon: TablerIcons.chart_bar,
                      title: 'Department Reports',
                      route: '/coordinator/reports',
                    ),
                  ],

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(
                      color: neuTheme.darkShadow.withValues(alpha: 0.3),
                      thickness: 1,
                    ),
                  ),
                  _drawerItem(
                    context,
                    icon: TablerIcons.bell,
                    title: 'Notifications',
                    route: '/notifications',
                  ),
                  _drawerItem(
                    context,
                    icon: TablerIcons.user,
                    title: 'User Profile',
                    route: '/profile',
                  ),
                ],
              ),
            ),

            // Footer Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: NeuButton(
                text: 'Sign Out',
                icon: TablerIcons.logout,
                isDanger: true,
                height: 46,
                onPressed: () async {
                  Navigator.of(context).pop(); // close drawer
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final neuTheme = context.neuTheme;
    final currentPath = GoRouterState.of(context).uri.toString();
    final isSelected = currentPath == route || currentPath.startsWith('$route/');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: NeuContainer(
        depthType: isSelected ? NeuDepth.concave : NeuDepth.flat,
        depth: isSelected ? 2.0 : 0.0,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: isSelected
            ? Border.all(color: neuTheme.accentColor.withValues(alpha: 0.4), width: 1)
            : Border.all(color: Colors.transparent),
        onTap: () {
          Navigator.of(context).pop(); // close drawer
          context.go(route);
        },
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? neuTheme.accentColor : neuTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? neuTheme.accentColor : neuTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
