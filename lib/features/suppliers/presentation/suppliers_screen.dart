import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/models/entities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/toast_notification.dart';
import '../../settings/application/settings_provider.dart';
import '../application/suppliers_provider.dart';
import 'widgets/add_supplier_dialog.dart';
import 'supplier_ledger_screen.dart';

class SuppliersScreen extends StatefulWidget {
  static const routeName = '/suppliers';

  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String _searchQuery = '';
  String? _selectedSupplierId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SuppliersProvider>();
    final isLedgerEnabled = context.watch<SettingsProvider>().isSupplierLedgerEnabled;
    
    final suppliers = provider.suppliers.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.phone != null && s.phone!.contains(_searchQuery));
    }).toList();

    final selectedSupplier = _selectedSupplierId != null 
        ? provider.suppliers.cast<Supplier?>().firstWhere(
            (s) => s?.id == _selectedSupplierId, 
            orElse: () => null
          )
        : null;

    return Scaffold(
      body: Column(
        children: [
          GlassHeader(
            title: 'Suppliers',
            subtitle: 'Manage inventory sources and payments',
            actions: [
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AddSupplierDialog(),
                  );
                },
                icon: const Icon(LucideIcons.truck),
                label: const Text('Add Supplier'),
              ),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      ModernCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CustomTextField(
                                label: 'Search',
                                prefixIcon: LucideIcons.search,
                                hint: 'Name or phone...',
                                onChanged: (v) => setState(() => _searchQuery = v),
                              ),
                            ),
                            const Divider(height: 1),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: suppliers.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final supplier = suppliers[index];
                                final isSelected = supplier.id == _selectedSupplierId;
                                return ListTile(
                                  selected: isSelected,
                                  selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.04),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected 
                                      ? theme.primaryColor 
                                      : theme.scaffoldBackgroundColor,
                                    child: Text(
                                      supplier.name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: isSelected 
                                          ? theme.colorScheme.onPrimary 
                                          : theme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  subtitle: Text(
                                    supplier.phone ?? 'No phone',
                                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                                  ),
                                  trailing: Icon(LucideIcons.chevronRight, size: 16),
                                  onTap: () {
                                    setState(() {
                                      _selectedSupplierId = supplier.id;
                                    });
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedSupplier != null)
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Theme.of(context).dividerTheme.color!),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                                  child: Text(
                                    selectedSupplier.name[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(selectedSupplier.name, style: Theme.of(context).textTheme.displayMedium),
                                      const SizedBox(height: 4),
                                      Text('Added ${selectedSupplier.createdAt.toString().split(' ')[0]}',
                                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AddSupplierDialog(initialSupplier: selectedSupplier),
                                    );
                                  },
                                  icon: const Icon(LucideIcons.edit3, size: 16),
                                  label: const Text('Edit'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _confirmDelete(context, selectedSupplier),
                                  icon: const Icon(LucideIcons.trash2, size: 16),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.DANGER),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(child: _buildContactInfo(LucideIcons.user, 'Contact', selectedSupplier.contactPerson ?? 'N/A')),
                                Expanded(child: _buildContactInfo(LucideIcons.phone, 'Phone', selectedSupplier.phone ?? 'N/A')),
                                Expanded(child: _buildContactInfo(LucideIcons.mapPin, 'Address', selectedSupplier.address ?? 'N/A')),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (isLedgerEnabled) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: ModernCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(LucideIcons.packagePlus, size: 16, color: theme.primaryColor),
                                              const SizedBox(width: 8),
                                              Text('Total Purchased', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Rs ${selectedSupplier.totalPurchased.toStringAsFixed(2)}', 
                                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                              color: theme.primaryColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ModernCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(LucideIcons.landmark, size: 16, color: selectedSupplier.currentDue > 0 ? AppColors.DANGER : Colors.green),
                                              const SizedBox(width: 8),
                                              Text('Current Due', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text('Rs ${selectedSupplier.currentDue.toStringAsFixed(2)}', 
                                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: selectedSupplier.currentDue > 0 ? AppColors.DANGER : Colors.green
                                            )
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SupplierLedgerScreen(supplier: selectedSupplier),
                                      ),
                                    );
                                  },
                                  icon: const Icon(LucideIcons.bookOpen),
                                  label: const Text('View Detailed Ledger & Record Payment'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    foregroundColor: theme.colorScheme.onSurface,
                                    elevation: 0,
                                  ),
                                ),
                              )
                            ] else ...[
                               ModernCard(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.calculator, size: 48, color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Supplier Ledger is Disabled',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Financial tracking for purchasing from suppliers is currently turned off in Settings. You can still assign products and stock to this supplier for physical tracking.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                                      ),
                                    ]
                                  ),
                                ),
                              )
                            ]
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.truck, size: 64, color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text('Select a supplier to view details', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
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

  Widget _buildContactInfo(IconData icon, String label, String value) {
    if (value == 'N/A' || value.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value, 
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Supplier supplier) async {
    final provider = context.read<SuppliersProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to permanently remove ${supplier.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.DANGER, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await provider.deleteSupplier(supplier.id!);
        if (context.mounted) {
          setState(() => _selectedSupplierId = null);
          AppToast.show(
            context,
            title: 'Deleted',
            message: 'Supplier deleted successfully',
            type: ToastType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(
            context,
            title: 'Error',
            message: 'Failed to delete supplier: $e',
            type: ToastType.error,
          );
        }
      }
    }
  }
}
