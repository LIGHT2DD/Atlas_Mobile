import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/status_badge.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neuTheme = context.neuTheme;
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: const NeuAppBar(title: 'User Profile'),
      drawer: const AtlasDrawer(),
      body: user == null
          ? Center(
              child: Text(
                'No active session',
                style: TextStyle(color: neuTheme.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                // Profile Extruded Avatar & Header Card
                NeuContainer(
                  depthType: NeuDepth.convex,
                  depth: 4.0,
                  borderRadius: BorderRadius.circular(22),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                  child: Column(
                    children: [
                      NeuContainer(
                        shape: BoxShape.circle,
                        width: 86,
                        height: 86,
                        depthType: NeuDepth.convex,
                        depth: 4.0,
                        alignment: Alignment.center,
                        child: Text(
                          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'A',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: neuTheme.accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: neuTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: neuTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      StatusBadge(
                        status: user.role.name,
                        customLabel: user.role.displayName,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Account Information
                NeuContainer(
                  depthType: NeuDepth.convex,
                  depth: 3.5,
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: neuTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _infoRow(context, label: 'Account Status', value: user.isActive ? 'Active' : 'Inactive'),
                      _divider(neuTheme),
                      _infoRow(context, label: 'User ID', value: user.id),
                      if (user.department != null && user.department!.isNotEmpty) ...[
                        _divider(neuTheme),
                        _infoRow(context, label: 'Department', value: user.department!),
                      ],
                      if (user.studentId != null && user.studentId!.isNotEmpty) ...[
                        _divider(neuTheme),
                        _infoRow(context, label: 'Student ID', value: user.studentId!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Appearance & Theme Preferences
                NeuContainer(
                  depthType: NeuDepth.convex,
                  depth: 3.5,
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance & Theme Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: neuTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDark ? TablerIcons.moon : TablerIcons.sun,
                                size: 20,
                                color: isDark ? const Color(0xFFF6E05E) : neuTheme.accentColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Dark Mode Theme',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: neuTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          NeuSwitch(
                            value: isDark,
                            onChanged: (val) {
                              ref.read(themeModeProvider.notifier).setTheme(
                                val ? ThemeMode.dark : ThemeMode.light,
                              );
                            },
                          ),
                        ],
                      ),
                      _divider(neuTheme),
                      GestureDetector(
                        onTap: () => context.push('/forgot-password'),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(TablerIcons.lock_access, size: 20, color: neuTheme.accentColor),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password Recovery',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: neuTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Dispatch password reset token',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: neuTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Icon(TablerIcons.chevron_right, size: 18, color: neuTheme.textSecondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Sign Out Button
                NeuButton(
                  text: 'Sign Out of ATLAS',
                  icon: TablerIcons.logout,
                  isDanger: true,
                  height: 52,
                  onPressed: () => _confirmSignOut(context, ref),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _divider(NeumorphicThemeData neuTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        color: neuTheme.darkShadow.withValues(alpha: 0.3),
        thickness: 1,
        height: 1,
      ),
    );
  }

  Widget _infoRow(BuildContext context, {required String label, required String value}) {
    final neuTheme = context.neuTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: neuTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: neuTheme.textPrimary),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    final neuTheme = context.neuTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: neuTheme.baseColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: TextStyle(color: neuTheme.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to end your ATLAS mobile session?',
          style: TextStyle(color: neuTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: neuTheme.textSecondary)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          NeuButton(
            text: 'Sign Out',
            isDanger: true,
            height: 40,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
