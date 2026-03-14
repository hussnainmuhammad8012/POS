import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/application/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/toast_notification.dart';
import '../application/settings_provider.dart';
import 'widgets/companion_server_settings.dart';
import '../../customers/application/customers_provider.dart';
import '../../suppliers/application/suppliers_provider.dart';
import '../../inventory/application/inventory_provider.dart';
import '../../inventory/application/stock_provider.dart';
import '../../transactions/application/transactions_provider.dart';
import '../../pos/application/pos_provider.dart';
import '../../analytics/application/analytics_provider.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _activeTab = 0; // 0: Store, 1: Receipt, 2: Payments, 3: Appearance, 4: Backup, 5: Companion

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: Column(
        children: [
          GlassHeader(
            title: 'Settings',
            subtitle: 'Configure your point of sale preferences',
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sub Navigation
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    children: [
                      _SettingsNavTile(
                        icon: LucideIcons.store,
                        label: 'Store Information',
                        isSelected: _activeTab == 0,
                        onTap: () => setState(() => _activeTab = 0),
                      ),
                      _SettingsNavTile(
                        icon: LucideIcons.receipt,
                        label: 'Receipt Options',
                        isSelected: _activeTab == 1,
                        onTap: () => setState(() => _activeTab = 1),
                      ),
                      _SettingsNavTile(
                        icon: LucideIcons.creditCard,
                        label: 'Payment Methods',
                        isSelected: _activeTab == 2,
                        onTap: () => setState(() => _activeTab = 2),
                      ),
                      _SettingsNavTile(
                        icon: LucideIcons.palette,
                        label: 'Appearance',
                        isSelected: _activeTab == 3,
                        onTap: () => setState(() => _activeTab = 3),
                      ),
                      _SettingsNavTile(
                        icon: LucideIcons.database,
                        label: 'Backup & Restore',
                        isSelected: _activeTab == 4,
                        onTap: () => setState(() => _activeTab = 4),
                      ),
                      _SettingsNavTile(
                        icon: LucideIcons.smartphone,
                        label: 'Companion App',
                        isSelected: _activeTab == 5,
                        onTap: () => setState(() => _activeTab = 5),
                      ),
                    ],
                  ),
                ),
                // Settings Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_activeTab == 0) _StoreInfoPanel(settings: settings),
                        if (_activeTab == 1) _ReceiptOptionsPanel(settings: settings),
                        if (_activeTab == 2) _PaymentMethodsPanel(settings: settings),
                        if (_activeTab == 3) const _AppearancePanel(),
                        if (_activeTab == 4) const _BackupRestorePanel(),
                        if (_activeTab == 5) const CompanionServerSettings(),
                      ],
                    ),
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

class _StoreInfoPanel extends StatelessWidget {
  final SettingsProvider settings;
  const _StoreInfoPanel({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Store Information', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text('Customize the details shown on receipts and reports.',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        const SizedBox(height: 32),
        ModernCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Store Name',
                initialValue: settings.storeName,
                onChanged: (v) => settings.updateStoreInfo(name: v),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Address',
                initialValue: settings.storeAddress,
                onChanged: (v) => settings.updateStoreInfo(address: v),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Phone Number',
                initialValue: settings.storePhone,
                onChanged: (v) => settings.updateStoreInfo(phone: v),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Tax Rate (%)',
                initialValue: settings.taxRate.toString(),
                keyboardType: TextInputType.number,
                onChanged: (v) => settings.updateStoreInfo(tax: double.tryParse(v)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptOptionsPanel extends StatelessWidget {
  final SettingsProvider settings;
  const _ReceiptOptionsPanel({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Receipt Options', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text('Configure your invoice layout and messages.', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        const SizedBox(height: 32),
        ModernCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Custom Receipt Message',
                hint: 'e.g. Hope you visit us again!',
                maxLines: 3,
                initialValue: settings.receiptCustomMessage,
                onChanged: (v) => settings.updateReceiptMessage(v),
              ),
              const SizedBox(height: 16),
              Text(
                'This message will appear at the bottom of every printed invoice.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodsPanel extends StatefulWidget {
  final SettingsProvider settings;
  const _PaymentMethodsPanel({required this.settings});

  @override
  State<_PaymentMethodsPanel> createState() => _PaymentMethodsPanelState();
}

class _PaymentMethodsPanelState extends State<_PaymentMethodsPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Methods', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text('Manage the ways your customers can pay for orders.', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        const SizedBox(height: 32),
        ModernCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _controller,
                      label: 'Add Payment Method',
                      hint: 'e.g. Easypaisa',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          widget.settings.addPaymentMethod(_controller.text);
                          _controller.clear();
                        }
                      },
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Add'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text('Available Methods', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.settings.paymentMethods.map((method) {
                  return Chip(
                    label: Text(method),
                    onDeleted: method == 'CASH' ? null : () => widget.settings.removePaymentMethod(method),
                    deleteIconColor: Colors.red,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppearancePanel extends StatelessWidget {
  const _AppearancePanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    label: 'StarAdmin',
                    isSelected: themeProvider.themeMode == ThemeMode.system,
                    icon: LucideIcons.monitor,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackupRestorePanel extends StatelessWidget {
  const _BackupRestorePanel();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Backup & Restore', style: theme.textTheme.displaySmall),
        const SizedBox(height: 8),
        Text('Safeguard your database or import a previous state.', style: TextStyle(color: theme.colorScheme.secondary)),
        const SizedBox(height: 32),
        
        // Auto Backup Settings
        ModernCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.shieldCheck, color: theme.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Automatic Backups', style: theme.textTheme.titleLarge),
                        Text('Protect your data by creating periodic local copies.', 
                          style: TextStyle(color: theme.colorScheme.secondary, fontSize: 13)
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.autoBackupEnabled,
                    onChanged: (v) => settings.setAutoBackup(v),
                  ),
                ],
              ),
              if (settings.lastBackupDate != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Last successful backup: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(settings.lastBackupDate!))}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Manual Actions
        Row(
          children: [
            Expanded(
              child: ModernCard(
                onTap: () => _handleManualExport(context, settings),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(LucideIcons.download, size: 32, color: theme.primaryColor),
                    const SizedBox(height: 16),
                    Text('Backup Now', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Save to PC, USB, or Google Drive', 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12)
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ModernCard(
                onTap: () => _handleRestore(context, settings),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(LucideIcons.upload, size: 32, color: Colors.green),
                    const SizedBox(height: 16),
                    Text('Restore Data', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Import from a previous backup file', 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.secondary, fontSize: 12)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),
        
        // Danger Zone
        Text('Danger Zone', style: theme.textTheme.titleLarge?.copyWith(color: AppColors.DANGER)),
        const SizedBox(height: 16),
        ModernCard(
          borderColor: AppColors.DANGER.withOpacity(0.3),
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Clear Database', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.DANGER)
                    ),
                    const SizedBox(height: 4),
                    Text('Permanently delete all transactions, products, and records. This cannot be undone.', 
                      style: TextStyle(color: theme.colorScheme.secondary, fontSize: 13)
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showClearDatabaseConfirmation(context, settings),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.DANGER,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear All Data'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleManualExport(BuildContext context, SettingsProvider settings) async {
    try {
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(now);
      final defaultName = 'store_backup_$timestamp.db';
      
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Select Where to Save Your Backup',
        fileName: defaultName,
        type: FileType.any,
      );

      if (outputFile != null) {
        await settings.manualExport(outputFile);
        if (context.mounted) {
          AppToast.show(
            context,
            title: 'Backup Success',
            message: 'Backup saved successfully!',
            type: ToastType.success,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          context,
          title: 'Backup Failed',
          message: e.toString(),
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, SettingsProvider settings) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select Backup File to Restore',
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        
        // Final confirmation before restore
        if (context.mounted) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Restore Database?'),
              content: const Text('This will replace ALL current data with the data from the selected backup file. The app will restart internal services.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Confirm Restore'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await settings.restoreBackup(path);
            if (context.mounted) {
              AppToast.show(
                context,
                title: 'Restore Success',
                message: 'Database restored successfully!',
                type: ToastType.success,
              );
            }
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          context,
          title: 'Restore Failed',
          message: e.toString(),
          type: ToastType.error,
        );
      }
    }
  }

  void _showClearDatabaseConfirmation(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Strict Confirmation Required', style: TextStyle(color: AppColors.DANGER)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This action is IRREVERSIBLE. All sales, customers, and inventory will be wiped.'),
            const SizedBox(height: 16),
            const Text('To confirm, please type "DELETE" below:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'DELETE',
                errorStyle: TextStyle(color: AppColors.DANGER),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().toUpperCase() == 'DELETE') {
                await settings.clearDatabase();
                if (context.mounted) {
                  Navigator.pop(context);
                  
                  // Immediately clear UI state globally
                  context.read<CustomersProvider>().loadCustomers();
                  context.read<SuppliersProvider>().loadSuppliers();
                  context.read<InventoryProvider>().loadCategories();
                  context.read<InventoryProvider>().loadProducts();
                  context.read<TransactionsProvider>().loadTransactions();
                  context.read<StockProvider>().loadMovements();
                  context.read<PosProvider>().clearCart();
                  context.read<AnalyticsProvider>().refreshData();

                  AppToast.show(
                    context,
                    title: 'Database Cleared',
                    message: 'Application data has been reset.',
                    type: ToastType.warning,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.DANGER, foregroundColor: Colors.white),
            child: const Text('I Understand, Delete All'),
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
  final VoidCallback onTap;

  const _SettingsNavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
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
        onTap: onTap,
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
          color: isSelected ? theme.primaryColor.withAlpha(26) : Colors.transparent, 
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
