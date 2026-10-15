import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      NeuToast.show(
        context,
        message: 'Please provide a valid institutional email address.',
        title: 'Validation Error',
        type: NeuToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final msg = await ref.read(authRepositoryProvider).forgotPassword(email);
      if (mounted) {
        setState(() => _isLoading = false);
        NeuToast.show(
          context,
          message: msg,
          title: 'Recovery Email Sent',
          type: NeuToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NeuToast.show(
          context,
          message: e.toString(),
          title: 'Password Recovery Failed',
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
      appBar: const NeuAppBar(title: 'Password Recovery'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: IosNeuCard(
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(22),
                  child: Icon(TablerIcons.lock_access, size: 36, color: neuTheme.accentColor),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Reset Your Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: neuTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the institutional email associated with your ATLAS account to receive a secure recovery token.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: neuTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 32),

              NeuTextField(
                controller: _emailController,
                labelText: 'Institutional Email',
                hintText: 'name@atlas.edu',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icon(TablerIcons.mail, size: 20, color: neuTheme.textSecondary),
              ),
              const SizedBox(height: 28),

              IosNeuButton(
                text: 'Send Recovery Instructions',
                icon: TablerIcons.send,
                isPrimary: true,
                height: 52,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
