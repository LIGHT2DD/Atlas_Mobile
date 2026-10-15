import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
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
      appBar: AppBar(
        title: const Text('Evaluation Rubrics'),
        actions: [
          IconButton(
            icon: const Icon(TablerIcons.rotate_clockwise),
            onPressed: () => ref.refresh(rubricsListProvider),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${r.weightPercentage.toInt()}% Weight',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
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
                            const Icon(TablerIcons.star, size: 16, color: AppColors.warning),
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
          ? FloatingActionButton.extended(
              icon: const Icon(TablerIcons.plus),
              label: const Text('Add Criterion'),
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
      builder: (ctx) => AlertDialog(
        title: const Text('New Rubric Criterion'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Criterion Title *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: scoreController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max Score'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Weight (%)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Save Criterion'),
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
    );
  }
}
