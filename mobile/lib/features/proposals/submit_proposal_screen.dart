import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'proposal_repository.dart';

class SubmitProposalScreen extends ConsumerStatefulWidget {
  final String teamId;

  const SubmitProposalScreen({super.key, required this.teamId});

  @override
  ConsumerState<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends ConsumerState<SubmitProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _abstractController = TextEditingController();
  final _changeSummaryController = TextEditingController();
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _abstractController.dispose();
    _changeSummaryController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.single;
        setState(() {
          _selectedFileBytes = picked.bytes;
          _selectedFileName = picked.name;
        });
        if (mounted) {
          NeuToast.show(
            context,
            message: 'Attached: ${picked.name}',
            type: NeuToastType.info,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        NeuToast.show(
          context,
          message: 'File selection error: $e',
          type: NeuToastType.error,
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(proposalRepositoryProvider);
      await repo.submitProposal(
        teamId: widget.teamId,
        title: _titleController.text.trim(),
        abstractText: _abstractController.text.trim(),
        changeSummary: _changeSummaryController.text.trim().isEmpty
            ? null
            : _changeSummaryController.text.trim(),
        documentBytes: _selectedFileBytes,
        documentFileName: _selectedFileName,
      );

      if (mounted) {
        NeuToast.show(
          context,
          message: 'Research proposal submitted successfully for supervisor review!',
          title: 'Proposal Transmitted',
          type: NeuToastType.success,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NeuToast.show(
          context,
          message: e.toString(),
          title: 'Submission Error',
          type: NeuToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IosNeuColors.canvas,
      appBar: const NeuAppBar(title: 'Submit Thesis Proposal'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IosNeuCard(
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: IosNeuColors.activePill,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(TablerIcons.file_description, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Proposal Submission',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: IosNeuColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Submit your official research synopsis for supervisor approval. If revising, specify what changes were incorporated.',
                        style: TextStyle(fontSize: 13, color: IosNeuColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                NeuTextField(
                  controller: _titleController,
                  labelText: 'Research Title *',
                  hintText: 'e.g. Adaptive Federated Learning Architecture',
                  prefixIcon: const Icon(TablerIcons.heading, color: IosNeuColors.textSecondary),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                NeuTextField(
                  controller: _abstractController,
                  labelText: 'Abstract & Methodology *',
                  hintText: 'Detail the problem statement, objectives, methodologies, and expected deliverables...',
                  maxLines: 6,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Abstract is required';
                    }
                    if (val.trim().length < 20) {
                      return 'Please provide a comprehensive abstract (at least 20 chars)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                NeuTextField(
                  controller: _changeSummaryController,
                  labelText: 'Revision Summary (Optional)',
                  hintText: 'e.g. Addressed supervisor comments on Section 3 methodology',
                  prefixIcon: const Icon(TablerIcons.notes, color: IosNeuColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Recessed Dropzone Container
                const Text(
                  'DOCUMENT DELIVERABLE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: IosNeuColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                NeuDropzone(
                  selectedFileName: _selectedFileName,
                  subtitle: 'Select PDF or DOCX research synopsis (Max 25MB)',
                  onPickFile: _pickDocument,
                  onClearFile: () {
                    setState(() {
                      _selectedFileBytes = null;
                      _selectedFileName = null;
                    });
                  },
                ),
                const SizedBox(height: 32),

                IosNeuButton(
                  text: 'Submit Proposal for Review',
                  icon: TablerIcons.send,
                  isPrimary: true,
                  height: 52,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
