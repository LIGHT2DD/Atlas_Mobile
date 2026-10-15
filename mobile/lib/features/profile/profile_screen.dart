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
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: IosNeuColors.canvas,
      appBar: const NeuAppBar(title: 'User Profile'),
      drawer: const AtlasDrawer(),
      body: user == null
          ? const Center(
              child: Text(
                'No active session',
                style: TextStyle(color: IosNeuColors.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              children: [
                // Profile Extruded Avatar & Header Card
                IosNeuCard(
                  borderRadius: BorderRadius.circular(28),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                  child: Column(
                    children: [
                      IosNeuCard(
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: IosNeuColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: IosNeuColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: IosNeuColors.textSecondary,
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
                IosNeuCard(
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: IosNeuColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _infoRow(context, label: 'Account Status', value: user.isActive ? 'Active' : 'Inactive'),
                      _divider(),
                      _infoRow(context, label: 'User ID', value: user.id),
                      if (user.department != null && user.department!.isNotEmpty) ...[
                        _divider(),
                        _infoRow(context, label: 'Department', value: user.department!),
                      ],
                      if (user.studentId != null && user.studentId!.isNotEmpty) ...[
                        _divider(),
                        _infoRow(context, label: 'Student ID', value: user.studentId!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Appearance & Theme Preferences
                IosNeuCard(
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appearance & Theme Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: IosNeuColors.textPrimary,
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
                                color: isDark ? const Color(0xFFF6E05E) : IosNeuColors.textPrimary,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Dark Mode Theme',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: IosNeuColors.textPrimary,
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
                      _divider(),
                      GestureDetector(
                        onTap: () => context.push('/forgot-password'),
                        behavior: HitTestBehavior.opaque,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(TablerIcons.lock_access, size: 20, color: IosNeuColors.textPrimary),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password Recovery',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: IosNeuColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Dispatch password reset token',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: IosNeuColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Icon(TablerIcons.chevron_right, size: 18, color: IosNeuColors.textSecondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Sign Out Button
                IosNeuButton(
                  text: 'Sign Out of ATLAS',
                  icon: TablerIcons.logout,
                  isPrimary: false,
                  height: 52,
                  onPressed: () => _confirmSignOut(context, ref),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        color: IosNeuColors.inactiveBadge,
        thickness: 1,
        height: 1,
      ),
    );
  }

  Widget _infoRow(BuildContext context, {required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: IosNeuColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: IosNeuColors.textPrimary),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
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
              const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: IosNeuColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to end your ATLAS mobile session?',
                style: TextStyle(fontSize: 14, color: IosNeuColors.textSecondary, height: 1.4),
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
                    text: 'Sign Out',
                    isPrimary: true,
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
            ],
          ),
        ),
      ),
    );
  }
}
