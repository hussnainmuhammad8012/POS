import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/modern_card.dart';

class BlockScreen extends StatelessWidget {
  final String title;
  final String message;
  final String contactInfo;

  const BlockScreen({
    super.key,
    required this.title,
    required this.message,
    required this.contactInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.DARK_BACKGROUND : AppColors.LIGHT_SURFACE,
      body: Center(
        child: ModernCard(
          width: 500,
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.shieldAlert,
                  size: 64,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.DARK_TEXT_SECONDARY : AppColors.LIGHT_TEXT_SECONDARY,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.DARK_BACKGROUND : AppColors.LIGHT_SURFACE,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.DARK_BORDER_SUBTLE : AppColors.LIGHT_BORDER_SUBTLE,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PLEASE CONTACT OWNER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      contactInfo,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'RaiRoyalsCode Security System',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
