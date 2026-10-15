import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'milestone_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class CreateMilestoneScreen extends ConsumerStatefulWidget {
  const CreateMilestoneScreen({super.key});

  @override
  ConsumerState<CreateMilestoneScreen> createState() => _CreateMilestoneScreenState();
}

class _CreateMilestoneScreenState extends ConsumerState<CreateMilestoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _scoreController = TextEditingController(text: '100');
  final _weightController = TextEditingController(text: '20');
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _scoreController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
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
      final dueDateStr = _selectedDueDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDueDate!)
          : null;

      await repo.createMilestone(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        dueDate: dueDateStr,
        maxScore: double.tryParse(_scoreController.text.trim()) ?? 100.0,
        weightPercentage: double.tryParse(_weightController.text.trim()) ?? 0.0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Academic milestone defined successfully!'),
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
    final neuTheme = context.neuTheme;

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: const NeuAppBar(
        title: 'New Milestone Configuration',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Academic Deliverable Schedule',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: neuTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Define institutional deliverables, point weightages, and strict submission cutoff dates for the current semester.',
                style: TextStyle(fontSize: 14, color: neuTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                IosNeuCard(
                  isSunken: true,
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              NeuTextField(
                controller: _titleController,
                labelText: 'Milestone Title *',
                hintText: 'e.g. Midterm Progress & Architecture Evaluation',
                prefixIcon: Icon(TablerIcons.flag, color: neuTheme.textSecondary),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Milestone title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              NeuTextField(
                controller: _descController,
                maxLines: 4,
                labelText: 'Deliverable Requirements & Guidelines',
                hintText: 'Specify instructions, report format, and rubric considerations...',
              ),
              const SizedBox(height: 18),

              // Due Date Selector
              GestureDetector(
                onTap: _pickDate,
                child: IosNeuCard(
                  isSunken: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(TablerIcons.calendar_event, size: 20, color: neuTheme.textPrimary),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDueDate != null
                                ? 'Due Date: ${DateFormat('yyyy-MM-dd').format(_selectedDueDate!)}'
                                : 'Select Submission Deadline Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedDueDate != null ? FontWeight.w600 : FontWeight.w400,
                              color: _selectedDueDate != null
                                  ? neuTheme.textPrimary
                                  : neuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Icon(TablerIcons.chevron_down, color: neuTheme.textSecondary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: NeuTextField(
                      controller: _scoreController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      labelText: 'Max Score *',
                      prefixIcon: Icon(TablerIcons.numbers, color: neuTheme.textSecondary),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        if (double.tryParse(val.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: NeuTextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      labelText: 'Weight (%) *',
                      prefixIcon: Icon(TablerIcons.percentage, color: neuTheme.textSecondary),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        if (double.tryParse(val.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              IosNeuButton(
                text: 'Publish Milestone Schedule',
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
