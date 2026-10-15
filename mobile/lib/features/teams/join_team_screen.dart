import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'team_repository.dart';

class JoinTeamScreen extends ConsumerStatefulWidget {
  const JoinTeamScreen({super.key});

  @override
  ConsumerState<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends ConsumerState<JoinTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(teamRepositoryProvider);
      final team = await repo.joinTeam(_codeController.text.trim());

      if (mounted) {
        NeuToast.show(
          context,
          message: 'Successfully joined "${team.name}"!',
          title: 'Welcome to the Team',
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
          title: 'Join Team Error',
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
      appBar: const NeuAppBar(title: 'Join Thesis Team'),
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
                          Icon(TablerIcons.link, color: neuTheme.accentColor, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Enter Invitation Code',
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
                        'Enter the 6-character invitation code provided by your team leader to join their registered thesis group.',
                        style: TextStyle(fontSize: 13, color: neuTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                NeuTextField(
                  controller: _codeController,
                  labelText: 'Invitation Code',
                  hintText: 'e.g. ABC123',
                  prefixIcon: Icon(TablerIcons.key, color: neuTheme.textSecondary),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the invite code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                NeuButton(
                  text: 'Join Team',
                  icon: TablerIcons.user_check,
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
