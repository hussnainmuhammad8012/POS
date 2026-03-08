import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    final success = await context.read<AuthProvider>().login(
      _usernameController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Credentials'), backgroundColor: AppColors.DANGER),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.STAR_BACKGROUND,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.STAR_PRIMARY.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.store, color: AppColors.STAR_PRIMARY, size: 32),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Sign in to manage your inventory',
                style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY),
              ),
              const SizedBox(height: 40),
              CustomTextField(
                label: 'Username',
                hint: 'Enter your admin username',
                prefixIcon: LucideIcons.user,
                controller: _usernameController,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Password',
                hint: '••••••••',
                prefixIcon: LucideIcons.lock,
                obscureText: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Login to POS System', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => context.read<AuthProvider>().unpair(),
                  child: const Text('Unpair this device', style: TextStyle(color: AppColors.DANGER)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
