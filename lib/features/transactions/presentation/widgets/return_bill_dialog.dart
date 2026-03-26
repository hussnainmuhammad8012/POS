import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/entities.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/transactions_provider.dart';
import '../../../inventory/application/inventory_provider.dart';
import '../../../inventory/application/stock_provider.dart';

class ReturnBillDialog extends StatefulWidget {
  final Transaction transaction;

  const ReturnBillDialog({super.key, required this.transaction});

  @override
  State<ReturnBillDialog> createState() => _ReturnBillDialogState();
}

class _ReturnBillDialogState extends State<ReturnBillDialog> {
  final Map<String, int> _quantitiesToReturn = {};
  List<Map<String, Object?>> _items = [];
  bool _isLoading = true;
  double _calculatedRefund = 0.0;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await context.read<TransactionsProvider>().getTransactionItems(widget.transaction.id!);
    setState(() {
      _items = items;
      _isLoading = false;
      for (final item in _items) {
        final variantId = item['product_variant_id'] as String;
        _quantitiesToReturn[variantId] = 0;
      }
    });
  }

  void _calculateRefund() {
    double total = 0.0;
    for (final item in _items) {
      final variantId = item['product_variant_id'] as String;
      final returnQty = _quantitiesToReturn[variantId] ?? 0;
      
      if (returnQty > 0) {
          final priceAtTime = (item['price_at_time'] as num).toDouble();
          final discount = (item['item_discount'] as num?)?.toDouble() ?? 0.0;
          final taxAmount = (item['tax_amount'] as num?)?.toDouble() ?? 0.0;
          final originalQty = (item['quantity'] as num).toInt();

          final double itemNetValue = ((priceAtTime * originalQty) - discount + taxAmount);
          final double valuePerItem = itemNetValue / originalQty;

          total += valuePerItem * returnQty;
      }
    }
    setState(() {
      _calculatedRefund = total;
    });
  }

  void _returnAll() {
    for (final item in _items) {
      final variantId = item['product_variant_id'] as String;
      final originalQty = (item['quantity'] as num).toInt();
      final returnedQty = (item['returned_quantity'] as num?)?.toInt() ?? 0;
      _quantitiesToReturn[variantId] = originalQty - returnedQty;
    }
    _calculateRefund();
  }

  Future<void> _processReturn() async {
    if (_calculatedRefund <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select items to return.')),
      );
      return;
    }

    try {
      await context.read<TransactionsProvider>().processReturn(
        transaction: widget.transaction,
        items: _items,
        quantitiesToReturn: _quantitiesToReturn,
      );
      if (mounted) {
        try {
          // Immediately reload the inventory and stock movements to reflect the return globally
          context.read<InventoryProvider>().loadProducts();
          context.read<StockProvider>().loadMovements();
        } catch (_) {}
        Navigator.pop(context, true); // Success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error processing return: $e'), backgroundColor: AppColors.DANGER),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Return Items', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: _returnAll,
                  child: const Text('Return All Eligible'),
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final variantId = item['product_variant_id'] as String;
                  final productName = item['product_name'] as String? ?? 'Unknown Product';
                  final originalQty = (item['quantity'] as num).toInt();
                  final returnedQty = (item['returned_quantity'] as num?)?.toInt() ?? 0;
                  final maxReturnable = originalQty - returnedQty;
                  final currentlyReturning = _quantitiesToReturn[variantId] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (returnedQty > 0)
                                Text('Already Returned: $returnedQty', style: TextStyle(color: AppColors.DANGER, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (maxReturnable == 0)
                          const Text('Fully Returned', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                        else
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: currentlyReturning > 0
                                    ? () {
                                        setState(() {
                                          _quantitiesToReturn[variantId] = currentlyReturning - 1;
                                        });
                                        _calculateRefund();
                                      }
                                    : null,
                              ),
                              SizedBox(
                                width: 30,
                                child: Text('$currentlyReturning', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: currentlyReturning < maxReturnable
                                    ? () {
                                        setState(() {
                                          _quantitiesToReturn[variantId] = currentlyReturning + 1;
                                        });
                                        _calculateRefund();
                                      }
                                    : null,
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Est. Refund Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                Text(
                  currencyFormat.format(_calculatedRefund),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.DANGER),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _calculatedRefund > 0 ? _processReturn : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.DANGER,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('Confirm Return', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
