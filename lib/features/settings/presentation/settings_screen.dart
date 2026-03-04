import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/application/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GlassHeader(
            title: 'Settings',
            subtitle: 'Configure your point of sale preferences',
            actions: [
              ElevatedButton(
                onPressed: () {},
                child: const Text('Save Changes'),
              ),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Theme.of(context).dividerTheme.color!),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    children: [
                      const _SettingsNavTile(icon: LucideIcons.store, label: 'Store Information', isSelected: true),
                      const _SettingsNavTile(icon: LucideIcons.receipt, label: 'Receipt Options', isSelected: false),
                      const _SettingsNavTile(icon: LucideIcons.palette, label: 'Appearance', isSelected: false),
                      const _SettingsNavTile(icon: LucideIcons.database, label: 'Backup & Restore', isSelected: false),
                      const _SettingsNavTile(icon: LucideIcons.terminal, label: 'System', isSelected: false),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(48),
                    children: [
                      Text('Store Information', style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 8),
                      Text('Customize the details shown on receipts and reports.', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                      const SizedBox(height: 32),
                      ModernCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CustomTextField(
                              label: 'Store Name',
                              initialValue: 'Utility POS Central',
                            ),
                            const SizedBox(height: 24),
                            const CustomTextField(
                              label: 'Address',
                              initialValue: '123 Main Street',
                            ),
                            const SizedBox(height: 24),
                            const CustomTextField(
                              label: 'Phone Number',
                              initialValue: '+92 300 1234567',
                            ),
                            const SizedBox(height: 24),
                            const CustomTextField(
                              label: 'Tax Rate (%)',
                              initialValue: '18.0',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text('Appearance', style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 8),
                      Text('Switch between light and dark modes.', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                      const SizedBox(height: 32),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) => ModernCard(
                          padding: const EdgeInsets.all(32),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ThemeModeSelector(
                                  label: 'Light',
                                  isSelected: themeProvider.themeMode == ThemeMode.light,
                                  icon: LucideIcons.sun,
                                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ThemeModeSelector(
                                  label: 'Dark',
                                  isSelected: themeProvider.themeMode == ThemeMode.dark,
                                  icon: LucideIcons.moon,
                                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ThemeModeSelector(
                                  label: 'System (StarAdmin)',
                                  isSelected: themeProvider.themeMode == ThemeMode.system,
                                  icon: LucideIcons.monitor,
                                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text('Backup & Restore', style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 8),
                      Text('Safeguard your database or import a previous state.', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                      const SizedBox(height: 32),
                      ModernCard(
                        padding: const EdgeInsets.all(32),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Create Backup', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 4),
                                  Text('Creates a complete SQLite copy of your data.', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.cloud_download),
                              label: const Text('Backup Now'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ModernCard(
                        padding: const EdgeInsets.all(32),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Restore Data', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 4),
                                  Text('Replace current data with a previous backup.', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.cloud_upload),
                              label: const Text('Restore'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _SettingsNavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {},
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _ThemeModeSelector({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withAlpha(26) : Colors.transparent, // ~10% opacity
          border: Border.all(
            color: isSelected ? theme.primaryColor : (isDark ? AppColors.DARK_BORDER_PROMINENT : AppColors.LIGHT_BORDER_PROMINENT),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? theme.primaryColor : theme.colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
