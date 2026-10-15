import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'milestone_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class NewSubmissionScreen extends ConsumerStatefulWidget {
  final String milestoneId;
  final String teamId;
  final String milestoneTitle;

  const NewSubmissionScreen({
    super.key,
    required this.milestoneId,
    required this.teamId,
    required this.milestoneTitle,
  });

  @override
  ConsumerState<NewSubmissionScreen> createState() => _NewSubmissionScreenState();
}

class _NewSubmissionScreenState extends ConsumerState<NewSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _codeUrlController = TextEditingController();
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _codeUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'zip', 'tar', 'gz', 'docx'],
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
          SnackBar(content: Text('File picker error: $e'), backgroundColor: AppColors.error),
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
      final repo = ref.read(milestoneRepositoryProvider);
      await repo.createSubmission(
        milestoneId: widget.milestoneId,
        teamId: widget.teamId,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        codeUrl: _codeUrlController.text.trim().isEmpty ? null : _codeUrlController.text.trim(),
        deliverableBytes: _selectedFileBytes,
        deliverableFileName: _selectedFileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deliverable submitted successfully!'),
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
        title: const Text('Submit Deliverable'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Milestone: ${widget.milestoneTitle}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Upload your project deliverable archive, report document, or provide a link to the version control repository.',
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
                  labelText: 'Deliverable Title *',
                  hintText: 'e.g. Sprint 2 Prototype & Test Results',
                  prefixIcon: Icon(TablerIcons.heading),
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
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Submission Description (Optional)',
                  hintText: 'Brief summary of what was accomplished in this milestone deliverable...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _codeUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Code Repository URL (Optional)',
                  hintText: 'https://github.com/organization/project',
                  prefixIcon: Icon(TablerIcons.code),
                ),
              ),
              const SizedBox(height: 20),

              // Attachment Card
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
                        Icon(TablerIcons.paperclip, size: 18, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(
                          'Deliverable Archive / Report (ZIP, PDF)',
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
                          const Icon(TablerIcons.file_zip, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFileName!,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(TablerIcons.x, size: 18, color: AppColors.error),
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
                        icon: const Icon(TablerIcons.upload),
                        label: const Text('Attach Deliverable File'),
                        onPressed: _pickFile,
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
                    : const Text('Confirm Submission'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
