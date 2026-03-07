import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/entities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/toast_notification.dart';
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
    final provider = context.watch<CustomersProvider>();
    final filteredDebtors = provider.filteredDebtors;
    final totalCredit = provider.totalOutstandingCredit;

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
                // Left Panel - Debtors List with Filters & Summary
                Container(
                  width: 400,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Column(
                    children: [
                      // Total Summary Card
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ModernCard(
                          backgroundColor: AppColors.DANGER.withValues(alpha: 0.1),
                          borderColor: AppColors.DANGER.withValues(alpha: 0.3),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.DANGER.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.alertCircle, color: AppColors.DANGER),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Outstanding', 
                                      style: TextStyle(fontSize: 13, color: AppColors.DANGER, fontWeight: FontWeight.bold)
                                    ),
                                    Text('Rs ${NumberFormat('#,##0').format(totalCredit)}', 
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: AppColors.DANGER, 
                                        fontWeight: FontWeight.bold
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Filters Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            CustomTextField(
                              hint: 'Search debtors...',
                              prefixIcon: LucideIcons.search,
                              onChanged: (v) => provider.setSearchQuery(v),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _FilterChip(
                                  label: 'All', 
                                  isSelected: provider.creditFilter == CreditFilter.all,
                                  onTap: () => provider.setCreditFilter(CreditFilter.all),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'High (>5k)', 
                                  isSelected: provider.creditFilter == CreditFilter.high,
                                  onTap: () => provider.setCreditFilter(CreditFilter.high),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Low', 
                                  isSelected: provider.creditFilter == CreditFilter.low,
                                  onTap: () => provider.setCreditFilter(CreditFilter.low),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      // Debtors List
                      Expanded(
                        child: filteredDebtors.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.users, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                                    const SizedBox(height: 16),
                                    const Text('No debtors found'),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredDebtors.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final c = filteredDebtors[index];
                                  final isSelected = _selectedCustomer?.id == c.id;
                                  return ModernCard(
                                    onTap: () => _selectCustomer(c),
                                    padding: const EdgeInsets.all(16),
                                    borderColor: isSelected ? Theme.of(context).primaryColor : null,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                                          child: Text(c.name[0].toUpperCase(), 
                                            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)
                                          ),
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
                                          'Rs ${NumberFormat('#,##0').format(c.currentCredit)}',
                                          style: const TextStyle(color: AppColors.DANGER, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                // Right Panel - Ledger
                Expanded(
                  child: _selectedCustomer == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.bookOpen, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              const Text('Select a customer to view ledger', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : _CustomerLedgerView(customer: provider.debtors.firstWhere((c) => c.id == _selectedCustomer!.id, orElse: () => _selectedCustomer!)),
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
                   AppToast.show(
                     context,
                     title: 'Payment Recorded',
                     message: 'Payment of Rs ${amount.toStringAsFixed(2)} received.',
                     type: ToastType.success,
                   );
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.show(
                    context,
                    title: 'Payment Failed',
                    message: e.toString(),
                    type: ToastType.error,
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
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
