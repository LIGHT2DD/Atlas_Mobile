import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/api_config.dart';
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
  void initState() {
    super.initState();
    ref.read(secureStorageProvider).getServerUrl().then((savedUrl) {
      if (savedUrl != null && savedUrl.isNotEmpty) {
        ApiConfig.setCustomBaseUrl(savedUrl);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).login(
      email: _emailController.text.trim(),
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
    }
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
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 64, bottom: 40),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      // Monochromatic iOS Soft-UI Logo Card
                      Center(
                        child: IosNeuCard(
                          shape: BoxShape.circle,
                          padding: const EdgeInsets.all(12),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icon/play_store_512.png',
                              width: 72,
                              height: 72,
                              fit: BoxFit.contain,
                            ),
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

                      // Clean inline error banner without harsh concave shadow
                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: neuTheme.dangerColor.withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: neuTheme.dangerColor.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(TablerIcons.alert_circle, color: neuTheme.dangerColor, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: TextStyle(
                                    color: neuTheme.dangerColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => ref.read(authControllerProvider.notifier).clearError(),
                                child: Icon(
                                  TablerIcons.x,
                                  size: 16,
                                  color: neuTheme.dangerColor.withValues(alpha: 0.8),
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
                        autofillHints: const [AutofillHints.email],
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
                        autofillHints: const [AutofillHints.password],
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

                      // Primary iOS Neumorphic Charcoal Submit Button
                      IosNeuButton(
                        text: 'Sign In to ATLAS',
                        icon: TablerIcons.login,
                        isPrimary: true,
                        height: 52,
                        isLoading: authState.isLoading,
                        onPressed: authState.isLoading ? null : _handleLogin,
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
                      IosNeuCard(
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
                              spacing: 8,
                              runSpacing: 8,
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
          ),
              // Top action buttons (Server Settings & Theme Toggle) on top of Stack for hit-testing
              Positioned(
                top: 12,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeuIconButton(
                      icon: TablerIcons.server,
                      tooltip: 'Server Settings',
                      iconColor: neuTheme.textSecondary,
                      onPressed: () => _showServerConfigDialog(context, neuTheme),
                    ),
                    const SizedBox(width: 8),
                    NeuIconButton(
                      icon: isDark ? TablerIcons.sun : TablerIcons.moon,
                      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                      iconColor: isDark ? const Color(0xFFF6E05E) : neuTheme.accentColor,
                      onPressed: () {
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoButton(String label, IconData icon, String email, NeumorphicThemeData neuTheme) {
    return IosNeuButton(
      isPrimary: false,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      onPressed: () => _quickFill(email, 'Password123'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: neuTheme.textPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: neuTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog(BuildContext context, NeumorphicThemeData neuTheme) {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: neuTheme.baseColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(TablerIcons.server, color: neuTheme.accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Server Settings',
              style: TextStyle(color: neuTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backend API URL:',
              style: TextStyle(color: neuTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: TextStyle(color: neuTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: neuTheme.baseColor,
                hintText: 'http://192.168.0.105:8000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Quick Presets:', style: TextStyle(color: neuTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('192.168.0.105:8000', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://192.168.0.105:8000',
                ),
                ActionChip(
                  label: const Text('10.0.2.2:8000 (Emulator)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://10.0.2.2:8000',
                ),
                ActionChip(
                  label: const Text('localhost:8000', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://localhost:8000',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: neuTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: neuTheme.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ApiConfig.setCustomBaseUrl(newUrl);
                ref.read(secureStorageProvider).saveServerUrl(newUrl);
                NeuToast.show(context, message: 'Server URL set to $newUrl', type: NeuToastType.success);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
