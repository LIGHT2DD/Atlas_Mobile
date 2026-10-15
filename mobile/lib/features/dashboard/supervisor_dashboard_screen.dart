import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/atlas_card.dart';
import '../auth/auth_controller.dart';
import '../supervisor/supervisor_repository.dart';

class SupervisorDashboardScreen extends ConsumerWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final requestsAsync = ref.watch(supervisorRequestsProvider);
    final teamsAsync = ref.watch(supervisedTeamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(supervisorRequestsProvider);
          ref.invalidate(supervisedTeamsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Prof. ${user?.lastName ?? user?.firstName ?? 'Faculty'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Manage candidate supervision, milestone grading, and defense committee evaluations.',
                      style: TextStyle(color: AppColors.divider, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Counters
              Row(
                children: [
                  Expanded(
                    child: AtlasCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SUPERVISED TEAMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          teamsAsync.when(
                            loading: () => const Text('...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            error: (err, stack) => const Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            data: (teams) => Text('${teams.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AtlasCard(
                      onTap: () => context.push('/supervisor/requests'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PENDING REQUESTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          requestsAsync.when(
                            loading: () => const Text('...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            error: (err, stack) => const Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            data: (reqs) => Text(
                              '${reqs.length}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: reqs.isNotEmpty ? AppColors.warning : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Navigation
              const Text(
                'SUPERVISION TASKS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              _taskCard(
                context,
                title: 'Supervision Requests Inbox',
                description: 'Review student team mentorship invitations',
                icon: Icons.mark_email_unread_outlined,
                badgeCount: requestsAsync.valueOrNull?.length,
                onTap: () => context.push('/supervisor/requests'),
              ),
              const SizedBox(height: 10),

              _taskCard(
                context,
                title: 'Assigned Teams Roster',
                description: 'Review proposals, monitor deliverable milestones',
                icon: Icons.groups_outlined,
                badgeCount: teamsAsync.valueOrNull?.length,
                onTap: () => context.push('/supervisor/teams'),
              ),
              const SizedBox(height: 10),

              _taskCard(
                context,
                title: 'Deliverables & Submissions',
                description: 'Inspect code repositories and submit grades',
                icon: Icons.assignment_outlined,
                onTap: () => context.push('/milestones'),
              ),
              const SizedBox(height: 10),

              _taskCard(
                context,
                title: 'Defense Hearings & Rubrics',
                description: 'Examine candidates and enter multi-criteria scores',
                icon: Icons.gavel_outlined,
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
    return AtlasCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (badgeCount != null && badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
