import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart' hide Column, Row, Center, Container, SizedBox, Divider, Padding, Expanded, EdgeInsets, Alignment, FontWeight, FontStyle, TextStyle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../features/settings/application/settings_provider.dart';
import '../../core/models/entities.dart';
import '../../features/pos/data/models/cart_item.dart';

class ReceiptPrinter {
  static final _currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

  static Future<void> printReceipt({
    required Transaction transaction,
    required List<CartItem> cartItems,
    required SettingsProvider settings,
  }) async {
    try {
      final pdfBytes = await generateReceiptPdf(
        transaction: transaction,
        cartItems: cartItems,
        settings: settings,
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Invoice_${transaction.invoiceNumber}',
      );
    } catch (e) {
      debugPrint('ReceiptPrinter Error: $e');
    }
  }

  static Future<Uint8List> generateReceiptPdf({
    required Transaction transaction,
    required List<CartItem> cartItems,
    required SettingsProvider settings,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildPdfHeader(settings),
              pw.SizedBox(height: 10),
              _buildPdfInfo(transaction),
              pw.SizedBox(height: 10),
              pw.Divider(),
              ...cartItems.map((item) => _buildPdfItemRow(item)),
              pw.Divider(),
              _buildPdfTotals(transaction, settings),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  settings.receiptCustomMessage.isNotEmpty ? settings.receiptCustomMessage : 'Thank you for shopping!', 
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfHeader(SettingsProvider settings) {
    bool hasLogo = false;
    
    // Rigorous check for logo existence
    if (settings.storeLogoPath != null && settings.storeLogoPath!.trim().isNotEmpty) {
      if (File(settings.storeLogoPath!).existsSync()) {
        hasLogo = true;
      }
    }
    
    if (!hasLogo && settings.storeLogo != null && settings.storeLogo!.trim().isNotEmpty) {
      hasLogo = true;
    }

    return pw.Column(
      children: [
        _buildPdfLogo(settings),
        if (!hasLogo) ...[
          pw.Center(
            child: pw.Text(settings.storeName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          ),
          pw.Center(
            child: pw.Text(settings.storeAddress, style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.Center(
            child: pw.Text('PH: ${settings.storePhone}', style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text('STORE RECEIPT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfLogo(SettingsProvider settings) {
    try {
      Uint8List? bytes;
      bool isSvg = false;

      if (settings.storeLogoPath != null) {
        final file = File(settings.storeLogoPath!);
        if (file.existsSync()) {
          bytes = file.readAsBytesSync();
          isSvg = settings.storeLogoPath!.toLowerCase().endsWith('.svg');
        }
      } else if (settings.storeLogo != null) {
        final base64 = settings.storeLogo!;
        final decodedBytes = base64.contains(',') ? base64Decode(base64.split(',').last) : base64Decode(base64);
        bytes = decodedBytes;
        isSvg = base64.contains('/svg') || (decodedBytes.length > 20 && utf8.decode(decodedBytes.take(20).toList(), allowMalformed: true).contains('<svg'));
      }

      if (bytes == null || bytes.isEmpty) return pw.SizedBox();

      return pw.Center(
        child: pw.Container(
          height: 200, // Even taller for the exclusive header
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: isSvg 
              ? pw.SvgImage(svg: utf8.decode(bytes), fit: pw.BoxFit.contain)
              : pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
        ),
      );
    } catch (e) {
      debugPrint('PDF Logo Error: $e');
      return pw.SizedBox();
    }
  }

  static pw.Widget _buildPdfInfo(Transaction transaction) {
    return pw.Column(
      children: [
        _buildPdfRow('Invoice:', '#${transaction.invoiceNumber}'),
        _buildPdfRow('Date:', DateFormat('MM/dd/yyyy HH:mm').format(transaction.createdAt)),
        if (transaction.customerId != null)
           _buildPdfRow('Customer ID:', transaction.customerId!),
        _buildPdfRow('Payment:', transaction.paymentMethod),
        _buildPdfRow('Status:', transaction.paymentStatus),
      ],
    );
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildPdfItemRow(CartItem item) {
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
          pw.Text('  ${item.quantity} ${item.unitName ?? item.variantName} x ${_currencyFormat.format(item.unitPrice)}', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfTotals(Transaction transaction, SettingsProvider settings) {
    return pw.Column(
      children: [
        _buildPdfRow('Gross Total:', _currencyFormat.format(transaction.totalAmount)),
        if (transaction.discount > 0)
          _buildPdfRow('Discount:', _currencyFormat.format(-transaction.discount)),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text(_currencyFormat.format(transaction.finalAmount), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // --- LABEL PRINTING ---

  static Future<void> printLabel({
    required Map<String, dynamic> labelData,
    required SettingsProvider settings,
  }) async {
    try {
      final pdfBytes = await generateLabelPdf(
        labelData: labelData,
        settings: settings,
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Label_${labelData['productName']}',
      );
    } catch (e) {
      debugPrint('ReceiptPrinter Label Error: $e');
    }
  }

  static Future<Uint8List> generateLabelPdf({
    required Map<String, dynamic> labelData,
    required SettingsProvider settings,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Standardize with BarcodeDialog for clarity
        build: (pw.Context context) {
          final price = labelData['price'] ?? 0.0;
          final formattedPrice = _currencyFormat.format(price);
          final String barcode = labelData['barcode'] ?? '';
          final String qrData = (labelData['qrData'] != null && labelData['qrData'].toString().isNotEmpty) 
              ? labelData['qrData'].toString() 
              : barcode;
          final String productName = labelData['productName'] ?? 'No Name';
          final String unitName = labelData['unitName'] ?? '';

          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                productName.toUpperCase(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                textAlign: pw.TextAlign.center,
              ),
              if (unitName.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(unitName, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
              pw.SizedBox(height: 10),
              if (barcode.isNotEmpty)
                pw.BarcodeWidget(
                  data: barcode,
                  barcode: pw.Barcode.code128(),
                  width: 200,
                  height: 80,
                ),
              if (barcode.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Text(barcode, style: const pw.TextStyle(fontSize: 12)),
              ],
              pw.SizedBox(height: 20),
              if (qrData.isNotEmpty)
                pw.BarcodeWidget(
                  data: qrData,
                  barcode: pw.Barcode.qrCode(),
                  width: 100,
                  height: 100,
                ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Price: $formattedPrice',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                settings.storeName,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
