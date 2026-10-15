import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/evaluation_model.dart';
import '../../shared/widgets/atlas_card.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'evaluation_repository.dart';
import 'rubrics_screen.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class EvaluationScoringScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String? teamName;

  const EvaluationScoringScreen({
    super.key,
    required this.teamId,
    this.teamName,
  });

  @override
  ConsumerState<EvaluationScoringScreen> createState() => _EvaluationScoringScreenState();
}

class _EvaluationScoringScreenState extends ConsumerState<EvaluationScoringScreen> {
  final _commentsController = TextEditingController();
  final Map<String, TextEditingController> _scoreControllers = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentsController.dispose();
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(List<RubricCriteriaModel> rubrics) async {
    final List<Map<String, dynamic>> scoreEntries = [];

    for (final r in rubrics) {
      final ctrl = _scoreControllers[r.id];
      final val = ctrl != null ? double.tryParse(ctrl.text.trim()) : null;
      if (val == null || val < 0 || val > r.maxScore) {
        setState(() {
          _errorMessage = 'Please provide valid score for "${r.title}" (0 - ${r.maxScore.toInt()})';
        });
        return;
      }
      scoreEntries.add({
        'criteria_id': r.id,
        'score': val,
      });
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(evaluationRepositoryProvider);
      await repo.submitEvaluation(
        teamId: widget.teamId,
        overallComments: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
        scores: scoreEntries,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Defense evaluation successfully submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rubricsAsync = ref.watch(rubricsListProvider);

    return Scaffold(
      appBar: NeuAppBar(
        title: 'Evaluate: ${widget.teamName ?? "Team"}',
      ),
      body: rubricsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading assessment rubrics...'),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (rubrics) {
          if (rubrics.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No rubric criteria available to score.'),
              ),
            );
          }

          // Initialize controllers for rubrics
          for (final r in rubrics) {
            _scoreControllers.putIfAbsent(r.id, () => TextEditingController());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Formal Defense Scoring',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: IosNeuColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Score each candidate presentation criterion according to university academic standards.',
                  style: TextStyle(fontSize: 14, color: IosNeuColors.textSecondary),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  IosNeuCard(
                    isSunken: true,
                    padding: const EdgeInsets.all(14),
                    child: Text(_errorMessage!, style: const TextStyle(color: IosNeuColors.statusDanger, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 18),
                ],

                ...rubrics.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
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
                                    fontWeight: FontWeight.w700,
                                    color: IosNeuColors.textPrimary,
                                  ),
                                ),
                              ),
                              IosNeuCard(
                                isSunken: true,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  'Max: ${r.maxScore.toInt()} (${r.weightPercentage.toInt()}%)',
                                  style: const TextStyle(fontSize: 11, color: IosNeuColors.textPrimary, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          if (r.description != null) ...[
                            const SizedBox(height: 6),
                            Text(r.description!, style: const TextStyle(fontSize: 13, color: IosNeuColors.textSecondary)),
                          ],
                          const SizedBox(height: 14),
                          NeuTextField(
                            controller: _scoreControllers[r.id],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            labelText: 'Score Awarded (0 - ${r.maxScore.toInt()})',
                            prefixIcon: const Icon(TablerIcons.gauge, size: 20, color: IosNeuColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 8),
                NeuTextField(
                  controller: _commentsController,
                  maxLines: 4,
                  labelText: 'Examiner Overall Commentary (Optional)',
                  hintText: 'Summary of thesis defense performance, technical depth, and presentation clarity...',
                ),
                const SizedBox(height: 28),

                IosNeuButton(
                  text: 'Submit Official Evaluation',
                  isPrimary: true,
                  isLoading: _isLoading,
                  height: 52,
                  borderRadius: BorderRadius.circular(26),
                  onPressed: _isLoading ? null : () => _submit(rubrics),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
