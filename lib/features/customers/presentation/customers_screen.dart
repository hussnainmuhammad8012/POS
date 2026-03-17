import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/models/entities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/toast_notification.dart';
import '../application/customers_provider.dart';
import 'widgets/add_customer_dialog.dart';

class CustomersScreen extends StatefulWidget {
  static const routeName = '/customers';

  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';
  String? _selectedCustomerId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CustomersProvider>();
    
    final customers = provider.customers.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.phone != null && c.phone!.contains(_searchQuery));
    }).toList();

    final selectedCustomer = _selectedCustomerId != null 
        ? provider.customers.cast<Customer?>().firstWhere(
            (c) => c?.id == _selectedCustomerId, 
            orElse: () => null
          )
        : null;

    return Column(
      children: [
        GlassHeader(
          title: 'Customers',
          subtitle: 'Manage client relationships and loyalty',
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddCustomerDialog(),
                );
              },
              icon: const Icon(LucideIcons.userPlus),
              label: const Text('Add Customer'),
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
                              hint: 'Name, phone or email...',
                              onChanged: (v) => setState(() => _searchQuery = v),
                            ),
                          ),
                          const Divider(height: 1),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: customers.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final customer = customers[index];
                              final isSelected = customer.id == _selectedCustomerId;
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.04),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: isSelected 
                                    ? theme.primaryColor 
                                    : theme.scaffoldBackgroundColor,
                                  child: Text(
                                    customer.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected 
                                        ? theme.colorScheme.onPrimary 
                                        : theme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: Text(
                                  customer.phone ?? 'No phone',
                                  style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                                ),
                                trailing: const Icon(LucideIcons.chevronRight, size: 16),
                                onTap: () {
                                  setState(() {
                                    _selectedCustomerId = customer.id;
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
              if (selectedCustomer != null)
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
                                  selectedCustomer.name[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(selectedCustomer.name, style: Theme.of(context).textTheme.displayMedium),
                                  const SizedBox(height: 4),
                                  Text('Customer since ${selectedCustomer.createdAt.toString().split(' ')[0]}',
                                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AddCustomerDialog(initialCustomer: selectedCustomer),
                                  );
                                },
                                icon: const Icon(LucideIcons.edit3, size: 16),
                                label: const Text('Edit'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => _confirmDelete(context, selectedCustomer),
                                icon: const Icon(LucideIcons.trash2, size: 16),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.DANGER),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(child: _buildContactInfo(LucideIcons.phone, 'Phone', selectedCustomer.phone ?? 'N/A')),
                              Expanded(child: _buildContactInfo(LucideIcons.messageCircle, 'WhatsApp', selectedCustomer.whatsappNumber ?? 'N/A')),
                              Expanded(child: _buildContactInfo(LucideIcons.mapPin, 'Address', selectedCustomer.address ?? 'N/A')),
                            ],
                          ),
                          const SizedBox(height: 24),
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
                                          Icon(LucideIcons.trendingUp, size: 16, color: theme.primaryColor),
                                          const SizedBox(width: 8),
                                          Text('Total Spent', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Rs ${selectedCustomer.totalSpent.toStringAsFixed(2)}', 
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
                                          Icon(LucideIcons.creditCard, size: 16, color: selectedCustomer.currentCredit > 0 ? AppColors.DANGER : Colors.green),
                                          const SizedBox(width: 8),
                                          Text('Current Credit', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text('Rs ${selectedCustomer.currentCredit.toStringAsFixed(2)}', 
                                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: selectedCustomer.currentCredit > 0 ? AppColors.DANGER : Colors.green
                                        )
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (selectedCustomer.creditLimit > 0) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(LucideIcons.shieldCheck, size: 14, color: Theme.of(context).colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text('Credit Limit: Rs ${selectedCustomer.creditLimit.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                              ],
                            ),
                          ],
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
                        Icon(LucideIcons.user, size: 64, color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('Select a customer to view details', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(IconData icon, String label, String value) {
    if (value == 'N/A' || value.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Customer customer) async {
    final provider = context.read<CustomersProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to permanently remove ${customer.name}? This action cannot be undone.'),
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
        await provider.deleteCustomer(customer.id!);
        if (context.mounted) {
          setState(() => _selectedCustomerId = null);
          AppToast.show(
            context,
            title: 'Deleted',
            message: 'Customer deleted successfully',
            type: ToastType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(
            context,
            title: 'Error',
            message: 'Failed to delete customer: $e',
            type: ToastType.error,
          );
        }
      }
    }
  }
}
