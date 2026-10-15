import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'milestone_repository.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Deliverable'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Submission: ${widget.submissionTitle}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Maximum points available: ${widget.maxScore.toInt()} pts',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _scoreController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Points Awarded (0 - ${widget.maxScore.toInt()}) *',
                  hintText: 'e.g. 88.5',
                  prefixIcon: const Icon(Icons.grade_outlined),
                ),
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
              const SizedBox(height: 16),

              TextFormField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Evaluator Feedback & Critique *',
                  hintText: 'Detail strengths, areas for technical improvement, or compliance remarks...',
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Feedback is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Record Deliverable Grade'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
