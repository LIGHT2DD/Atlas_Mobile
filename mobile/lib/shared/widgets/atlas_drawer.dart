import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../models/user_model.dart';
import '../../features/auth/auth_controller.dart';
import 'status_badge.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class AtlasDrawer extends ConsumerWidget {
  const AtlasDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final role = user?.role ?? UserRole.student;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      user != null && user.firstName.isNotEmpty
                          ? user.firstName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'ATLAS User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StatusBadge(status: role.name, customLabel: role.displayName),
                ],
              ),
            ),

            // Navigation List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
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

                  const Divider(),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: ListTile(
                leading: const Icon(TablerIcons.logout, color: AppColors.error),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () async {
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
    final currentPath = GoRouterState.of(context).uri.toString();
    final isSelected = currentPath == route || currentPath.startsWith('$route/');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        tileColor: isSelected ? AppColors.infoBg.withAlpha(100) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          Navigator.of(context).pop(); // close drawer
          context.go(route);
        },
      ),
    );
  }
}
