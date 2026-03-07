import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/models/entities.dart' hide Category, Product, StockMovement, Transaction;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../../customers/application/customers_provider.dart';
import '../../inventory/application/inventory_provider.dart';
import '../../inventory/data/repositories/product_repository.dart';
import '../../customers/presentation/widgets/add_customer_dialog.dart';
import '../application/pos_provider.dart';
import '../application/product_scanner.dart';
import 'widgets/invoice_dialog.dart';
import 'widgets/searchable_customer_dropdown.dart';

class PosScreen extends StatefulWidget {
  static const routeName = '/pos';

  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _barcodeController = TextEditingController();
  final _barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

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
                                  controller: _barcodeController,
                                  focusNode: _barcodeFocusNode,
                                  label: 'Scan Barcode',
                                  hint: 'Enter barcode...',
                                  prefixIcon: LucideIcons.scanLine,
                                  autofocus: true,
                                  onSubmitted: (barcode) async {
                                    if (barcode.isEmpty) return;
                                    
                                    final success = await pos.handleBarcode(
                                      barcode, 
                                      context.read<ProductRepository>(),
                                    );

                                    if (!success && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(pos.error ?? 'Product not found'),
                                          backgroundColor: Theme.of(context).colorScheme.error,
                                        ),
                                      );
                                    }
                                    
                                    _barcodeController.clear();
                                    _barcodeFocusNode.requestFocus();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
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
                left: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
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
                            icon: const Icon(LucideIcons.moreHorizontal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SearchableCustomerDropdown(
                              value: pos.selectedCustomer,
                              onChanged: (c) => pos.setCustomer(c),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const AddCustomerDialog(),
                              );
                            },
                            icon: const Icon(LucideIcons.userPlus),
                            tooltip: 'Add New Customer',
                          ),
                        ],
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
                const _CheckoutSummary(),
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
              border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
            ),
            child: const Icon(LucideIcons.package, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (item.variantName.isNotEmpty)
                  Text(
                    item.variantName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${item.unitPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuantityButton(
                      icon: LucideIcons.minus,
                      onTap: () => pos.decrementQuantity(item.variantId),
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
                      onTap: () => pos.incrementQuantity(item.variantId),
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
                icon: const Icon(LucideIcons.trash2, size: 18),
                color: Theme.of(context).colorScheme.error,
                onPressed: () => pos.removeFromCart(item.variantId),
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
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary();

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
              const Text('Subtotal'),
              Text('Rs ${pos.subtotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax'),
              Text('Rs ${pos.taxAmount.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Rs ${pos.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: pos.cartItems.isEmpty ? null : () async {
                double cashPaid = pos.totalAmount;
                double creditAmount = 0.0;

                if (pos.selectedCustomer != null) {
                  final result = await showDialog<Map<String, double>>(
                    context: context,
                    builder: (context) => _SplitPaymentDialog(total: pos.totalAmount),
                  );
                  if (result == null) return;
                  cashPaid = result['cash']!;
                  creditAmount = result['credit']!;
                }

                // Copy cart items before processing because processCheckout clears them
                final itemsSnapshot = List<CartItem>.from(pos.cartItems);
                
                await pos.processCheckout(
                  cashPaid: cashPaid,
                  creditAmount: creditAmount,
                  onSuccess: (savedTx) {
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => InvoiceDialog(
                          transaction: savedTx,
                          cartItems: itemsSnapshot,
                        ),
                      );
                    }
                  },
                  onError: (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              child: pos.isProcessing 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Checkout', style: TextStyle(fontSize: 16)),
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

class _SplitPaymentDialog extends StatefulWidget {
  final double total;

  const _SplitPaymentDialog({required this.total});

  @override
  State<_SplitPaymentDialog> createState() => _SplitPaymentDialogState();
}

class _SplitPaymentDialogState extends State<_SplitPaymentDialog> {
  late TextEditingController _cashController;
  double _creditAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController(text: widget.total.toStringAsFixed(2));
    _cashController.addListener(_updateCredit);
  }

  void _updateCredit() {
    final cash = double.tryParse(_cashController.text) ?? 0.0;
    setState(() {
      _creditAmount = (widget.total - cash).clamp(0, widget.total);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount:'),
              Text('Rs ${widget.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _cashController,
            label: 'Cash Received',
            prefixIcon: LucideIcons.banknote,
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Remaining to Credit:'),
              Text('Rs ${_creditAmount.toStringAsFixed(2)}', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _creditAmount > 0 ? AppColors.DANGER : Colors.green,
                )
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final cash = double.tryParse(_cashController.text) ?? 0.0;
            Navigator.pop(context, {'cash': cash, 'credit': _creditAmount});
          },
          child: const Text('Complete Sale'),
        ),
      ],
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
