import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
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
  String? _errorMessage;

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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selection error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Research proposal submitted successfully!'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Thesis Proposal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Proposal Submission',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Submit your official research synopsis for supervisor approval. If revising, specify what changes were incorporated.',
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

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Research Title *',
                  hintText: 'e.g. Adaptive Federated Learning Architecture',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _abstractController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Abstract & Methodology *',
                  hintText: 'Detail the problem statement, objectives, methodologies, and expected deliverables...',
                  alignLabelWithHint: true,
                ),
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
              const SizedBox(height: 16),

              TextFormField(
                controller: _changeSummaryController,
                decoration: const InputDecoration(
                  labelText: 'Revision Summary (Optional)',
                  hintText: 'e.g. Addressed supervisor comments on Section 3 methodology',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Document attachment box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.attach_file, size: 18, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(
                          'Document Attachment (PDF / DOCX)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_selectedFileName != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.insert_drive_file, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFileName!,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                            onPressed: () {
                              setState(() {
                                _selectedFileBytes = null;
                                _selectedFileName = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Select Proposal Document'),
                        onPressed: _pickDocument,
                      ),
                    ],
                  ],
                ),
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
                    : const Text('Submit Proposal for Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
