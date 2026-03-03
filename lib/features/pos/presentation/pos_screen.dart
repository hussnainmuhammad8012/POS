import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/models/entities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../../customers/application/customers_provider.dart';
import '../application/pos_provider.dart';

class PosScreen extends StatelessWidget {
  static const routeName = '/pos';

  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final customers = context.watch<CustomersProvider>().customers;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side - Products/Scanning Panel
          Expanded(
            flex: 5,
            child: Column(
              children: [
                const GlassHeader(
                  title: 'Point of Sale',
                  subtitle: 'Quick checkout & product scanning',
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        ModernCard(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 100,
                                child: CustomTextField(
                                  label: 'Quantity',
                                  initialValue: pos.bulkQuantity.toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    final parsed = int.tryParse(v) ?? 1;
                                    pos.setBulkQuantity(parsed);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Scan Barcode',
                                  hint: 'Enter barcode...',
                                  prefixIcon: LucideIcons.scanLine,
                                  autofocus: true,
                                  onSubmitted: (barcode) {
                                    if (barcode.isEmpty) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Product lookup not wired yet.')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Usually you'd put a grid of quick-add products here
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerTheme.color!),
                            ),
                            child: const Center(
                              child: Text('Product Grid Placeholder\n(Quick access categories)'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right Side - The Cart Sidebar
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border(
                left: BorderSide(color: Theme.of(context).dividerTheme.color!),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Current Order', style: Theme.of(context).textTheme.titleLarge),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(LucideIcons.moreHorizontal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Customer?>(
                        value: pos.selectedCustomer,
                        decoration: InputDecoration(
                          hintText: 'Select Customer',
                          prefixIcon: Icon(LucideIcons.user, size: 18),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        items: [
                          const DropdownMenuItem<Customer?>(value: null, child: Text('Walk-in Customer')),
                          ...customers.map(
                            (c) => DropdownMenuItem<Customer?>(value: c, child: Text(c.name)),
                          ),
                        ],
                        onChanged: (c) => pos.setCustomer(c),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: pos.cartItems.isEmpty ? const _EmptyCartState() : ListView.separated(
                    itemCount: pos.cartItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = pos.cartItems[index];
                      return _ModernCartRow(item: item);
                    },
                  ),
                ),
                const Divider(height: 1),
                _CheckoutSummary(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernCartRow extends StatelessWidget {
  final CartItem item;

  const _ModernCartRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final pos = context.read<PosProvider>();
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerTheme.color!),
            ),
            child: Icon(LucideIcons.package, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${item.product.sellingPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuantityButton(
                      icon: LucideIcons.minus,
                      onTap: () => pos.decrementQuantity(item.product),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        item.quantity.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _QuantityButton(
                      icon: LucideIcons.plus,
                      onTap: () => pos.incrementQuantity(item.product),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs ${item.subtotal.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: Icon(LucideIcons.trash2, size: 18),
                color: Theme.of(context).colorScheme.error,
                onPressed: () => pos.removeProduct(item.product),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerTheme.color!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }
}

class _CheckoutSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: Theme.of(context).textTheme.bodyMedium),
              Text('Rs ${pos.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax', style: Theme.of(context).textTheme.bodyMedium),
              Text('Rs 0.00', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Rs ${pos.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: pos.cartItems.isEmpty ? null : () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              child: const Text('Checkout', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: pos.cartItems.isEmpty ? null : () => pos.clearCart(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Void Sale'),
            ),
          ),
        ],
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
          Icon(LucideIcons.shoppingBag, size: 48, color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Cart is empty',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan products to add them.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
