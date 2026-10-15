import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'milestone_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class GradeSubmissionScreen extends ConsumerStatefulWidget {
  final String submissionId;
  final String submissionTitle;
  final double maxScore;

  const GradeSubmissionScreen({
    super.key,
    required this.submissionId,
    required this.submissionTitle,
    required this.maxScore,
  });

  @override
  ConsumerState<GradeSubmissionScreen> createState() => _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState extends ConsumerState<GradeSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scoreController = TextEditingController();
  final _feedbackController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final score = double.tryParse(_scoreController.text.trim());
    if (score == null || score < 0 || score > widget.maxScore) {
      setState(() => _errorMessage = 'Score must be between 0 and ${widget.maxScore}');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(milestoneRepositoryProvider);
      final msg = await repo.gradeSubmission(
        submissionId: widget.submissionId,
        score: score,
        feedback: _feedbackController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
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
    final neuTheme = context.neuTheme;

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: const NeuAppBar(
        title: 'Grade Deliverable',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IosNeuCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.submissionTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: neuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Maximum points available: ${widget.maxScore.toInt()} pts',
                      style: TextStyle(fontSize: 13, color: neuTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                IosNeuCard(
                  isSunken: true,
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: neuTheme.dangerColor, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              NeuTextField(
                controller: _scoreController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                labelText: 'Points Awarded (0 - ${widget.maxScore.toInt()}) *',
                hintText: 'e.g. 88.5',
                prefixIcon: Icon(TablerIcons.award, color: neuTheme.textSecondary),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Score is required';
                  }
                  final n = double.tryParse(val.trim());
                  if (n == null) return 'Must be a valid number';
                  if (n < 0 || n > widget.maxScore) {
                    return 'Score must be between 0 and ${widget.maxScore}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              NeuTextField(
                controller: _feedbackController,
                maxLines: 5,
                labelText: 'Evaluator Feedback & Critique *',
                hintText: 'Detail strengths, areas for technical improvement, or compliance remarks...',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Feedback is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              IosNeuButton(
                text: 'Record Deliverable Grade',
                isLoading: _isLoading,
                isPrimary: true,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
