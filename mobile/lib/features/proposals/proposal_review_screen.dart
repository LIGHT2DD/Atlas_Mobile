import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'proposal_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

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
      appBar: const NeuAppBar(
        title: 'Proposal Evaluation',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Supervisor Review Decision',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: IosNeuColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Evaluate the academic rigor, clarity, and viability of the submitted proposal. Provide constructive criticism or guidance.',
                style: TextStyle(fontSize: 14, color: IosNeuColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                IosNeuCard(
                  isSunken: true,
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: IosNeuColors.statusDanger, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Decision Selection with IosNeuSegmentPill
              const Text(
                'Formal Verdict *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: IosNeuColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: IosNeuSegmentPill(
                      label: 'Approve',
                      icon: TablerIcons.circle_check,
                      isSelected: _selectedDecision == 'approved',
                      onTap: () => setState(() => _selectedDecision = 'approved'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: IosNeuSegmentPill(
                      label: 'Revisions',
                      icon: TablerIcons.pencil,
                      isSelected: _selectedDecision == 'changes_requested',
                      onTap: () => setState(() => _selectedDecision = 'changes_requested'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: IosNeuSegmentPill(
                      label: 'Reject',
                      icon: TablerIcons.circle_x,
                      isSelected: _selectedDecision == 'rejected',
                      onTap: () => setState(() => _selectedDecision = 'rejected'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              NeuTextField(
                controller: _commentsController,
                maxLines: 6,
                labelText: 'Faculty Review Comments *',
                hintText: 'State required changes, literature references, or approval comments...',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Review comments are required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              IosNeuButton(
                text: 'Submit Formal Review',
                isPrimary: true,
                isLoading: _isLoading,
                height: 52,
                borderRadius: BorderRadius.circular(26),
                onPressed: _isLoading ? null : _submit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
