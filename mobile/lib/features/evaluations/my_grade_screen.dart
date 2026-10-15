import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/evaluation_model.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/status_badge.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'evaluation_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

final myGradeFutureProvider = FutureProvider.autoDispose<TeamGradeModel>((ref) async {
  final repo = ref.watch(evaluationRepositoryProvider);
  return repo.getMyGrade();
});

class MyGradeScreen extends ConsumerWidget {
  const MyGradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradeAsync = ref.watch(myGradeFutureProvider);

    return Scaffold(
      appBar: NeuAppBar(
        title: 'Official Academic Grades',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeuIconButton(
              icon: TablerIcons.rotate_clockwise,
              tooltip: 'Refresh Grades',
              onPressed: () => ref.refresh(myGradeFutureProvider),
            ),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: gradeAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading transcript records...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(myGradeFutureProvider),
        ),
        data: (grade) {
          if (!grade.hasGrade || !grade.published) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: TablerIcons.clock,
                  title: 'Grades Not Yet Published',
                  subtitle: grade.reason ??
                      'Final defense evaluations are pending coordinator publication and institutional approval.',
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myGradeFutureProvider),
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                // Academic Certificate / Transcript Card
                AtlasCard(
                  child: Column(
                    children: [
                      const Icon(TablerIcons.award, size: 56, color: IosNeuColors.activePill),
                      const SizedBox(height: 12),
                      const Text(
                        'OFFICIAL THESIS ASSESSMENT',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: IosNeuColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        grade.finalGrade ?? 'P',
                        style: const TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          color: IosNeuColors.textPrimary,
                        ),
                      ),
                      if (grade.finalScore != null) ...[
                        Text(
                          '${grade.finalScore!.toStringAsFixed(1)}% Aggregate Score',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: IosNeuColors.textPrimary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const StatusBadge(
                        status: 'approved',
                        customLabel: 'Published & Certified',
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Team:',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                          Text(
                            grade.teamName ?? 'N/A',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Project:',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                          Expanded(
                            child: Text(
                              grade.projectTitle ?? 'N/A',
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'This official grade reflects aggregated scores from your thesis supervisor, defense panel examiners, and deliverable milestones, finalized by the academic coordinator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
