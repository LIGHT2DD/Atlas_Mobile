import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'proposal_repository.dart';

class ProposalReviewScreen extends ConsumerStatefulWidget {
  final String proposalId;

  const ProposalReviewScreen({super.key, required this.proposalId});

  @override
  ConsumerState<ProposalReviewScreen> createState() => _ProposalReviewScreenState();
}

class _ProposalReviewScreenState extends ConsumerState<ProposalReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  String _selectedDecision = 'approved';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(proposalRepositoryProvider);
      final msg = await repo.reviewProposal(
        proposalId: widget.proposalId,
        decision: _selectedDecision,
        comments: _commentsController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: _selectedDecision == 'approved'
                ? AppColors.success
                : AppColors.info,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposal Evaluation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Supervisor Review Decision',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Evaluate the academic rigor, clarity, and viability of the submitted proposal. Provide constructive criticism or guidance.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
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

              // Decision Selection
              const Text(
                'Formal Verdict *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'approved',
                    label: Text('Approve'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: 'changes_requested',
                    label: Text('Revisions'),
                    icon: Icon(Icons.edit_outlined),
                  ),
                  ButtonSegment(
                    value: 'rejected',
                    label: Text('Reject'),
                    icon: Icon(Icons.cancel_outlined),
                  ),
                ],
                selected: {_selectedDecision},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedDecision = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _commentsController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Faculty Review Comments *',
                  hintText: 'State required changes, literature references, or approval comments...',
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Review comments are required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedDecision == 'approved'
                      ? AppColors.success
                      : (_selectedDecision == 'rejected' ? AppColors.error : AppColors.primary),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Formal Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
