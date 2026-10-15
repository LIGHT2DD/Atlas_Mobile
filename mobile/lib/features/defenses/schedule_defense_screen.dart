import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import '../teams/team_repository.dart';
import 'defense_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

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
    final neuTheme = context.neuTheme;
    final facultyAsync = ref.watch(supervisorsFutureProvider);

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: const NeuAppBar(
        title: 'Schedule Defense Hearing',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Defense Session Booking',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: neuTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Book an oral defense venue, timeslot, and assign the faculty examination panel. The scheduling conflict engine automatically detects room and examiner clashes.',
                style: TextStyle(fontSize: 14, color: neuTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                IosNeuCard(
                  isSunken: true,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(TablerIcons.alert_triangle, color: AppColors.error, size: 20),
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

              NeuTextField(
                controller: _teamIdController,
                labelText: 'Team ID or Name *',
                hintText: 'Enter candidate Team ID',
                prefixIcon: Icon(TablerIcons.users, color: neuTheme.textSecondary),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Team ID is required';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Date Picker
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
                            _selectedDate != null
                                ? 'Hearing Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'
                                : 'Select Hearing Date *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.w400,
                              color: _selectedDate != null
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
                      controller: _startTimeController,
                      labelText: 'Start Time *',
                      hintText: '10:00',
                      prefixIcon: Icon(TablerIcons.clock, color: neuTheme.textSecondary),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: NeuTextField(
                      controller: _endTimeController,
                      labelText: 'End Time *',
                      hintText: '11:00',
                      prefixIcon: Icon(TablerIcons.clock, color: neuTheme.textSecondary),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              NeuTextField(
                controller: _roomController,
                labelText: 'Room / Venue *',
                hintText: 'e.g. Auditorium Hall 204 or Lab 3',
                prefixIcon: Icon(TablerIcons.door_enter, color: neuTheme.textSecondary),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Room is required';
                  return null;
                },
              ),
              const SizedBox(height: 22),

              // Panel Selection
              Text(
                'Assign Examination Panel *',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: neuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              facultyAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load faculty: $e'),
                data: (supervisors) {
                  return IosNeuCard(
                    isSunken: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: supervisors.map((s) {
                        final isSelected = _selectedPanelMemberIds.contains(s.id);
                        return CheckboxListTile(
                          activeColor: IosNeuColors.activePill,
                          checkColor: Colors.white,
                          title: Text(
                            s.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: neuTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            s.email,
                            style: TextStyle(fontSize: 12, color: neuTheme.textSecondary),
                          ),
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
              const SizedBox(height: 18),

              NeuTextField(
                controller: _notesController,
                maxLines: 3,
                labelText: 'Session Notes (Optional)',
                hintText: 'Equipment requirements, defense format, or instructions for the panel...',
              ),
              const SizedBox(height: 32),

              IosNeuButton(
                text: 'Confirm Defense Schedule',
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
