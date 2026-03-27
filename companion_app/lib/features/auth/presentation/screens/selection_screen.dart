import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:companion_app/features/auth/application/auth_provider.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.STAR_BACKGROUND,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Brand Area
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Column(
                    children: [
                      if (auth.storeLogo != null)
                        _buildLogoWidget(auth.storeLogo!)
                      else ...[
                        const Icon(LucideIcons.shieldCheck, size: 80, color: AppColors.STAR_PRIMARY),
                        const SizedBox(height: 20),
                        const Text(
                          'POS COMPANION',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Select your workspace',
                          style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY),
                        ),
                      ],
                      if (auth.storeLogo != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          auth.shopName ?? 'Gravity POS',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Companion App',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 60),

              // Selection Buttons
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Column(
                    children: [
                      if (!auth.isLoggedIn || auth.canAccessInventory)
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
                      if (!auth.isLoggedIn || auth.canAccessInventory) const SizedBox(height: 20),
                      if (!auth.isLoggedIn || auth.canAccessAnalytics)
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
                      if (!auth.isLoggedIn || auth.canAccessPos) const SizedBox(height: 20),
                      if (!auth.isLoggedIn || auth.canAccessPos)
                        _buildSelectionCard(
                          context,
                          title: 'Point of Sale',
                          subtitle: 'Quick barcode scanning & checkout',
                          icon: LucideIcons.shoppingCart,
                          color: AppColors.STAR_PRIMARY,
                          onTap: () {
                            context.read<AuthProvider>().setAppMode(AppMode.pos);
                          },
                        ),
                      if (auth.isLoggedIn && !auth.canAccessInventory && !auth.canAccessAnalytics)
                        const Center(
                          child: Text(
                            'No modules assigned to your account.\nPlease contact Admin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.DANGER),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // Version & Manual Update
              const SizedBox(height: 30),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Column(
                    children: [
                      Text(
                        'Version ${auth.appVersion}',
                        style: const TextStyle(color: AppColors.STAR_TEXT_SECONDARY, fontSize: 12),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Checking for updates... please wait'), duration: Duration(seconds: 2))
                          );
                          await auth.checkRemoteUpdate(isManual: true);
                          if (auth.updateInfo == null || auth.updateInfo!['available'] != true) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('App is already up to date'))
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.refreshCw, size: 14, color: AppColors.STAR_PRIMARY),
                        label: const Text('Check for Updates', style: TextStyle(color: AppColors.STAR_PRIMARY, fontSize: 12)),
                      ),
                    ],
                  );
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

  Widget _buildLogoWidget(String base64) {
    try {
      final bytes = base64.contains(',') 
          ? base64Decode(base64.split(',').last) 
          : base64Decode(base64);
      
      final isSvg = base64.contains('/svg') || 
                   (bytes.length > 20 && utf8.decode(bytes.take(20).toList(), allowMalformed: true).contains('<svg'));

      Widget fallback = Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: AppColors.STAR_PRIMARY.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.store, size: 50, color: AppColors.STAR_PRIMARY),
      );

      return Container(
        height: 120,
        constraints: const BoxConstraints(maxWidth: 250),
        child: isSvg 
            ? SvgPicture.memory(
                bytes, 
                fit: BoxFit.contain,
                placeholderBuilder: (context) => fallback,
              )
            : Image.memory(
                bytes, 
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      );
    } catch (e) {
      return Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: AppColors.STAR_PRIMARY.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.store, size: 50, color: AppColors.STAR_PRIMARY),
      );
    }
  }
}
