import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).register(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      NeuToast.show(
        context,
        message: 'Your ATLAS student account is ready.',
        title: 'Registration Complete',
        type: NeuToastType.success,
      );
      context.go('/dashboard');
    } else if (mounted) {
      final err = ref.read(authControllerProvider).errorMessage ?? 'Registration failed';
      NeuToast.show(
        context,
        message: err,
        title: 'Registration Error',
        type: NeuToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      appBar: const NeuAppBar(title: 'Student Registration'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                          Icon(TablerIcons.user_plus, color: neuTheme.accentColor, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Candidate Account Setup',
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
                        'Register your institutional profile to join or form thesis teams and submit research milestones.',
                        style: TextStyle(fontSize: 13, color: neuTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (authState.errorMessage != null) ...[
                  NeuContainer(
                    depthType: NeuDepth.concave,
                    borderRadius: BorderRadius.circular(14),
                    padding: const EdgeInsets.all(14),
                    border: Border.all(color: neuTheme.dangerColor.withValues(alpha: 0.5), width: 1.2),
                    child: Row(
                      children: [
                        Icon(TablerIcons.alert_circle, color: neuTheme.dangerColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: TextStyle(color: neuTheme.dangerColor, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                Row(
                  children: [
                    Expanded(
                      child: NeuTextField(
                        controller: _firstNameController,
                        labelText: 'First Name',
                        hintText: 'John',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: NeuTextField(
                        controller: _lastNameController,
                        labelText: 'Last Name',
                        hintText: 'Doe',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                NeuTextField(
                  controller: _emailController,
                  labelText: 'University Email',
                  hintText: 'student@atlas.edu',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(TablerIcons.mail, size: 20, color: neuTheme.textSecondary),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email.';
                    if (!v.contains('@')) return 'Please enter a valid email.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                NeuTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: '••••••••••••',
                  obscureText: _obscurePassword,
                  prefixIcon: Icon(TablerIcons.lock, size: 20, color: neuTheme.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? TablerIcons.eye_off : TablerIcons.eye,
                      size: 20,
                      color: neuTheme.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 8) return 'Password must be at least 8 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                NeuTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: '••••••••••••',
                  obscureText: _obscurePassword,
                  prefixIcon: Icon(TablerIcons.lock_access, size: 20, color: neuTheme.textSecondary),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match.';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                NeuButton(
                  text: 'Complete Registration',
                  icon: TablerIcons.check,
                  isAccent: true,
                  height: 52,
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _handleRegister,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
