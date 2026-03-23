import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/models/entities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/badge_widget.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../application/transactions_provider.dart';

class TransactionDetailsScreen extends StatelessWidget {
  static const routeName = '/transaction-details';
  final Transaction transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy • hh:mm a');

    return Scaffold(
      body: Column(
        children: [
          GlassHeader(
            title: 'Transaction Details',
            subtitle: 'Invoice #${transaction.invoiceNumber}',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Main Info & Payment
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildInfoCard(context, theme, dateFormat),
                            const SizedBox(height: 24),
                            _buildPaymentCard(context, theme, currencyFormat),
                            const SizedBox(height: 24),
                            _buildItemsCard(context, theme, currencyFormat),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right Column: Customer & Summary
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildCustomerCard(context, theme),
                            const SizedBox(height: 24),
                            _buildSummaryCard(context, theme, currencyFormat),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ThemeData theme, DateFormat dateFormat) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Invoice Number', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(transaction.invoiceNumber, 
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              BadgeWidget(
                label: transaction.paymentStatus.toUpperCase(),
                type: transaction.paymentStatus.toLowerCase() == 'completed' 
                  ? BadgeType.success 
                  : BadgeType.warning,
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              _buildDetailItem(LucideIcons.calendar, 'Date & Time', dateFormat.format(transaction.createdAt)),
              const Spacer(),
              _buildDetailItem(LucideIcons.hash, 'Transaction ID', transaction.id ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, ThemeData theme) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.user, size: 20, color: theme.primaryColor),
              const SizedBox(width: 12),
              const Text('Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  (transaction.customerName ?? 'W')[0].toUpperCase(),
                  style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.customerName ?? 'Walk-in Customer', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                  ),
                  if (transaction.customerId != null)
                    Text('ID: ${transaction.customerId}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, ThemeData theme, NumberFormat currencyFormat) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.creditCard, size: 20, color: theme.primaryColor),
              const SizedBox(width: 12),
              const Text('Payment Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(child: _buildDetailItem(LucideIcons.wallet, 'Method', transaction.paymentMethod.toUpperCase())),
              Expanded(child: _buildDetailItem(LucideIcons.banknote, 'Cash Paid', currencyFormat.format(transaction.cashPaid))),
              if (transaction.creditAmount > 0)
                Expanded(child: _buildDetailItem(LucideIcons.alertCircle, 'Credit Applied', currencyFormat.format(transaction.creditAmount), valueColor: AppColors.DANGER)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, ThemeData theme, NumberFormat currencyFormat) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(LucideIcons.shoppingBag, size: 20, color: theme.primaryColor),
                const SizedBox(width: 12),
                const Text('Items Purchased', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          FutureBuilder<List<Map<String, Object?>>>(
            future: context.read<TransactionsProvider>().getTransactionItems(transaction.id!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: Text('No items found for this transaction.')),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final productName = item['product_name'] as String? ?? 'Unknown Product';
                  final productSku = item['product_sku'] as String? ?? item['product_variant_id'];
                  final variantName = item['variant_name'] as String?;
                  final unitName = item['unit_name'] as String?;
                  final quantity = (item['quantity'] as num).toInt();
                  final price = (item['price_at_time'] as num).toDouble();
                  final subtotal = (item['subtotal'] as num).toDouble();

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'SKU: $productSku',
                          style: TextStyle(color: theme.hintColor, fontSize: 11, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    subtitle: variantName != null && variantName.isNotEmpty 
                      ? Text(variantName, style: TextStyle(color: theme.colorScheme.secondary, fontSize: 13))
                      : null,
                    trailing: IntrinsicWidth(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$quantity ${unitName ?? ""}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'x ${currencyFormat.format(price)}',
                                style: TextStyle(color: theme.hintColor, fontSize: 11),
                              ),
                              if (item['item_discount'] != null && (item['item_discount'] as num) > 0)
                                Text(
                                  '${(item['item_discount_percent'] as num?)?.toStringAsFixed(1) ?? "0.0"}% (-${currencyFormat.format((item['item_discount'] as num).toDouble())})',
                                  style: const TextStyle(color: AppColors.SUCCESS, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Text(
                            currencyFormat.format(subtotal),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ThemeData theme, NumberFormat currencyFormat) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.barChart3, size: 20, color: theme.primaryColor),
              const SizedBox(width: 12),
              const Text('Payment Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          _buildSummaryRow('Gross Total', currencyFormat.format(transaction.totalAmount)),
          if (transaction.discount > 0)
            _buildSummaryRow(
              'Total Discount (${transaction.discountPercent.toStringAsFixed(1)}%)', 
              '- ${currencyFormat.format(transaction.discount)}', 
              color: AppColors.SUCCESS
            ),
          if (transaction.tax > 0)
            _buildSummaryRow('Tax', '+ ${currencyFormat.format(transaction.tax)}'),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(currencyFormat.format(transaction.finalAmount), 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: theme.primaryColor)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: valueColor)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
