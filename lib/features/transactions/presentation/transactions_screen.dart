import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/badge_widget.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../application/transactions_provider.dart';

class TransactionsScreen extends StatelessWidget {
  static const routeName = '/transactions';

  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
      ),
    );
  }

  Widget _buildFilters(BuildContext context, TransactionsProvider provider) {
    final theme = Theme.of(context);
    
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'Today',
            isSelected: provider.currentFilter == TransactionFilter.today,
            onTap: () => provider.setFilter(TransactionFilter.today),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Last 7 Days',
            isSelected: provider.currentFilter == TransactionFilter.last7Days,
            onTap: () => provider.setFilter(TransactionFilter.last7Days),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Last 30 Days',
            isSelected: provider.currentFilter == TransactionFilter.lastMonth,
            onTap: () => provider.setFilter(TransactionFilter.lastMonth),
          ),
          const SizedBox(width: 8),
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
          const Spacer(),
          Text(
            '${provider.transactions.length} Transactions Found',
            style: theme.textTheme.bodySmall,
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
                DataCell(Text(tx.customerId == null ? 'Walk-in' : 'Customer #${tx.customerId}')),
                DataCell(Text(currencyFormat.format(tx.finalAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(tx.paymentMethod.toUpperCase())),
                DataCell(
                  BadgeWidget(
                    label: tx.paymentStatus,
                    type: tx.paymentStatus.toLowerCase() == 'completed' ? BadgeType.success : BadgeType.warning,
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(LucideIcons.eye, size: 20),
                    onPressed: () {
                      // Show Details Dialog
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
