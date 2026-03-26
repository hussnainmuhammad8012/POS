import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/entities.dart' hide Category, Product, StockMovement, Transaction;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/toast_notification.dart';
import '../../customers/application/customers_provider.dart';
import '../../inventory/application/inventory_provider.dart';
import '../../inventory/data/repositories/product_repository.dart';
import '../../settings/application/settings_provider.dart';
import '../../customers/presentation/widgets/add_customer_dialog.dart';
import '../../analytics/application/analytics_provider.dart';
import '../../transactions/application/transactions_provider.dart';
import '../../inventory/application/stock_provider.dart';
import '../../inventory/data/models/product_unit_model.dart';
import '../../../core/features/notifications/application/notification_provider.dart';
import '../application/pos_provider.dart';
import 'package:utility_store_pos/features/pos/data/models/cart_item.dart';
import '../application/product_scanner.dart';
import 'widgets/invoice_dialog.dart';
import 'widgets/searchable_customer_dropdown.dart';
import 'widgets/uom_selector.dart';
import 'widgets/product_name_search.dart';
// Notifications moved to nav_shell.dart

class PosScreen extends StatefulWidget {
  static const routeName = '/pos';
  final bool isVisible;

  const PosScreen({super.key, this.isVisible = false});

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
      if (widget.isVisible) {
        _barcodeFocusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant PosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _barcodeFocusNode.requestFocus();
    }
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Side - Products/Scanning Panel
        Expanded(
          flex: 5,
          child: Column(
            children: [
              GlassHeader(
                title: 'Point of Sale',
                subtitle: 'Quick checkout & product scanning',
                actions: [
                  // Wholesale Toggle
                  Row(
                    children: [
                      Text('Wholesale', style: Theme.of(context).textTheme.bodySmall),
                      Switch(
                        value: pos.isWholesale,
                        onChanged: (v) => pos.setWholesaleMode(v),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      ModernCard(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 80,
                              child: CustomTextField(
                                label: 'Qty',
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
                                  final isUomEnabled = context.read<SettingsProvider>().enableUomSystem;
                                  
                                  final success = await pos.handleBarcode(
                                    barcode, 
                                    context.read<ProductRepository>(),
                                    isUomEnabled: isUomEnabled,
                                  );

                                  if (!success && mounted) {
                                    AppToast.show(
                                      context,
                                      title: 'Scan Error',
                                      message: pos.error ?? 'Product not found',
                                      type: ToastType.error,
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
                      const SizedBox(height: 12),
                      // Product Name Search
                      const ProductNameSearch(),
                      const SizedBox(height: 16),
                      // Robust Cart Header
                      if (pos.cartItems.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Row(
                            children: [
                              const SizedBox(width: 48), // Icon space
                              const SizedBox(width: 20),
                              Expanded(flex: 4, child: Text('PRODUCT', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold))),
                               Expanded(flex: 2, child: Text('PRICE', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold))),
                               if (context.read<SettingsProvider>().allowDiscounts)
                                  Expanded(flex: 2, child: Center(child: Text('DISC.', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold)))),
                               Expanded(flex: 3, child: Center(child: Text('QUANTITY', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold)))),
                               Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('TOTAL', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold)))),
                              const SizedBox(width: 48), // Action space
                            ],
                          ),
                        ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).dividerTheme.color?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: pos.cartItems.isEmpty
                              ? _EmptyCartState()
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: pos.cartItems.length,
                                    separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerTheme.color?.withOpacity(0.5)),
                                    itemBuilder: (context, index) {
                                      final item = pos.cartItems[index];
                                      return _ModernCartRow(item: item);
                                    },
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Right Side - The Cart Sidebar
        Container(
          width: 340,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Checkout Details', style: Theme.of(context).textTheme.titleLarge),
                        Icon(LucideIcons.shoppingCart, color: Theme.of(context).primaryColor, size: 24),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Customer', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
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
              const Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: _CheckoutSummary(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModernCartRow extends StatefulWidget {
  final CartItem item;

  const _ModernCartRow({required this.item});

  @override
  State<_ModernCartRow> createState() => _ModernCartRowState();
}

class _ModernCartRowState extends State<_ModernCartRow> {
  late TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController(text: _getDiscountText());
  }

  @override
  void didUpdateWidget(_ModernCartRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = _getDiscountText();
    if (_discountController.text != newText && !FocusScope.of(context).hasFocus) {
      _discountController.text = newText;
    }
  }

  String _getDiscountText() {
    final isPercent = context.read<SettingsProvider>().calculatePercentageDiscount;
    if (isPercent) {
      return widget.item.unitDiscountPercent > 0 ? widget.item.unitDiscountPercent.toStringAsFixed(1) : '';
    } else {
      return widget.item.unitDiscount > 0 ? widget.item.unitDiscount.toStringAsFixed(0) : '';
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.read<PosProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.package, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        widget.item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#${widget.item.productSku}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (widget.item.isUomItem && widget.item.productUnits.isNotEmpty)
                  AppUomSelector(
                    item: widget.item,
                    onSelected: (unit) => pos.changeItemUnit(widget.item.id, unit),
                  )
                else if (widget.item.variantName.isNotEmpty)
                  Text(
                    widget.item.variantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          // Price Info
          Expanded(
            flex: 2,
            child: Text(
              'Rs ${widget.item.unitPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          // Discount Input
          if (context.read<SettingsProvider>().allowDiscounts)
            Expanded(
              flex: 2,
              child: Center(
                child: SizedBox(
                  width: 70,
                  height: 40,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: '0',
                      prefixText: context.read<SettingsProvider>().calculatePercentageDiscount ? null : 'Rs ',
                      suffixText: context.read<SettingsProvider>().calculatePercentageDiscount ? '%' : null,
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    controller: _discountController,
                    onChanged: (v) {
                      final discount = double.tryParse(v) ?? 0.0;
                      pos.setItemDiscount(widget.item.variantId, discount);
                    },
                  ),
                ),
              ),
            ),
          // Quantity Controls
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QuantityButton(
                      icon: LucideIcons.minus,
                      onTap: () => pos.decrementQuantity(widget.item.variantId),
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        widget.item.quantity.toString(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _QuantityButton(
                      icon: LucideIcons.plus,
                      onTap: () {
                        pos.incrementQuantity(widget.item.variantId);
                        if (pos.error != null) {
                          AppToast.show(
                            context,
                            title: 'Stock Alert',
                            message: pos.error!,
                            type: ToastType.warning,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Total
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Rs ${widget.item.subtotal.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.grey, size: 18),
            onPressed: () => pos.removeFromCart(widget.item.variantId),
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove',
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

class _CheckoutSummary extends StatefulWidget {
  const _CheckoutSummary();

  @override
  State<_CheckoutSummary> createState() => _CheckoutSummaryState();
}

class _CheckoutSummaryState extends State<_CheckoutSummary> {
  late TextEditingController _billDiscountController;

  @override
  void initState() {
    super.initState();
    _billDiscountController = TextEditingController(text: _getBillDiscountText());
  }

  @override
  void didUpdateWidget(_CheckoutSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = _getBillDiscountText();
    // Only update the text if it's different and NOT focused
    if (_billDiscountController.text != newText && !FocusScope.of(context).hasFocus) {
      _billDiscountController.text = newText;
    }
  }

  String _getBillDiscountText() {
    final pos = context.read<PosProvider>();
    final isPercent = context.read<SettingsProvider>().calculatePercentageDiscount;
    if (isPercent) {
      return pos.billDiscountPercent > 0 ? pos.billDiscountPercent.toStringAsFixed(1) : '';
    } else {
      return pos.discountAmount > 0 ? pos.discountAmount.toStringAsFixed(2) : '';
    }
  }

  @override
  void dispose() {
    _billDiscountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text('Rs ${pos.subtotal.toStringAsFixed(2)}'),
            ],
          ),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              if (!settings.enableTaxSystem || pos.totalTaxAmount == 0) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(settings.taxInclusive ? 'Tax (Incl.)' : 'Tax (Excl.)'),
                      Text('Rs ${pos.totalTaxAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              );
            }
          ),
          if (context.read<SettingsProvider>().allowDiscounts) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bill Discount'),
                SizedBox(
                  width: 100,
                  height: 35,
                  child: TextField(
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: '0.00',
                      prefixText: context.read<SettingsProvider>().calculatePercentageDiscount ? null : 'Rs ',
                      suffixText: context.read<SettingsProvider>().calculatePercentageDiscount ? '%' : null,
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    controller: _billDiscountController,
                    onChanged: (v) {
                      final discount = double.tryParse(v) ?? 0.0;
                      pos.setDiscountAmount(discount);
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
              Text(
                'Rs ${pos.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Payment Method Selector
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return AppDropdown<String>(
                label: 'Payment Method',
                value: pos.paymentMethod,
                prefixIcon: LucideIcons.wallet,
                items: settings.paymentMethods.map((m) => AppDropdownItem<String>(
                  value: m,
                  label: m,
                  icon: m == 'CASH' ? LucideIcons.banknote : 
                        m == 'BANK' ? LucideIcons.landmark : 
                        m == 'JAZZCASH' ? LucideIcons.smartphone : LucideIcons.creditCard,
                )).toList(),
                onChanged: (v) {
                  if (v != null) pos.setPaymentMethod(v);
                },
              );
            }
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: pos.cartItems.isEmpty ? null : () async {
                double cashPaid = pos.totalAmount;
                double creditAmount = 0.0;
                DateTime? dueDate;

                if (pos.selectedCustomer != null) {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => _SplitPaymentDialog(total: pos.totalAmount),
                  );
                  if (result == null) return;
                  cashPaid = result['cash']!;
                  creditAmount = result['credit']!;
                  dueDate = result['dueDate'] as DateTime?;
                }

                // Copy cart items before processing because processCheckout clears them
                final itemsSnapshot = List<CartItem>.from(pos.cartItems);
                
                await pos.processCheckout(
                  cashPaid: cashPaid,
                  creditAmount: creditAmount,
                  dueDate: dueDate,
                  onSuccess: (savedTx) {
                    // Proactive refreshes to make the system "smart"
                    context.read<AnalyticsProvider>().refreshData();
                    context.read<TransactionsProvider>().loadTransactions();
                    context.read<StockProvider>().loadMovements();
                    context.read<NotificationProvider>().checkLowStock();
                    context.read<InventoryProvider>().loadCategories();
                    context.read<InventoryProvider>().loadProducts(); // Fresh stock in product list
                    context.read<CustomersProvider>().loadCustomers(); // Refresh customer credit/ledger

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
                      AppToast.show(
                        context,
                        title: 'Checkout Failed',
                        message: e.toString(),
                        type: ToastType.error,
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
  DateTime? _dueDate;

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
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get customer credit if a customer is attached
    final pos = context.read<PosProvider>();
    final customer = pos.selectedCustomer;
    final double? customerCredit = customer is Customer ? customer.currentCredit : null;

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
          // Show customer credit if a customer is attached
          if (customerCredit != null && customerCredit > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.DANGER.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.DANGER.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Customer Credit Due:', style: TextStyle(fontSize: 12)),
                  Text(
                    'Rs ${customerCredit.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.DANGER,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          if (_creditAmount > 0) ...[
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.calendar),
              title: const Text('Credit Due Date'),
              subtitle: Text(_dueDate == null ? 'Select Date' : DateFormat('dd MMM, yyyy').format(_dueDate!)),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _dueDate = date);
                }
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final cash = double.tryParse(_cashController.text) ?? 0.0;
            Navigator.pop(context, {
              'cash': cash, 
              'credit': _creditAmount,
              'dueDate': _dueDate,
            });
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Icon(
                LucideIcons.shoppingCart, 
                size: 60, 
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Cart is Ready',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 300,
              child: Text(
                'Start scanning products or enter barcodes to build your customer\'s order.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Icon(LucideIcons.info, size: 14, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Awaiting entries...',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
