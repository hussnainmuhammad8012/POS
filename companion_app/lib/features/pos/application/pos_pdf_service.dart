import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PosPdfService {
  Future<File> generateReceiptPdf(Map<String, dynamic> receiptData) async {
    final pdf = pw.Document();
    final storeName = receiptData['storeName'] ?? 'UTILITY STORE';
    final storeAddress = receiptData['storeAddress'] ?? '';
    final storePhone = receiptData['storePhone'] ?? '';
    final customMessage = receiptData['receiptCustomMessage'] ?? 'Thank you for shopping!';
    final date = receiptData['date'] ?? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final invoice = receiptData['invoice'] ?? 'N/A';
    final items = receiptData['items'] as List? ?? [];
    final subtotal = receiptData['subtotal'] ?? 0.0;
    final discount = receiptData['discount'] ?? 0.0;
    final tax = receiptData['tax'] ?? 0.0;
    final total = receiptData['total'] ?? 0.0;
    final cashPaid = receiptData['cashPaid'] ?? total;
    final credit = receiptData['creditAmount'] ?? 0.0;
    final customer = receiptData['customer']?['name'] ?? 'Walk-in Customer';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(storeName.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ),
              if (storeAddress.isNotEmpty)
                pw.Center(child: pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
              if (storePhone.isNotEmpty)
                pw.Center(child: pw.Text('PH: $storePhone', style: const pw.TextStyle(fontSize: 8))),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('STORE RECEIPT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              ),
              pw.SizedBox(height: 10),
              _pdfInfoRow('Invoice:', '#$invoice'),
              _pdfInfoRow('Date:', date),
              _pdfInfoRow('Customer:', customer),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                   pw.Text('Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(thickness: 0.5),
              ...items.map((item) {
                final itemName = item['productName'] ?? 'Product';
                final unit = item['unitName'] ?? item['variantName'] ?? '';
                final qty = item['quantity'] ?? 1;
                final price = item['unitPrice'] ?? 0.0;
                final itemTotal = item['total'] ?? 0.0;
                final itemDisc = (item['unitDiscount'] ?? 0.0) * qty;
                final itemDiscPercent = item['unitDiscountPercent'] ?? 0.0;
                final itemTax = item['taxAmount'] ?? 0.0;
                final itemTaxRate = item['taxRate'] ?? 0.0;

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                           pw.Expanded(child: pw.Text(itemName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                           pw.Text('Rs ${itemTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Text('$qty x Rs ${price.toStringAsFixed(2)} ($unit)', style: const pw.TextStyle(fontSize: 7)),
                      if (itemDisc > 0)
                        pw.Text('  Discount: ${itemDiscPercent.toStringAsFixed(1)}% (-Rs ${itemDisc.toStringAsFixed(2)})', style: pw.TextStyle(fontSize: 7, color: PdfColors.green)),
                      if (itemTax > 0)
                        pw.Text('  Tax (${itemTaxRate.toStringAsFixed(1)}%): +Rs ${itemTax.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 7, color: PdfColors.orange)),
                    ],
                  ),
                );
              }).toList(),
              pw.Divider(thickness: 0.5),
              _pdfRow('Gross Total:', subtotal),
              if (tax > 0) _pdfRow(receiptData['taxInclusive'] == true ? 'Tax (Incl.):' : 'Tax (Excl.):', tax),
              if (discount > 0) _pdfRow('Total Discount (${(receiptData['discountPercent'] ?? 0.0).toStringAsFixed(1)}%):', discount, isNegative: true),
              pw.SizedBox(height: 4),
              _pdfRow('TOTAL:', total, isBold: true, fontSize: 12),
              if (discount > 0)
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text('YOU SAVED: Rs ${discount.toStringAsFixed(2)}', 
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                  ),
                ),
              pw.Divider(thickness: 0.5),
              _pdfRow('Cash Paid', cashPaid),
              if (credit > 0) _pdfRow('Remaining Credit', credit),
              pw.SizedBox(height: 15),
              pw.Center(child: pw.Text(customMessage, style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic), textAlign: pw.TextAlign.center)),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Receipt_$invoice.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _pdfRow(String label, dynamic value, {bool isBold = false, bool isNegative = false, double fontSize = 9}) {
    final val = double.tryParse(value.toString()) ?? 0.0;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(
            '${isNegative ? "-" : ""}Rs ${val.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
