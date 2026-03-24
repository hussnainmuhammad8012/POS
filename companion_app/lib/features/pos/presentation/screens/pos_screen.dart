import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/pos_provider.dart';
import '../../application/pos_pdf_service.dart';
import '../widgets/pos_scanner_page.dart';
import '../widgets/confirm_payment_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final PosPdfService _pdfService = PosPdfService();
  Offset? _fabPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosProvider>().fetchPaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.STAR_BACKGROUND,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mobile POS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(pos.isWholesale ? 'WHOLESALE MODE' : 'RETAIL MODE', 
                style: const TextStyle(fontSize: 10, color: AppColors.STAR_PRIMARY)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppColors.DANGER),
              onPressed: () => pos.clearCart(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Top Controls: Mode, Bulk Qty, Customer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.STAR_CARD,
                  border: const Border(bottom: BorderSide(color: AppColors.STAR_BORDER)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.STAR_BACKGROUND,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.STAR_BORDER),
                            ),
                            child: Row(
                              children: [
                                const Text('Qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: '1'),
                                    onChanged: (v) => pos.setBulkQuantity(int.tryParse(v) ?? 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildWholesaleButton(pos),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCustomerField(context, pos),
                  ],
                ),
              ),
            Expanded(
              child: pos.cartItems.isEmpty 
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pos.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = pos.cartItems[index];
                      return _buildCartItem(context, item, pos);
                    },
                  ),
            ),

            // Summary Panel
            _buildSummaryPanel(context, pos),
              ],
            ),
            Positioned(
              left: _fabPosition?.dx ?? (MediaQuery.of(context).size.width - 80),
              top: _fabPosition?.dy ?? (MediaQuery.of(context).size.height - 250),
              child: Draggable(
                feedback: _buildScannerFab(context, pos, isFeedback: true),
                childWhenDragging: Container(),
                onDragEnd: (details) {
                  setState(() {
                    _fabPosition = details.offset;
                    final size = MediaQuery.of(context).size;
                    double x = _fabPosition!.dx.clamp(0.0, size.width - 60);
                    double y = _fabPosition!.dy.clamp(0.0, size.height - 180);
                    _fabPosition = Offset(x, y);
                  });
                },
                child: _buildScannerFab(context, pos),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerFab(BuildContext context, PosProvider pos, {bool isFeedback = false}) {
    return FloatingActionButton(
      onPressed: isFeedback ? null : () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PosScannerPage(
            onScan: (code) async {
              final result = await pos.addToCartByBarcode(code);
              if (!context.mounted) return;
              
              String message = '';
              Color color = Colors.black87;
              
              switch (result) {
                case 'SUCCESS':
                  message = 'Item added to cart';
                  color = Colors.green;
                  break;
                case 'RE_SYNCED':
                  message = 'Server Connection Refreshed!';
                  color = Colors.blue;
                  break;
                case 'AUTH_ERROR':
                  message = 'Session Expired! Please re-scan Server QR.';
                  color = Colors.orange;
                  break;
                case 'INVALID_SYNC_QR':
                  message = 'Invalid Sync QR Code';
                  color = Colors.red;
                  break;
                default:
                  message = pos.error ?? 'Product not found';
                  color = Colors.red;
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message, style: const TextStyle(color: Colors.white)),
                  backgroundColor: color,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ),
      backgroundColor: isFeedback ? AppColors.STAR_PRIMARY.withOpacity(0.5) : AppColors.STAR_PRIMARY,
      elevation: isFeedback ? 8 : 4,
      child: const Icon(LucideIcons.scanLine, color: Colors.white),
    );
  }



  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.shoppingCart, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Your cart is empty', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, PosProvider pos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.STAR_CARD,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.STAR_BORDER),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('SKU: ${item.productSku} | ${item.variantName}', 
                      style: const TextStyle(fontSize: 12, color: AppColors.STAR_TEXT_SECONDARY)),
                    const SizedBox(height: 8),
                    Text('Rs ${item.unitPrice.toStringAsFixed(2)}', 
                      style: const TextStyle(color: AppColors.STAR_PRIMARY, fontWeight: FontWeight.bold)),
                    if (item.productUnits.length > 1) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: item.productUnits.map((u) {
                            final isSelected = item.unitId == u.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(u.unitName, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : null)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) pos.changeItemUnit(item.id, u);
                                },
                                selectedColor: AppColors.STAR_PRIMARY,
                                padding: EdgeInsets.zero,
                                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(onPressed: () => pos.updateQuantity(item.id, -1), icon: const Icon(LucideIcons.minusCircle, size: 20)),
                  Container(
                    width: 40,
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: '${item.quantity}')..selection = TextSelection.collapsed(offset: '${item.quantity}'.length),
                      onSubmitted: (v) {
                        int? val = int.tryParse(v);
                        if (val != null) {
                           pos.updateQuantity(item.id, val - item.quantity);
                        }
                      },
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    ),
                  ),
                  IconButton(onPressed: () => pos.updateQuantity(item.id, 1), icon: const Icon(LucideIcons.plusCircle, size: 20, color: AppColors.STAR_PRIMARY)),
                ],
              ),
            ],
          ),
          if (pos.allowDiscounts) ...[
            const Divider(height: 16),
            Row(
              children: [
                const Icon(LucideIcons.tag, size: 14, color: AppColors.STAR_TEXT_SECONDARY),
                const SizedBox(width: 8),
                const Text('Discount/item', style: TextStyle(fontSize: 12, color: AppColors.STAR_TEXT_SECONDARY)),
                const Spacer(),
                Container(
                  width: 80,
                  height: 30,
                  child: TextField(
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: item.unitDiscount > 0 
                        ? (pos.calculatePercentageDiscount ? (item.unitDiscount / item.unitPrice * 100).toStringAsFixed(1) : item.unitDiscount.toStringAsFixed(2)) 
                        : ''
                    )..selection = TextSelection.collapsed(
                      offset: (item.unitDiscount > 0 
                        ? (pos.calculatePercentageDiscount ? (item.unitDiscount / item.unitPrice * 100).toStringAsFixed(1) : item.unitDiscount.toStringAsFixed(2)) 
                        : '').length
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: AppColors.STAR_BACKGROUND,
                    ),
                    onSubmitted: (v) {
                      double? val = double.tryParse(v);
                      if (val != null) {
                        pos.setItemDiscount(item.id, val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryPanel(BuildContext context, PosProvider pos) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.STAR_CARD,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', 'Rs ${pos.subtotal.toStringAsFixed(2)}'),
          if (pos.enableTax)
            _summaryRow('Tax', 'Rs ${pos.totalTax.toStringAsFixed(2)}'),
          if (pos.allowDiscounts)
            _summaryRow('Discount', 'Rs ${pos.totalDiscount.toStringAsFixed(2)}', isNegative: true),
          const Divider(height: 16),
          _summaryRow('Total', 'Rs ${pos.total.toStringAsFixed(2)}', isStrong: true),
          if (pos.allowDiscounts) ...[
            const SizedBox(height: 8),
            _buildDiscountField(pos),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: pos.cartItems.isEmpty ? null : () => _handleCheckout(context, pos),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: AppColors.STAR_PRIMARY,
              ),
              child: pos.isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('PROCEED TO PAYMENT', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountField(PosProvider pos) {
    return Row(
      children: [
        const Icon(LucideIcons.ticket, size: 16, color: AppColors.STAR_TEXT_SECONDARY),
        const SizedBox(width: 8),
        const Text('Bill Discount', style: TextStyle(fontSize: 13, color: AppColors.STAR_TEXT_SECONDARY)),
        const Spacer(),
        SizedBox(
          width: 80,
          height: 35,
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              hintText: '0.00',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (val) => pos.setBillDiscount(double.tryParse(val) ?? 0),
          ),
        ),
      ],
    );
  }

  Widget _buildWholesaleButton(PosProvider pos) {
    return InkWell(
      onTap: () => pos.toggleWholesale(!pos.isWholesale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: pos.isWholesale ? AppColors.STAR_PRIMARY.withOpacity(0.1) : AppColors.STAR_BACKGROUND,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pos.isWholesale ? AppColors.STAR_PRIMARY : AppColors.STAR_BORDER),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.tag, size: 16, color: pos.isWholesale ? AppColors.STAR_PRIMARY : Colors.grey),
            const SizedBox(width: 8),
            Text('WHOLESALE', style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.bold,
              color: pos.isWholesale ? AppColors.STAR_PRIMARY : Colors.grey,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerField(BuildContext context, PosProvider pos) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.STAR_BACKGROUND,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.STAR_BORDER),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.user, size: 20, color: AppColors.STAR_PRIMARY),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pos.selectedCustomer?['name'] ?? 'Walk-in Customer',
              style: TextStyle(
                color: pos.selectedCustomer == null ? Colors.grey : AppColors.STAR_TEXT,
                fontWeight: pos.selectedCustomer == null ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(pos.selectedCustomer == null ? LucideIcons.userPlus : LucideIcons.xCircle, size: 20),
            onPressed: () {
              if (pos.selectedCustomer != null) {
                pos.setCustomer(null);
              } else {
                 _showCustomerSelection(context, pos);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCustomerSelection(BuildContext context, PosProvider pos) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('Select Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: pos.customers.length,
                  itemBuilder: (context, index) {
                    final customer = pos.customers[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(LucideIcons.user)),
                      title: Text(customer['name']),
                      subtitle: Text(customer['phone'] ?? ''),
                      onTap: () {
                        pos.setCustomer(customer);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleCheckout(BuildContext context, PosProvider pos) async {
    final paymentData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ConfirmPaymentDialog(
        total: pos.total,
        customer: pos.selectedCustomer,
        paymentMethods: pos.paymentMethodsList,
      ),
    );

    if (paymentData == null) return;

    final result = await pos.checkout(
      cashPaid: paymentData['cashPaid'],
      creditAmount: paymentData['creditAmount'],
      dueDate: paymentData['dueDate'],
      paymentMethod: paymentData['paymentMethod'],
    );

    if (result != null) {
      if (context.mounted) {
        _showReceiptDialog(context, pos, result);
      }
    } else if (pos.error != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pos.error!), backgroundColor: AppColors.DANGER),
        );
      }
    }
  }

  void _showReceiptDialog(BuildContext context, PosProvider pos, Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Text('Sale Completed!')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.checkCircle, color: AppColors.SUCCESS, size: 60),
            const SizedBox(height: 16),
            Text('Invoice: ${result['invoice']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _receiptActionButton(
                  icon: LucideIcons.printer, 
                  label: 'Remote Print',
                  onTap: () {
                    pos.printReceipt(result);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print request sent to Desktop')));
                  },
                ),
                _receiptActionButton(
                  icon: LucideIcons.share2, 
                  label: 'Share PDF',
                  onTap: () async {
                    try {
                      final pdfFile = await _pdfService.generateReceiptPdf(result);
                      await Share.shareXFiles([XFile(pdfFile.path)], text: 'Receipt ${result['invoice']}');
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF Error: $e')));
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NEW SALE'),
          ),
        ],
      ),
    );
  }

  Widget _receiptActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.STAR_PRIMARY.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.STAR_PRIMARY),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isStrong = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isStrong ? 16 : 13,
            fontWeight: isStrong ? FontWeight.bold : FontWeight.normal,
          )),
          Text(value, style: TextStyle(
            fontSize: isStrong ? 18 : 13,
            fontWeight: isStrong ? FontWeight.bold : FontWeight.w600,
            color: isNegative ? AppColors.DANGER : (isStrong ? AppColors.STAR_PRIMARY : null),
          )),
        ],
      ),
    );
  }
}
