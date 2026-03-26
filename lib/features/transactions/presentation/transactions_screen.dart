import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../settings/application/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/badge_widget.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../application/transactions_provider.dart';
import 'transaction_details_screen.dart';

class TransactionsScreen extends StatelessWidget {
  static const routeName = '/transactions';

  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GlassHeader(
          title: 'Transactions',
          subtitle: 'View and filter your store sales history',
        ),
        Expanded(
          child: Consumer<TransactionsProvider>(
            builder: (context, provider, child) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildFilters(context, provider),
                  const SizedBox(height: 24),
                  if (provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (provider.transactions.isEmpty)
                    _buildEmptyState(context)
                  else
                    _buildTransactionsTable(context, provider),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, TransactionsProvider provider) {
    final theme = Theme.of(context);
    
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FilterChip(
            label: 'Today',
            isSelected: provider.currentFilter == TransactionFilter.today,
            onTap: () => provider.setFilter(TransactionFilter.today),
          ),
          _FilterChip(
            label: 'Last 7 Days',
            isSelected: provider.currentFilter == TransactionFilter.last7Days,
            onTap: () => provider.setFilter(TransactionFilter.last7Days),
          ),
          _FilterChip(
            label: 'Last 30 Days',
            isSelected: provider.currentFilter == TransactionFilter.lastMonth,
            onTap: () => provider.setFilter(TransactionFilter.lastMonth),
          ),
          _FilterChip(
            label: provider.currentFilter == TransactionFilter.custom && provider.customRange != null
                ? '${DateFormat('MMM dd').format(provider.customRange!.start)} - ${DateFormat('MMM dd').format(provider.customRange!.end)}'
                : 'Custom Range',
            isSelected: provider.currentFilter == TransactionFilter.custom,
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: theme.copyWith(
                      colorScheme: theme.colorScheme.copyWith(
                        primary: theme.primaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (range != null) {
                provider.setFilter(TransactionFilter.custom, range: range);
              }
            },
          ),
          SizedBox(
            width: 180,
            child: AppDropdown<String>(
              value: provider.selectedCustomer ?? 'ALL',
              items: ['ALL', ...provider.availableCustomers].map((c) => AppDropdownItem<String>(
                value: c,
                label: c,
                icon: LucideIcons.user,
              )).toList(),
              onChanged: (v) => provider.setCustomerFilter(v),
              hint: 'Filter by Customer',
            ),
          ),
          SizedBox(
            width: 180,
            child: Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                final methods = ['ALL', ...settings.paymentMethods];
                return AppDropdown<String>(
                  value: provider.selectedPaymentMethod ?? 'ALL',
                  items: methods.map((m) => AppDropdownItem<String>(
                    value: m,
                    label: m,
                    icon: m == 'ALL' ? LucideIcons.filter : 
                          m == 'CASH' ? LucideIcons.banknote : 
                          m == 'BANK' ? LucideIcons.landmark : 
                          m == 'JAZZCASH' ? LucideIcons.smartphone : LucideIcons.creditCard,
                  )).toList(),
                  onChanged: (v) => provider.setPaymentMethodFilter(v),
                  hint: 'Filter by Payment',
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '${provider.transactions.length} Transactions Found',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTable(BuildContext context, TransactionsProvider provider) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

    return ModernCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 56,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 64,
                columnSpacing: 24,
                headingRowColor: WidgetStateProperty.all(theme.scaffoldBackgroundColor.withValues(alpha: 0.5)),
                columns: const [
                  DataColumn(label: Text('Invoice #')),
                  DataColumn(label: Text('Date & Time')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Payment')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: provider.transactions.map((tx) {
                  return DataRow(
                    cells: [
                      DataCell(Text(tx.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(DateFormat('MMM dd, yyyy • hh:mm a').format(tx.createdAt))),
                      DataCell(Text(tx.customerName ?? 'Walk-in')),
                      DataCell(Text(currencyFormat.format(tx.finalAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(tx.paymentMethod.toUpperCase())),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BadgeWidget(
                              label: tx.paymentStatus,
                              type: tx.paymentStatus.toLowerCase() == 'completed' ? BadgeType.success : BadgeType.warning,
                            ),
                            if (tx.isReturned || tx.returnedAmount > 0) ...[
                              const SizedBox(width: 8),
                              BadgeWidget(
                                label: tx.isReturned ? 'RETURNED' : 'PARTIAL',
                                type: BadgeType.error,
                              ),
                            ],
                          ],
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(LucideIcons.eye, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionDetailsScreen(transaction: tx),
                              ),
                            );
                          },
                          tooltip: 'View Details',
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.receipt,
                size: 64,
                color: theme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Transactions Found',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or choose a different date range.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerTheme.color ?? AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
