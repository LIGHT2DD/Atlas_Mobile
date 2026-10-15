import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'team_repository.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class SupervisorRequestScreen extends ConsumerStatefulWidget {
  final String teamId;

  const SupervisorRequestScreen({super.key, required this.teamId});

  @override
  ConsumerState<SupervisorRequestScreen> createState() => _SupervisorRequestScreenState();
}

class _SupervisorRequestScreenState extends ConsumerState<SupervisorRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _msgController = TextEditingController();
  String? _selectedSupervisorId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupervisorId == null) {
      setState(() => _errorMessage = 'Please select a faculty supervisor.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(teamRepositoryProvider);
      final msg = await repo.requestSupervisor(
        teamId: widget.teamId,
        supervisorId: _selectedSupervisorId!,
        message: _msgController.text.trim(),
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
    final supervisorsAsync = ref.watch(supervisorsFutureProvider);

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: const NeuAppBar(
        title: 'Request Faculty Supervisor',
      ),
      body: supervisorsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading available faculty...'),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Failed to load faculty: $err', style: TextStyle(color: neuTheme.dangerColor)),
          ),
        ),
        data: (supervisors) {
          if (supervisors.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: EmptyState(
                  icon: TablerIcons.school,
                  title: 'No Faculty Available',
                  subtitle: 'No faculty supervisors are currently available for selection.',
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Supervision Proposal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: neuTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a faculty member whose research interests align with your topic and provide a concise proposal message.',
                    style: TextStyle(fontSize: 14, color: neuTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    IosNeuCard(
                      isSunken: true,
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: neuTheme.dangerColor, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  IosNeuCard(
                    isSunken: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSupervisorId,
                        isExpanded: true,
                        dropdownColor: neuTheme.baseColor,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          prefixIcon: Icon(TablerIcons.school, color: neuTheme.textSecondary, size: 20),
                          hintText: 'Select Faculty Member *',
                          hintStyle: TextStyle(color: neuTheme.textSecondary, fontSize: 14),
                        ),
                        items: supervisors.map((s) {
                          return DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(
                              '${s.name} (${s.email})',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, color: neuTheme.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedSupervisorId = val);
                        },
                        validator: (val) => val == null ? 'Please select a supervisor' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  NeuTextField(
                    controller: _msgController,
                    maxLines: 5,
                    labelText: 'Proposal / Request Message *',
                    hintText:
                        'Introduce your project concept, motivation, and why you are seeking guidance from this faculty member...',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Request message is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  IosNeuButton(
                    text: 'Send Supervision Request',
                    isLoading: _isLoading,
                    isPrimary: true,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
