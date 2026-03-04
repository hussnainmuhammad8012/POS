import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/models/entities.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../application/customers_provider.dart';

class CustomersScreen extends StatefulWidget {
  static const routeName = '/customers';

  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';
  Customer? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CustomersProvider>();
    final customers = provider.customers.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.phone != null && c.phone!.contains(_searchQuery));
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          GlassHeader(
            title: 'Customers',
            subtitle: 'Manage client relationships and loyalty',
            actions: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(LucideIcons.userPlus),
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
                                final isSelected = customer == _selectedCustomer;
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
                                  trailing: Icon(LucideIcons.chevronRight, size: 16),
                                  onTap: () {
                                    setState(() {
                                      _selectedCustomer = customer;
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
                if (_selectedCustomer != null)
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
                                    _selectedCustomer!.name[0].toUpperCase(),
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
                                    Text(_selectedCustomer!.name, style: Theme.of(context).textTheme.displayMedium),
                                    const SizedBox(height: 4),
                                    Text('Customer since ${_selectedCustomer!.createdAt.toString().split(' ')[0]}',
                                      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: ModernCard(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Total Spent', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)),
                                        const SizedBox(height: 8),
                                        Text('Rs ${_selectedCustomer!.totalSpent.toStringAsFixed(2)}', style: Theme.of(context).textTheme.displaySmall),
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
                                        Text('Loyalty Points', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)),
                                        const SizedBox(height: 8),
                                        Text('0', style: Theme.of(context).textTheme.displaySmall),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}
