import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/toast_notification.dart';
import '../../application/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      AppToast.show(
        context,
        title: 'Input Required',
        message: 'Please enter both username and password.',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await context.read<AuthProvider>().login(
      _usernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        AppToast.show(
          context,
          title: 'Login Failed',
          message: 'Invalid username or password.',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.DARK_BACKGROUND : AppColors.LIGHT_SURFACE,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Developer Branding
              Text(
                'RaiRoyalsCode',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor.withOpacity(0.7),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              
              // Project Identity
              ModernCard(
                width: 450,
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.shieldCheck,
                        size: 48,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Secure Access',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please enter your credentials to continue',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.DARK_TEXT_SECONDARY : AppColors.LIGHT_TEXT_SECONDARY,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      controller: _usernameController,
                      prefixIcon: LucideIcons.user,
                      label: 'Username',
                      hint: 'Enter your username',
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      prefixIcon: LucideIcons.lock,
                      label: 'Password',
                      hint: 'Enter your password',
                      obscureText: _obscurePassword,
                      suffixIcon: _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                      onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Text(
                                'Login to System',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Footer
              Text(
                '© 2026 RaiRoyalsCode. All Rights Reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.DARK_TEXT_TERTIARY : AppColors.LIGHT_TEXT_TERTIARY,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
