import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/status_badge.dart';
import '../auth/auth_controller.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      drawer: const AtlasDrawer(),
      body: user == null
          ? const Center(child: Text('No active session'))
          : ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                // Profile Header Card
                AtlasCard(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      StatusBadge(
                        status: user.role.name,
                        customLabel: user.role.displayName,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Account Information
                AtlasCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoRow(label: 'Account Status', value: user.isActive ? 'Active' : 'Inactive'),
                      const Divider(height: 16),
                      _infoRow(label: 'User ID', value: user.id),
                      if (user.department != null && user.department!.isNotEmpty) ...[
                        const Divider(height: 16),
                        _infoRow(label: 'Department', value: user.department!),
                      ],
                      if (user.studentId != null && user.studentId!.isNotEmpty) ...[
                        const Divider(height: 16),
                        _infoRow(label: 'Student Registration ID', value: user.studentId!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Security & Settings Card
                AtlasCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security & Preferences',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(TablerIcons.lock_access, color: AppColors.accent),
                        title: const Text('Password Recovery'),
                        subtitle: const Text('Dispatch a password reset link to your email'),
                        trailing: const Icon(TablerIcons.chevron_right, size: 14),
                        onTap: () {
                          context.push('/forgot-password');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sign Out Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  icon: const Icon(TablerIcons.logout),
                  label: const Text('Sign Out of ATLAS'),
                  onPressed: () => _confirmSignOut(context, ref),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _infoRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to end your ATLAS mobile session?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
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
