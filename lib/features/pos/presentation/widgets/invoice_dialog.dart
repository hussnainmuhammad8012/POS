import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/entities.dart';
import '../../application/pos_provider.dart';

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
  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  bool _isPrinting = false;
  bool _isSharing = false;

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
                    _buildReceiptDetails(context),
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
                      label: const Text('Share WhatsApp'),
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
          _buildReceiptRow('Payment Method', widget.transaction.paymentMethod),
          const Divider(height: 32),
          
          ...widget.cartItems.map((CartItem item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.productName} ${item.variantName.isNotEmpty ? "(${item.variantName})" : ""}'),
                      Text(
                        '${item.quantity} x ${_currencyFormat.format(item.unitPrice)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                Text(_currencyFormat.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),

          const Divider(height: 32),
          
          _buildTotalRow('Subtotal', widget.transaction.totalAmount),
          if (widget.transaction.tax > 0)
            _buildTotalRow('Tax', widget.transaction.tax),
          if (widget.transaction.discount > 0)
            _buildTotalRow('Discount', -widget.transaction.discount),
            
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Thermal printer 80mm roll standard
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text('STORE RECEIPT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Invoice: ${widget.transaction.invoiceNumber}'),
              pw.Text('Date: ${DateFormat('MM/dd/yyyy HH:mm').format(widget.transaction.createdAt)}'),
              pw.SizedBox(height: 10),
              pw.Divider(),
              ...widget.cartItems.map((CartItem item) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${item.productName} x${item.quantity}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Text(
                        _currencyFormat.format(item.subtotal),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              }),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(_currencyFormat.format(widget.transaction.totalAmount), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (widget.transaction.tax > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(_currencyFormat.format(widget.transaction.tax), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              if (widget.transaction.discount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(_currencyFormat.format(-widget.transaction.discount), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_currencyFormat.format(widget.transaction.finalAmount), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Thank you for shopping!', style: const pw.TextStyle(fontSize: 10)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
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
      final sb = StringBuffer();
      sb.writeln('*STORE RECEIPT*');
      sb.writeln('Invoice: ${widget.transaction.invoiceNumber}');
      sb.writeln('Date: ${DateFormat('MM/dd/yyyy HH:mm').format(widget.transaction.createdAt)}');
      sb.writeln('------------------------');
      
      for (var item in widget.cartItems) {
        sb.writeln('${item.productName} x${item.quantity} - ${_currencyFormat.format(item.subtotal)}');
      }
      
      sb.writeln('------------------------');
      sb.writeln('*TOTAL: ${_currencyFormat.format(widget.transaction.finalAmount)}*');
      sb.writeln('');
      sb.writeln('Thank you for your purchase!');

      final encodedMessage = Uri.encodeComponent(sb.toString());
      
      // Try launching WhatsApp protocol
      final uri = Uri.parse('whatsapp://send?text=$encodedMessage');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to web WhatsApp specifically
        final webUri = Uri.parse('https://wa.me/?text=$encodedMessage');
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri);
        } else {
          throw Exception('WhatsApp not installed and unable to open web browser.');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share to WhatsApp. Ensure the desktop app is installed.'),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
}
