import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pasteboard/pasteboard.dart';

import '../../../settings/application/settings_provider.dart';
import '../../../../core/models/entities.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/toast_notification.dart';
import '../../../../core/repositories/customer_repository.dart';
import '../../application/pos_provider.dart';
import 'package:utility_store_pos/features/pos/data/models/cart_item.dart';
import '../../../../core/services/receipt_printer.dart';

class InvoiceDialog extends StatefulWidget {
  final Transaction transaction;
  final List<CartItem> cartItems;

  const InvoiceDialog({
    super.key,
    required this.transaction,
    required this.cartItems,
  });

  @override
  State<InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<InvoiceDialog> {
  final _currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
  bool _isPrinting = false;
  bool _isSharing = false;
  final ScreenshotController _screenshotController = ScreenshotController();
  Customer? _customer;

  @override
  void initState() {
    super.initState();
    _fetchCustomer();
  }

  Future<void> _fetchCustomer() async {
    if (widget.transaction.customerId != null) {
      try {
        final repo = context.read<CustomerRepository>();
        final customers = await repo.getAll();
        final match = customers.where((c) => c.id == widget.transaction.customerId).toList();
        if (match.isNotEmpty) {
          setState(() => _customer = match.first);
        }
      } catch (e) {
        debugPrint('Error fetching customer for invoice: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.checkCircle, size: 48, color: Color(0xFF4CAF50)),
                  const SizedBox(height: 16),
                  Text(
                    'Checkout Successful',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invoice #${widget.transaction.invoiceNumber}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Receipt Preview
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Screenshot(
                      controller: _screenshotController,
                      child: _buildReceiptDetails(context),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Column(
                children: [
                   Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isPrinting ? null : _handlePrint,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: _isPrinting 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(LucideIcons.printer),
                          label: const Text('Print Receipt'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSharing ? null : _handleWhatsAppShare,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                            foregroundColor: Colors.white,
                          ),
                          icon: _isSharing 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(LucideIcons.messageCircle),
                          label: const Text('WhatsApp Share'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _isSharing ? null : _handleShareReceipt,
                          icon: const Icon(LucideIcons.share2, size: 18),
                          label: const Text('Other Share'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptDetails(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => Column(
              children: [
                if (settings.storeLogo != null || settings.storeLogoPath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(child: _buildLogoPreview(settings)),
                  ),
                Center(
                  child: Text(
                    settings.storeName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    settings.storeAddress,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(fontSize: 12),
                  ),
                ),
                Center(
                  child: Text(
                    'PH: ${settings.storePhone}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'STORE RECEIPT',
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildReceiptRow('Date', DateFormat('MM/dd/yyyy HH:mm').format(widget.transaction.createdAt)),
          if (widget.transaction.customerId != null)
             _buildReceiptRow('Customer ID', widget.transaction.customerId!),
          _buildReceiptRow('Payment Method', widget.transaction.paymentMethod),
          _buildReceiptRow('Status', widget.transaction.paymentStatus),
          const Divider(height: 32),
          
          ...widget.cartItems.map((CartItem item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'SKU: ${item.productSku}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _currencyFormat.format(item.subtotal),
                            style: GoogleFonts.spaceMono(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.unitName ?? item.variantName,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item.quantity} x ${_currencyFormat.format(item.unitPrice)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontFamily: GoogleFonts.spaceMono().fontFamily,
                            ),
                          ),
                        ],
                      ),
                      if (item.unitDiscount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 2),
                          child: Text(
                            'Discount: ${item.unitDiscountPercent.toStringAsFixed(1)}% (-${_currencyFormat.format(item.totalDiscount)})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.SUCCESS,
                              fontSize: 9,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (item.taxAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 2),
                          child: Text(
                            'Tax (${item.taxRate.toStringAsFixed(1)}%): +${_currencyFormat.format(item.taxAmount)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade700,
                              fontSize: 9,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )),

          const Divider(height: 32),
          
          _buildTotalRow('Gross Total', widget.transaction.totalAmount),
          if (widget.transaction.tax > 0)
            _buildTotalRow(
              widget.transaction.isTaxInclusive ? 'Tax (Inclusive)' : 'Tax (Exclusive)', 
              widget.transaction.tax
            ),
          if (widget.transaction.discount > 0)
            _buildTotalRow(
               'Total Discount (${widget.transaction.discountPercent.toStringAsFixed(1)}%)', 
               -widget.transaction.discount
            ),
            
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                _currencyFormat.format(widget.transaction.finalAmount),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (widget.transaction.discount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.SUCCESS.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  'YOU SAVED: ${_currencyFormat.format(widget.transaction.discount)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.SUCCESS,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
          if (widget.transaction.creditAmount > 0) ...[
            const Divider(height: 32),
            _buildTotalRow('Paid in Cash', widget.transaction.cashPaid),
            _buildTotalRow('Remaining Credit', widget.transaction.creditAmount),
          ],
          const Divider(height: 32),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => Center(
              child: Text(
                settings.receiptCustomMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPreview(SettingsProvider settings) {
    try {
      Widget? logoImage;
      
      // 1. Try file-based logo
      if (settings.storeLogoPath != null) {
        final file = File(settings.storeLogoPath!);
        if (file.existsSync()) {
          final isSvg = settings.storeLogoPath!.toLowerCase().endsWith('.svg');
          logoImage = isSvg 
              ? SvgPicture.file(file, fit: BoxFit.contain)
              : Image.file(file, fit: BoxFit.contain);
        }
      }
      
      // 2. Fallback to base64 if no file
      if (logoImage == null && settings.storeLogo != null && settings.storeLogo!.isNotEmpty) {
        final base64 = settings.storeLogo!;
        final bytes = base64.contains(',') ? base64Decode(base64.split(',').last) : base64Decode(base64);
        final isSvg = base64.contains('/svg') || (base64.length > 20 && utf8.decode(bytes.take(20).toList(), allowMalformed: true).contains('<svg'));
        logoImage = isSvg ? SvgPicture.memory(bytes, fit: BoxFit.contain) : Image.memory(bytes, fit: BoxFit.contain);
      }

      if (logoImage != null) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 110),
            child: logoImage,
          ),
        );
      }

      return const SizedBox.shrink();
    } catch (e) {
      debugPrint('Error building logo preview: $e');
      return const SizedBox.shrink();
    }
  }



  Widget _buildReceiptRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(_currencyFormat.format(amount)),
        ],
      ),
    );
  }

  // Generate PDF Document
  Future<Uint8List> _generatePdf() async {
    final settings = context.read<SettingsProvider>();
    
    // Use the centralized ReceiptPrinter to ensure branding consistency (massive logo, no text if logo present)
    return await ReceiptPrinter.generateReceiptPdf(
      transaction: widget.transaction,
      cartItems: widget.cartItems,
      settings: settings,
    );
  }

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    try {
      final pdfBytes = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Invoice_${widget.transaction.invoiceNumber}',
      );
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context, 
          title: 'Print Failed', 
          message: 'Error: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  Future<void> _handleWhatsAppShare() async {
    setState(() => _isSharing = true);
    try {
      // 1. Capture the receipt as a high-quality image
      final Uint8List? image = await _screenshotController.capture(
        pixelRatio: 2.0, // High definition
      );
      
      if (image == null) throw Exception('Failed to capture receipt image');

      // 2. Copy image to clipboard
      await Pasteboard.writeImage(image);

      // 3. Launch WhatsApp
      final phone = _customer?.whatsappNumber ?? _customer?.phone;
      final invoice = widget.transaction.invoiceNumber;
      final total = _currencyFormat.format(widget.transaction.finalAmount);
      
      final message = 'Receipt for Invoice #$invoice\nTotal: $total\n(Image copied to clipboard. Press Ctrl+V to paste)';
      
      final cleanPhone = phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
      final appUrl = 'whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}';
      final webUrl = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}';

      if (await canLaunchUrl(Uri.parse(appUrl))) {
        await launchUrl(Uri.parse(appUrl));
      } else {
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        AppToast.show(
          context, 
          title: 'Receipt Copied!', 
          message: 'Image is in clipboard. Press Ctrl+V in WhatsApp to send.',
          type: ToastType.success,
        );
        // Optional: close dialog after success like companion app
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context, 
          title: 'Share Failed', 
          message: e.toString(),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _handleShareReceipt() async {
    setState(() => _isSharing = true);
    try {
      final pdfBytes = await _generatePdf();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Receipt_${widget.transaction.invoiceNumber}.pdf');
      await file.writeAsBytes(pdfBytes);

      // Open System Share Dialog
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Store Receipt - Invoice #${widget.transaction.invoiceNumber}',
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context, 
          title: 'Share Failed', 
          message: e.toString(),
          type: ToastType.warning,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
}
