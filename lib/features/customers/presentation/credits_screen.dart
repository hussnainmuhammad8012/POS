import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/entities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../application/customers_provider.dart';
import '../application/credit_ledger_provider.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomersProvider>().loadCustomers();
    });
  }

  void _selectCustomer(Customer customer) {
    setState(() => _selectedCustomer = customer);
    context.read<CreditLedgerProvider>().loadLedgers(customer.id!);
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomersProvider>().customers
        .where((c) => c.currentCredit > 0).toList();

    return Scaffold(
      body: Column(
        children: [
          const GlassHeader(
            title: 'Credit Management',
            subtitle: 'Track outstanding balances and customer payments',
          ),
          Expanded(
            child: Row(
              children: [
                // Left Panel - Debtors List
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: customers.isEmpty
                      ? const Center(child: Text('No customers with outstanding credit'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: customers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final c = customers[index];
                            final isSelected = _selectedCustomer?.id == c.id;
                            return ModernCard(
                              onTap: () => _selectCustomer(c),
                              padding: const EdgeInsets.all(16),
                              borderColor: isSelected ? Theme.of(context).primaryColor : null,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                                    child: const Icon(LucideIcons.user, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(c.phone ?? 'No phone', style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Rs ${c.currentCredit.toStringAsFixed(0)}',
                                    style: const TextStyle(color: AppColors.DANGER, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Right Panel - Ledger
                Expanded(
                  child: _selectedCustomer == null
                      ? const Center(child: Text('Select a customer to view ledger'))
                      : _CustomerLedgerView(customer: _selectedCustomer!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerLedgerView extends StatelessWidget {
  final Customer customer;

  const _CustomerLedgerView({required this.customer});

  @override
  Widget build(BuildContext context) {
    final ledgerProvider = context.watch<CreditLedgerProvider>();
    final ledgers = ledgerProvider.ledgers;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: Theme.of(context).textTheme.headlineMedium),
                  Text('Current Balance: Rs ${customer.currentCredit.toStringAsFixed(2)}', 
                    style: const TextStyle(color: AppColors.DANGER, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showPaymentDialog(context),
                icon: const Icon(LucideIcons.banknote),
                label: const Text('Receive Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Ledger History', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: ledgerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ledgers.isEmpty
                    ? const Center(child: Text('No ledger entries found'))
                    : ListView.separated(
                        itemCount: ledgers.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final entry = ledgers[index];
                          final isCredit = entry.type == 'CREDIT';
                          return ListTile(
                            leading: Icon(
                              isCredit ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                              color: isCredit ? AppColors.DANGER : Colors.green,
                            ),
                            title: Text(isCredit ? 'Credit Sale' : 'Payment Received'),
                            subtitle: Text(DateFormat('MMM dd, yyyy HH:mm').format(entry.createdAt)),
                            trailing: Text(
                              '${isCredit ? "+" : "-"} Rs ${entry.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCredit ? AppColors.DANGER : Colors.green,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final controller = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receive Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: controller,
              label: 'Amount Received',
              prefixIcon: LucideIcons.banknote,
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: notesController,
              label: 'Notes (Optional)',
              prefixIcon: LucideIcons.stickyNote,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0.0;
              if (amount <= 0) return;

              try {
                await context.read<CreditLedgerProvider>().addPayment(
                  customerId: customer.id!,
                  amount: amount,
                  notes: notesController.text,
                );
                // Refresh customer to get new currentCredit
                if (context.mounted) {
                   await context.read<CustomersProvider>().loadCustomers();
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Payment recorded successfully'), backgroundColor: Colors.green),
                   );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.DANGER),
                  );
                }
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }
}
