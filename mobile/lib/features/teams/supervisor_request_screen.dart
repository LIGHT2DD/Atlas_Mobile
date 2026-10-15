import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/loading_indicator.dart';
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
    final supervisorsAsync = ref.watch(supervisorsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Faculty Supervisor'),
      ),
      body: supervisorsAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading available faculty...'),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Failed to load faculty: $err', style: const TextStyle(color: AppColors.error)),
          ),
        ),
        data: (supervisors) {
          if (supervisors.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No faculty supervisors are currently available for selection.'),
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
                  const Text(
                    'Supervision Proposal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a faculty member whose research interests align with your topic and provide a concise proposal message.',
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

                  DropdownButtonFormField<String>(
                    initialValue: _selectedSupervisorId,
                    decoration: const InputDecoration(
                      labelText: 'Select Faculty Member *',
                      prefixIcon: Icon(TablerIcons.school),
                    ),
                    items: supervisors.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text('${s.name} (${s.email})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedSupervisorId = val);
                    },
                    validator: (val) => val == null ? 'Please select a supervisor' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _msgController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Proposal / Request Message *',
                      hintText:
                          'Introduce your project concept, motivation, and why you are seeking guidance from this faculty member...',
                      alignLabelWithHint: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Request message is required';
                      }
                      return null;
                    },
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
                        : const Text('Send Supervision Request'),
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
