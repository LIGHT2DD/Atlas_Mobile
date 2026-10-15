import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/atlas_card.dart';
import '../coordinator/coordinator_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class CoordinatorDashboardScreen extends ConsumerWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coordinator Administration'),
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
          ref.invalidate(reportsSummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Department Governance',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Institutional oversight of active semesters, defenses, rubrics, and grade certifications.',
                      style: TextStyle(color: AppColors.divider, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Grid
              const Text(
                'LIFECYCLE OVERVIEW METRICS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              reportAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (e, _) => AtlasCard(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
                data: (data) => GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: [
                    _kpiMiniCard('Teams', '${data.totalTeams}', TablerIcons.users),
                    _kpiMiniCard('Proposals', '${data.activeProposals}', TablerIcons.circle_check),
                    _kpiMiniCard('Defenses', '${data.completedDefenses}', TablerIcons.calendar_event),
                    _kpiMiniCard('Students', '${data.totalStudents}', TablerIcons.user),
                    _kpiMiniCard('Faculty', '${data.totalSupervisors}', TablerIcons.school),
                    _kpiMiniCard('Completed', '${data.completedDefenses}', TablerIcons.award),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Administration Management Actions
              const Text(
                'ADMINISTRATIVE CAPABILITIES',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              _adminNavTile(
                context,
                title: 'All Thesis Teams',
                description: 'Manage rosters, assign or rebalance faculty supervisors',
                icon: TablerIcons.users,
                route: '/coordinator/teams',
              ),
              const SizedBox(height: 10),

              _adminNavTile(
                context,
                title: 'Academic Semesters',
                description: 'Activate academic terms, configure team size limits',
                icon: TablerIcons.calendar,
                route: '/coordinator/semesters',
              ),
              const SizedBox(height: 10),

              _adminNavTile(
                context,
                title: 'Defense Scheduling & Conflicts',
                description: 'Schedule oral defenses with automated collision prevention',
                icon: TablerIcons.clock,
                route: '/defenses',
              ),
              const SizedBox(height: 10),

              _adminNavTile(
                context,
                title: 'Rubrics & Grade Publishing',
                description: 'Configure weighted criteria and authoritatively publish transcripts',
                icon: TablerIcons.ruler,
                route: '/evaluations/rubrics',
              ),
              const SizedBox(height: 10),

              _adminNavTile(
                context,
                title: 'University Audit Logs',
                description: 'Chronological activity stream for accreditation compliance',
                icon: TablerIcons.shield_check,
                route: '/coordinator/audit-logs',
              ),
              const SizedBox(height: 10),

              _adminNavTile(
                context,
                title: 'Academic Reports & Analytics',
                description: 'Departmental progression, exportable metrics, and grades',
                icon: TablerIcons.chart_bar,
                route: '/coordinator/reports',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiMiniCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminNavTile(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String route,
  }) {
    return AtlasCard(
      onTap: () => context.push(route),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(TablerIcons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
