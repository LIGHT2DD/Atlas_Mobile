import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic/neumorphic.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).login(
      email: _emailController.text,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (success && mounted) {
      NeuToast.show(
        context,
        message: 'Welcome back to ATLAS',
        title: 'Authentication Successful',
        type: NeuToastType.success,
      );
      context.go('/dashboard');
    } else if (mounted) {
      final err = ref.read(authControllerProvider).errorMessage ?? 'Login failed';
      NeuToast.show(
        context,
        message: err,
        title: 'Authentication Error',
        type: NeuToastType.error,
      );
    }
  }

  void _handleGoogleSignIn() {
    NeuToast.show(
      context,
      message: 'Redirecting to University Google OAuth Single Sign-On...',
      title: 'Google Sign-In',
      type: NeuToastType.info,
    );
  }

  void _quickFill(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
    NeuToast.show(
      context,
      message: 'Loaded credentials for $email',
      type: NeuToastType.info,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final neuTheme = context.neuTheme;
    final authState = ref.watch(authControllerProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = currentThemeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: neuTheme.baseColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Top theme toggle button
            Positioned(
              top: 12,
              right: 16,
              child: NeuIconButton(
                icon: isDark ? TablerIcons.sun : TablerIcons.moon,
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                iconColor: isDark ? const Color(0xFFF6E05E) : neuTheme.accentColor,
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Extruded Neumorphic Logo
                      Center(
                        child: NeuContainer(
                          shape: BoxShape.circle,
                          width: 80,
                          height: 80,
                          depthType: NeuDepth.convex,
                          depth: 4.5,
                          alignment: Alignment.center,
                          child: Icon(
                            TablerIcons.school,
                            color: neuTheme.accentColor,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'ATLAS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: neuTheme.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Academic Thesis Lifecycle & Assessment Suite',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: neuTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Error banner if any
                      if (authState.errorMessage != null) ...[
                        NeuContainer(
                          depthType: NeuDepth.concave,
                          borderRadius: BorderRadius.circular(14),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        const SizedBox(height: 20),
                      ],

                      // Email Recessed Input
                      NeuTextField(
                        controller: _emailController,
                        labelText: 'Institutional Email',
                        hintText: 'name@atlas.edu',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(TablerIcons.mail, size: 20, color: neuTheme.textSecondary),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter your email.';
                          if (!v.contains('@')) return 'Please enter a valid email.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Password Recessed Input
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
                          if (v == null || v.isEmpty) return 'Please enter your password.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Remember Me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              NeuCheckbox(
                                value: _rememberMe,
                                onChanged: (v) => setState(() => _rememberMe = v),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Remember me',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: neuTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push('/forgot-password'),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: neuTheme.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Primary Raised Submit Button
                      NeuButton(
                        text: 'Sign In to ATLAS',
                        icon: TablerIcons.login,
                        isAccent: true,
                        height: 52,
                        isLoading: authState.isLoading,
                        onPressed: authState.isLoading ? null : _handleLogin,
                      ),
                      const SizedBox(height: 16),

                      // Tactile Google OAuth Button
                      NeuButton(
                        text: 'Continue with Google',
                        icon: TablerIcons.brand_google,
                        height: 50,
                        depth: 3.5,
                        onPressed: authState.isLoading ? null : _handleGoogleSignIn,
                      ),
                      const SizedBox(height: 24),

                      // Candidate Registration link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "New candidate? ",
                            style: TextStyle(fontSize: 13, color: neuTheme.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: Text(
                              'Register Student Account',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: neuTheme.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // Tactile Quick Demo Roster Box
                      NeuContainer(
                        depthType: NeuDepth.convex,
                        depth: 2.5,
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(TablerIcons.sparkles, size: 16, color: neuTheme.accentColor),
                                const SizedBox(width: 8),
                                Text(
                                  'QUICK DEMO ROSTER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: neuTheme.textSecondary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _demoButton('Coordinator', TablerIcons.shield_check, 'coordinator@atlas.edu', neuTheme),
                                _demoButton('Supervisor', TablerIcons.school, 'supervisor1@atlas.edu', neuTheme),
                                _demoButton('Student', TablerIcons.user, 'student1@atlas.edu', neuTheme),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoButton(String label, IconData icon, String email, NeumorphicThemeData neuTheme) {
    return NeuButton(
      height: 36,
      depth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      onPressed: () => _quickFill(email, 'Password123'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: neuTheme.accentColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: neuTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
