import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../coordinator/coordinator_repository.dart';

class CoordinatorDashboardScreen extends ConsumerWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neuTheme = context.neuTheme;
    final reportAsync = ref.watch(reportsSummaryProvider);

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: NeuAppBar(
        title: 'Coordinator Workspace',
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
          ref.invalidate(reportsSummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Extruded Banner
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
                            'Department Governance',
                            style: TextStyle(
                              color: neuTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Institutional oversight of active semesters, defenses, rubrics, and grade certifications.',
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
                      width: 52,
                      height: 52,
                      depthType: NeuDepth.convex,
                      depth: 3.0,
                      alignment: Alignment.center,
                      child: Icon(TablerIcons.shield_check, color: neuTheme.accentColor, size: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // KPI Grid Header
              Text(
                'LIFECYCLE OVERVIEW METRICS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: neuTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 14),

              reportAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => NeuContainer(
                  depthType: NeuDepth.concave,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $e', style: TextStyle(color: neuTheme.dangerColor)),
                ),
                data: (data) => GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    _kpiMiniCard(context, 'Teams', '${data.totalTeams}', TablerIcons.users),
                    _kpiMiniCard(context, 'Proposals', '${data.activeProposals}', TablerIcons.circle_check),
                    _kpiMiniCard(context, 'Defenses', '${data.completedDefenses}', TablerIcons.calendar_event),
                    _kpiMiniCard(context, 'Students', '${data.totalStudents}', TablerIcons.user),
                    _kpiMiniCard(context, 'Faculty', '${data.totalSupervisors}', TablerIcons.school),
                    _kpiMiniCard(context, 'Completed', '${data.completedDefenses}', TablerIcons.award),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Administration Management Actions
              Text(
                'ADMINISTRATIVE CAPABILITIES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: neuTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 14),

              _adminNavTile(
                context,
                title: 'All Thesis Teams',
                description: 'Manage rosters, assign or rebalance faculty supervisors',
                icon: TablerIcons.users,
                route: '/coordinator/teams',
              ),
              const SizedBox(height: 14),

              _adminNavTile(
                context,
                title: 'Academic Semesters',
                description: 'Activate academic terms, configure team size limits',
                icon: TablerIcons.calendar,
                route: '/coordinator/semesters',
              ),
              const SizedBox(height: 14),

              _adminNavTile(
                context,
                title: 'Defense Scheduling & Conflicts',
                description: 'Schedule oral defenses with automated collision prevention',
                icon: TablerIcons.clock,
                route: '/defenses',
              ),
              const SizedBox(height: 14),

              _adminNavTile(
                context,
                title: 'Rubrics & Grade Publishing',
                description: 'Configure weighted criteria and authoritatively publish transcripts',
                icon: TablerIcons.ruler,
                route: '/evaluations/rubrics',
              ),
              const SizedBox(height: 14),

              _adminNavTile(
                context,
                title: 'University Audit Logs',
                description: 'Chronological activity stream for accreditation compliance',
                icon: TablerIcons.shield_check,
                route: '/coordinator/audit-logs',
              ),
              const SizedBox(height: 14),

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

  Widget _kpiMiniCard(BuildContext context, String label, String value, IconData icon) {
    final neuTheme = context.neuTheme;

    return NeuContainer(
      depthType: NeuDepth.convex,
      depth: 3.0,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: neuTheme.accentColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: neuTheme.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: neuTheme.textSecondary,
                ),
              ),
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
    final neuTheme = context.neuTheme;

    return NeuContainer(
      depthType: NeuDepth.convex,
      depth: 3.5,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      onTap: () => context.push(route),
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
          Icon(TablerIcons.chevron_right, size: 20, color: neuTheme.textSecondary.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}
