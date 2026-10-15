import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/status_badge.dart';
import 'coordinator_repository.dart';

final reportSummaryFutureProvider = FutureProvider.autoDispose<ReportSummaryModel>((ref) async {
  final repo = ref.watch(coordinatorRepositoryProvider);
  return repo.getReportSummary();
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportSummaryFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departmental Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(reportSummaryFutureProvider),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: reportAsync.when(
        loading: () => const LoadingIndicator(message: 'Compiling academic metrics...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(reportSummaryFutureProvider),
        ),
        data: (report) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(reportSummaryFutureProvider),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Academic Cohort Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Real-time synthesis of student engagement, faculty assignments, and thesis defense progress.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Metrics Grid
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        title: 'Total Students',
                        value: report.totalStudents.toString(),
                        icon: Icons.person_outline,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricCard(
                        title: 'Supervisors',
                        value: report.totalSupervisors.toString(),
                        icon: Icons.school_outlined,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        title: 'Thesis Teams',
                        value: report.totalTeams.toString(),
                        icon: Icons.groups_3_outlined,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricCard(
                        title: 'Active Proposals',
                        value: report.activeProposals.toString(),
                        icon: Icons.description_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _metricCard(
                  title: 'Oral Defenses Concluded',
                  value: report.completedDefenses.toString(),
                  icon: Icons.workspace_premium_outlined,
                  color: AppColors.success,
                ),
                const SizedBox(height: 20),

                // Status Breakdown
                AtlasCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Team Lifecycle Status Distribution',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (report.teamsByStatus.isEmpty) ...[
                        const Text('No status distribution records available.', style: TextStyle(fontSize: 13)),
                      ] else ...[
                        ...report.teamsByStatus.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StatusBadge(status: entry.key),
                                Text(
                                  '${entry.value} team(s)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AtlasCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
