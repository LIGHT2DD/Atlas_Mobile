import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import '../../shared/models/evaluation_model.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/atlas_drawer.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../auth/auth_controller.dart';
import 'evaluation_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

final rubricsListProvider = FutureProvider.autoDispose<List<RubricCriteriaModel>>((ref) async {
  final repo = ref.watch(evaluationRepositoryProvider);
  return repo.getRubrics();
});

class RubricsScreen extends ConsumerWidget {
  const RubricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rubricsAsync = ref.watch(rubricsListProvider);
    final authState = ref.watch(authControllerProvider);
    final isCoordinator = authState.user?.role.isCoordinator ?? false;

    return Scaffold(
      appBar: NeuAppBar(
        title: 'Evaluation Rubrics',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NeuIconButton(
              icon: TablerIcons.rotate_clockwise,
              tooltip: 'Refresh Rubrics',
              onPressed: () => ref.refresh(rubricsListProvider),
            ),
          ),
        ],
      ),
      drawer: const AtlasDrawer(),
      body: rubricsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading rubric criteria...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(rubricsListProvider),
        ),
        data: (rubrics) {
          if (rubrics.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: TablerIcons.ruler,
                  title: 'No Rubrics Defined',
                  subtitle:
                      'Institutional assessment matrices and scoring weightages will be shown here once configured.',
                  actionLabel: isCoordinator ? 'Add Criterion' : null,
                  onAction: isCoordinator ? () => _showAddCriteriaDialog(context, ref) : null,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(rubricsListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: rubrics.length,
              itemBuilder: (context, index) {
                final r = rubrics[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: AtlasCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                r.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IosNeuCard(
                              isSunken: true,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              child: Text(
                                '${r.weightPercentage.toInt()}% Weight',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: IosNeuColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (r.description != null && r.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            r.description!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(TablerIcons.star, size: 16, color: IosNeuColors.activePill),
                            const SizedBox(width: 4),
                            Text(
                              'Max Score: ${r.maxScore.toInt()} pts',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: isCoordinator
          ? IosNeuFAB(
              tooltip: 'Add Rubric Criterion',
              onPressed: () => _showAddCriteriaDialog(context, ref),
            )
          : null,
    );
  }

  void _showAddCriteriaDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final scoreController = TextEditingController(text: '25');
    final weightController = TextEditingController(text: '25');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: IosNeuCard(
          isLarge: true,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'New Rubric Criterion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: IosNeuColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 18),
                NeuTextField(
                  controller: titleController,
                  labelText: 'Criterion Title *',
                  hintText: 'e.g. System Architecture & Methodology',
                ),
                const SizedBox(height: 12),
                NeuTextField(
                  controller: descController,
                  labelText: 'Description',
                  hintText: 'Evaluation standards and expectations',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: NeuTextField(
                        controller: scoreController,
                        keyboardType: TextInputType.number,
                        labelText: 'Max Score',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeuTextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        labelText: 'Weight (%)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IosNeuButton(
                      text: 'Cancel',
                      isPrimary: false,
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    const SizedBox(width: 10),
                    IosNeuButton(
                      text: 'Save Criterion',
                      isPrimary: true,
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        Navigator.of(ctx).pop();
                        try {
                          final repo = ref.read(evaluationRepositoryProvider);
                          await repo.createRubricCriteria(
                            title: titleController.text.trim(),
                            description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                            maxScore: double.tryParse(scoreController.text.trim()) ?? 25.0,
                            weightPercentage: double.tryParse(weightController.text.trim()) ?? 25.0,
                          );
                          ref.invalidate(rubricsListProvider);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
