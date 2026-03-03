import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/entities.dart';
import '../../../core/theme/app_theme.dart';
import '../../customers/application/customers_provider.dart';
import '../application/pos_provider.dart';

class PosScreen extends StatelessWidget {
  static const routeName = '/pos';

  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final customers = context.watch<CustomersProvider>().customers;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Left: Cart
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Current Sale',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    child: Column(
                      children: [
                        _CartHeader(),
                        const Divider(height: 1),
                        Expanded(
                          child: pos.cartItems.isEmpty
                              ? const _EmptyCartState()
                              : ListView.builder(
                                  itemCount: pos.cartItems.length,
                                  itemBuilder: (context, index) {
                                    final item = pos.cartItems[index];
                                    return _CartRow(item: item);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right: Scan + Customer + Summary
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.qr_code_scanner,
                                color: AppColors.info),
                            const SizedBox(width: 8),
                            Text(
                              'Scan Item',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue:
                                    pos.bulkQuantity.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Qty',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final parsed = int.tryParse(v) ?? 1;
                                  pos.setBulkQuantity(parsed);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                autofocus: true,
                                decoration: const InputDecoration(
                                  labelText: 'Barcode',
                                  prefixIcon: Icon(Icons.qr_code),
                                ),
                                onFieldSubmitted: (barcode) async {
                                  // In a full implementation this would look
                                  // up the product by barcode via repository.
                                  if (barcode.isEmpty) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Product lookup by barcode is not wired yet.',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<Customer?>(
                                value: pos.selectedCustomer,
                                decoration: const InputDecoration(
                                  labelText: 'Customer (optional)',
                                ),
                                items: [
                                  const DropdownMenuItem<Customer?>(
                                    value: null,
                                    child: Text('Walk-in customer'),
                                  ),
                                  ...customers.map(
                                    (c) => DropdownMenuItem<Customer?>(
                                      value: c,
                                      child: Text(c.name),
                                    ),
                                  ),
                                ],
                                onChanged: (c) =>
                                    pos.setCustomer(c),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Add new customer',
                              child: IconButton(
                                icon: const Icon(Icons.person_add_alt_1),
                                onPressed: () {
                                  // would open add-customer dialog
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _CheckoutSummary(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'Item',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Price',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Qty',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Total',
              textAlign: TextAlign.end,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final CartItem item;

  const _CartRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final pos = context.read<PosProvider>();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 1),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Container(
          color: value == 1
              ? Colors.transparent
              : AppColors.success.withOpacity(0.05),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                item.product.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₹${item.product.sellingPrice.toStringAsFixed(2)}',
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Decrease quantity',
                    onPressed: () =>
                        pos.decrementQuantity(item.product),
                  ),
                  Text(item.quantity.toString()),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Increase quantity',
                    onPressed: () =>
                        pos.incrementQuantity(item.product),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₹${item.subtotal.toStringAsFixed(2)}',
                textAlign: TextAlign.end,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Remove item',
              onPressed: () =>
                  pos.removeProduct(item.product),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '₹${pos.total.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PaymentButton(
                    icon: Icons.payments,
                    label: 'Cash',
                    color: AppColors.success,
                    onTap: () =>
                        _showPaymentDialog(context, 'Cash'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PaymentButton(
                    icon: Icons.credit_card,
                    label: 'Card',
                    color: AppColors.info,
                    onTap: () =>
                        _showPaymentDialog(context, 'Card'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PaymentButton(
                    icon: Icons.smartphone,
                    label: 'Other',
                    color: AppColors.primaryTeal,
                    onTap: () =>
                        _showPaymentDialog(context, 'Other'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Void Sale'),
                        content: const Text(
                          'Are you sure you want to clear the current cart?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: const Text('No'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: const Text('Yes'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (confirmed) {
                  context.read<PosProvider>().clearCart();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sale cleared.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Void Sale'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentDialog(
    BuildContext context,
    String method,
  ) async {
    final pos = context.read<PosProvider>();
    if (pos.total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one item before checkout.'),
        ),
      );
      return;
    }
    final controller =
        TextEditingController(text: pos.total.toStringAsFixed(2));
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Payment - $method'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Amount due: ₹${pos.total.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount tendered',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(true),
                icon: const Icon(Icons.check),
                label: const Text('Complete Sale'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      // Here we would persist the transaction to SQLite, generate invoice, etc.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Sale completed via $method. (Persistence not wired yet)'),
          backgroundColor: AppColors.success,
        ),
      );
      pos.clearCart();
    }
  }
}

class _PaymentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PaymentButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label payment (Alt+${label[0].toUpperCase()})',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            'No items in the cart.\nScan a barcode to get started!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

