import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:companion_app/features/auth/application/auth_provider.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.STAR_BACKGROUND,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Brand Area
              const Icon(LucideIcons.shieldCheck, size: 80, color: AppColors.STAR_PRIMARY),
              const SizedBox(height: 20),
              const Text(
                'POS COMPANION',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'Select your workspace',
                style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY),
              ),
              const SizedBox(height: 60),

              // Selection Buttons
              _buildSelectionCard(
                context,
                title: 'Manage Inventory',
                subtitle: 'Scan products & add stock',
                icon: LucideIcons.package,
                color: AppColors.STAR_PRIMARY,
                onTap: () {
                  context.read<AuthProvider>().setAppMode(AppMode.inventory);
                },
              ),
              const SizedBox(height: 20),
              _buildSelectionCard(
                context,
                title: 'Admin Dashboard',
                subtitle: 'Live sales & store analytics',
                icon: LucideIcons.layoutDashboard,
                color: AppColors.STAR_TEAL,
                onTap: () {
                  context.read<AuthProvider>().setAppMode(AppMode.admin);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.STAR_CARD,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.STAR_BORDER, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.STAR_TEXT_SECONDARY,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.STAR_TEXT_SECONDARY, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
