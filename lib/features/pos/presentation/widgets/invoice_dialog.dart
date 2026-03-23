import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
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
import '../../application/pos_provider.dart';
import 'package:utility_store_pos/features/pos/data/models/cart_item.dart';

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
              child: Row(
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
                      onPressed: _isSharing ? null : _handleShareWhatsApp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                        foregroundColor: Colors.white,
                      ),
                      icon: _isSharing 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.messageCircle),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('No Receipt'),
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
    final pdf = pw.Document();
    final settings = context.read<SettingsProvider>();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Thermal printer 80mm roll standard
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(settings.storeName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ),
              pw.Center(
                child: pw.Text(settings.storeAddress, style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Center(
                child: pw.Text('PH: ${settings.storePhone}', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('STORE RECEIPT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('#${widget.transaction.invoiceNumber}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Date:', style: const pw.TextStyle(fontSize: 10)),
                   pw.Text(DateFormat('MM/dd/yyyy HH:mm').format(widget.transaction.createdAt), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (widget.transaction.customerId != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Customer ID:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(widget.transaction.customerId!, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Payment Method:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(widget.transaction.paymentMethod, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Status:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(widget.transaction.paymentStatus, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              ...widget.cartItems.map((CartItem item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(item.productName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                pw.Text('[${item.productSku}]', style: const pw.TextStyle(fontSize: 7)),
                              ],
                            ),
                          ),
                          pw.Text(_currencyFormat.format(item.subtotal), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Text(
                        '  ${item.quantity} ${item.unitName ?? item.variantName} x ${_currencyFormat.format(item.unitPrice)}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      if (item.unitDiscount > 0)
                        pw.Text(
                          '  Discount: ${item.unitDiscountPercent.toStringAsFixed(1)}% (-${_currencyFormat.format(item.totalDiscount)})',
                          style: pw.TextStyle(fontSize: 7, color: PdfColors.green),
                        ),
                      if (item.taxAmount > 0)
                        pw.Text(
                          '  Tax (${item.taxRate.toStringAsFixed(1)}%): +${_currencyFormat.format(item.taxAmount)}',
                          style: pw.TextStyle(fontSize: 7, color: PdfColors.orange),
                        ),
                    ],
                  ),
                );
              }),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Gross Total:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(_currencyFormat.format(widget.transaction.totalAmount), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (widget.transaction.tax > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      widget.transaction.isTaxInclusive ? 'Tax (Incl.):' : 'Tax (Excl.):', 
                      style: const pw.TextStyle(fontSize: 10)
                    ),
                    pw.Text(_currencyFormat.format(widget.transaction.tax), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              if (widget.transaction.discount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Discount (${widget.transaction.discountPercent.toStringAsFixed(1)}%):', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(_currencyFormat.format(-widget.transaction.discount), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
               if (widget.transaction.discount > 0) ...[
                pw.SizedBox(height: 5),
                 pw.Center(
                  child: pw.Text('YOU SAVED: ${_currencyFormat.format(widget.transaction.discount)}', 
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                ),
              ],
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_currencyFormat.format(widget.transaction.finalAmount), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              if (widget.transaction.creditAmount > 0) ...[
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Cash Paid:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(_currencyFormat.format(widget.transaction.cashPaid), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Remaining Credit:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(_currencyFormat.format(widget.transaction.creditAmount), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(settings.receiptCustomMessage.isNotEmpty ? settings.receiptCustomMessage : 'Thank you for shopping!', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
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

  Future<void> _handleShareWhatsApp() async {
    setState(() => _isSharing = true);
    try {
      // Capture the receipt details as an image
      final imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0, 
      );
      
      if (imageBytes == null) throw Exception('Failed to generate receipt image.');

      // WhatsApp Desktop doesn't support direct image attachments via URL.
      // So we copy the image to the clipboard, and open WhatsApp directly. 
      // The user just has to press Ctrl+V to paste the image.
      await Pasteboard.writeImage(imageBytes);

      // Close the receipt dialog immediately after capturing
      if (mounted) {
        Navigator.pop(context);
      }

      // Open WhatsApp directly using the protocol
      final encodedMessage = Uri.encodeComponent(
        'Here is today\'s purchase slip.'
      );
      
      final uri = Uri.parse('whatsapp://send?text=$encodedMessage');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        
        if (mounted) {
           AppToast.show(
             context, 
             title: 'Copied to Clipboard!', 
             message: 'Press Ctrl+V in WhatsApp to paste the receipt.',
             type: ToastType.success,
           );
        }
      } else {
        // Fallback to web WhatsApp specifically
        final webUri = Uri.parse('https://wa.me/?text=$encodedMessage');
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri);
          if (mounted) {
             AppToast.show(
               context, 
               title: 'Copied to Clipboard!', 
               message: 'Press Ctrl+V in WhatsApp to paste the receipt.',
               type: ToastType.success,
             );
          }
        } else {
          // If all else fails, fallback to native share sheet as a backup
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/receipt_${widget.transaction.invoiceNumber}.png');
          await file.writeAsBytes(imageBytes);
          await Share.shareXFiles(
            [XFile(file.path)],
            text: 'Store Receipt - Invoice #${widget.transaction.invoiceNumber}',
          );
        }
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
