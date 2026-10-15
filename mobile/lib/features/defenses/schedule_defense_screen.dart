import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../teams/team_repository.dart';
import 'defense_repository.dart';

class ScheduleDefenseScreen extends ConsumerStatefulWidget {
  const ScheduleDefenseScreen({super.key});

  @override
  ConsumerState<ScheduleDefenseScreen> createState() => _ScheduleDefenseScreenState();
}

class _ScheduleDefenseScreenState extends ConsumerState<ScheduleDefenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();
  final _startTimeController = TextEditingController(text: '10:00');
  final _endTimeController = TextEditingController(text: '11:00');
  final _notesController = TextEditingController();
  final _teamIdController = TextEditingController();

  DateTime? _selectedDate;
  final List<String> _selectedPanelMemberIds = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _roomController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _notesController.dispose();
    _teamIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      setState(() => _errorMessage = 'Please pick a date for the defense');
      return;
    }
    if (_selectedPanelMemberIds.isEmpty) {
      setState(() => _errorMessage = 'Select at least one faculty panel examiner');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(defenseRepositoryProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final msg = await repo.scheduleDefense(
        teamId: _teamIdController.text.trim(),
        date: dateStr,
        startTime: _startTimeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        room: _roomController.text.trim(),
        panelMemberIds: _selectedPanelMemberIds,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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
    final facultyAsync = ref.watch(supervisorsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Defense Hearing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Defense Session Booking',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Book an oral defense venue, timeslot, and assign the faculty examination panel. The scheduling conflict engine automatically detects room and examiner clashes.',
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
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _teamIdController,
                decoration: const InputDecoration(
                  labelText: 'Team ID or Name *',
                  hintText: 'Enter candidate Team ID',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Team ID is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: AppColors.accent),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate != null
                                ? 'Hearing Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'
                                : 'Select Hearing Date *',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Start Time *',
                        hintText: '10:00',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: const InputDecoration(
                        labelText: 'End Time *',
                        hintText: '11:00',
                        prefixIcon: Icon(Icons.access_time_filled),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room / Venue *',
                  hintText: 'e.g. Auditorium Hall 204 or Lab 3',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Room is required';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Panel Selection
              const Text(
                'Assign Examination Panel *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              facultyAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load faculty: $e'),
                data: (supervisors) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: supervisors.map((s) {
                        final isSelected = _selectedPanelMemberIds.contains(s.id);
                        return CheckboxListTile(
                          title: Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(s.email, style: const TextStyle(fontSize: 12)),
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedPanelMemberIds.add(s.id);
                              } else {
                                _selectedPanelMemberIds.remove(s.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Session Notes (Optional)',
                  hintText: 'Equipment requirements, defense format, or instructions for the panel...',
                  alignLabelWithHint: true,
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
                    : const Text('Confirm Defense Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
