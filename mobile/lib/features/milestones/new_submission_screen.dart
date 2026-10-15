import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'milestone_repository.dart';

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
          message: 'File picker error: $e',
          type: NeuToastType.error,
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

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
        NeuToast.show(
          context,
          message: 'Milestone deliverable submitted successfully!',
          title: 'Submission Received',
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
    final neuTheme = context.neuTheme;

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: const NeuAppBar(title: 'Submit Deliverable'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NeuContainer(
                  depthType: NeuDepth.convex,
                  depth: 3.0,
                  borderRadius: BorderRadius.circular(18),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(TablerIcons.flag, color: neuTheme.accentColor, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.milestoneTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: neuTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload your project deliverable archive, report document, or provide a link to the version control repository.',
                        style: TextStyle(fontSize: 13, color: neuTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                NeuTextField(
                  controller: _titleController,
                  labelText: 'Deliverable Title *',
                  hintText: 'e.g. Sprint 2 Prototype & Test Results',
                  prefixIcon: Icon(TablerIcons.heading, color: neuTheme.textSecondary),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                NeuTextField(
                  controller: _descController,
                  labelText: 'Submission Description (Optional)',
                  hintText: 'Brief summary of what was accomplished in this milestone deliverable...',
                  maxLines: 4,
                ),
                const SizedBox(height: 18),

                NeuTextField(
                  controller: _codeUrlController,
                  labelText: 'Code Repository URL (Optional)',
                  hintText: 'https://github.com/organization/project',
                  keyboardType: TextInputType.url,
                  prefixIcon: Icon(TablerIcons.code, color: neuTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                Text(
                  'DELIVERABLE ARCHIVE / REPORT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: neuTheme.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                NeuDropzone(
                  selectedFileName: _selectedFileName,
                  subtitle: 'Select project archive or evaluation report (ZIP, PDF, DOCX)',
                  onPickFile: _pickFile,
                  onClearFile: () {
                    setState(() {
                      _selectedFileBytes = null;
                      _selectedFileName = null;
                    });
                  },
                ),
                const SizedBox(height: 32),

                NeuButton(
                  text: 'Confirm Submission',
                  icon: TablerIcons.cloud_upload,
                  isAccent: true,
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
