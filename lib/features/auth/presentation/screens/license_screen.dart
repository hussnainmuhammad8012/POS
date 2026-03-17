import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../application/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/toast_notification.dart';

class LicenseActivationScreen extends StatefulWidget {
  const LicenseActivationScreen({super.key});

  @override
  State<LicenseActivationScreen> createState() => _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends State<LicenseActivationScreen> {
  final TextEditingController _keyController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleActivation() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      AppToast.show(context, title: 'Required', message: 'Please enter your license key', type: ToastType.warning);
      return;
    }

    setState(() => _isLoading = true);
    
    final success = await context.read<AuthProvider>().activateLicense(key);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        AppToast.show(context, title: 'Success', message: 'Software activated successfully!', type: ToastType.success);
      } else {
        AppToast.show(
          context, 
          title: 'Activation Failed', 
          message: context.read<AuthProvider>().statusMessage, 
          type: ToastType.error
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.DARK_BACKGROUND : Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Branding
              Text(
                'RaiRoyalsCode',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.primaryColor,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 48),
              
              ModernCard(
                width: 450,
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.key,
                        size: 48,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Activate Software',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please enter your license key to unlock the system',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.DARK_TEXT_SECONDARY),
                    ),
                    const SizedBox(height: 32),
                    
                    CustomTextField(
                      controller: _keyController,
                      label: 'License Key',
                      hint: 'XXXX-XXXX-XXXX-XXXX',
                      prefixIcon: LucideIcons.shieldCheck,
                      autofocus: true,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleActivation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Verify & Activate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Text(
                      'Don\'t have a key? Contact your provider.',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.DARK_TEXT_TERTIARY),
                    ),
                    const Text(
                      'Support: 03258012402',
                      style: TextStyle(fontSize: 10, color: AppColors.DARK_TEXT_TERTIARY),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
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
