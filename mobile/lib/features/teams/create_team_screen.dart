import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'team_repository.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(teamRepositoryProvider);
      await repo.createTeam(
        name: _nameController.text.trim(),
        projectTitle: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      );

      if (mounted) {
        NeuToast.show(
          context,
          message: 'Thesis team created successfully! Share your invite code.',
          title: 'Team Established',
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
          title: 'Team Creation Failed',
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
      appBar: const NeuAppBar(title: 'Create Thesis Team'),
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
                          Icon(TablerIcons.circles_relation, color: neuTheme.accentColor, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'New Team Registration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: neuTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'As the founder of this team, you will be registered as the Team Leader. You can share your unique invite code with peers once created.',
                        style: TextStyle(fontSize: 13, color: neuTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                NeuTextField(
                  controller: _nameController,
                  labelText: 'Team Name *',
                  hintText: 'e.g. Quantum Innovators',
                  prefixIcon: Icon(TablerIcons.circles_relation, color: neuTheme.textSecondary),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Team name is required';
                    }
                    if (val.trim().length < 3) {
                      return 'Team name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                NeuTextField(
                  controller: _titleController,
                  labelText: 'Thesis / Project Title *',
                  hintText: 'e.g. Distributed Consensus in Edge Networks',
                  prefixIcon: Icon(TablerIcons.book, color: neuTheme.textSecondary),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Project title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                NeuTextField(
                  controller: _descController,
                  labelText: 'Project Summary / Scope (Optional)',
                  hintText: 'Provide a brief outline of the research domain and goals...',
                  maxLines: 4,
                ),
                const SizedBox(height: 32),

                NeuButton(
                  text: 'Establish Team',
                  icon: TablerIcons.plus,
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
