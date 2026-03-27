import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import '../../settings/application/settings_provider.dart';
import '../application/analytics_provider.dart';

class PdfReportService {
  static final _currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
  static final _dateFormat = DateFormat('dd MMM yyyy');

  Future<String?> generateAndSaveReport({
    required String storeName,
    required String storeAddress,
    String? storeLogo,
    required DateTime start,
    required DateTime end,
    required AnalyticsKpi kpi,
    required List<Map<String, dynamic>> topProducts,
    required List<Map<String, dynamic>> topCategories,
    required SettingsProvider settings,
  }) async {
    final pdf = pw.Document();

    // ... (rest of PDF generation stays same)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(storeName, storeAddress, start, end, settings, storeLogo: storeLogo),
          pw.SizedBox(height: 24),
          _buildKpiSummary(kpi),
          pw.SizedBox(height: 32),
          _buildSectionTitle('Top Selling Products'),
          _buildProductsTable(topProducts),
          pw.SizedBox(height: 32),
          _buildSectionTitle('Top Categories'),
          _buildCategoriesTable(topCategories),
          pw.SizedBox(height: 32),
          pw.Footer(
            trailing: pw.Text(
              'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    final fileName = 'Business_Report_${DateFormat('yyyyMMdd').format(start)}_to_${DateFormat('yyyyMMdd').format(end)}.pdf';
    
    final String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Business Report',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsBytes(await pdf.save());
      return outputFile;
    }
    
    return null;
  }

  Future<String?> generateReturnsReport({
    required String storeName,
    required String storeAddress,
    String? storeLogo,
    required DateTime start,
    required DateTime end,
    required List<dynamic> returnedTransactions,
    required SettingsProvider settings,
  }) async {
    final pdf = pw.Document();
    
    double totalReturnedAmount = 0;
    for (var tx in returnedTransactions) {
      totalReturnedAmount += tx.returnedAmount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(storeName, storeAddress, start, end, settings, title: 'RETURNED BILLS REPORT', storeLogo: storeLogo),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildKpiItem('Total Returned Bills', returnedTransactions.length.toString(), PdfColors.red800),
                _buildKpiItem('Total Returned Amount', _currencyFormat.format(totalReturnedAmount), PdfColors.red800),
              ],
            ),
          ),
          pw.SizedBox(height: 32),
          _buildSectionTitle('Returned Transactions Detail'),
          _buildReturnsTable(returnedTransactions),
          pw.SizedBox(height: 32),
          pw.Footer(
            trailing: pw.Text(
              'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    final fileName = 'Returns_Report_${DateFormat('yyyyMMdd').format(start)}_to_${DateFormat('yyyyMMdd').format(end)}.pdf';
    
    final String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Returns Report',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsBytes(await pdf.save());
      return outputFile;
    }
    
    return null;
  }

  pw.Widget _buildHeader(String name, String address, DateTime start, DateTime end, SettingsProvider settings, {String title = 'BUSINESS REPORT', String? storeLogo}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (settings.storeLogo != null || settings.storeLogoPath != null)
           pw.Center(
             child: pw.Container(
               height: 60,
               margin: const pw.EdgeInsets.only(bottom: 20),
               child: _buildPdfLogo(settings),
             ),
           ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.SizedBox(height: 4),
                pw.Text(address, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${_dateFormat.format(start)} - ${_dateFormat.format(end)}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue900),
      ],
    );
  }

  pw.Widget _buildPdfLogo(SettingsProvider settings) {
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
        if (base64.isNotEmpty) {
          final decodedBytes = base64.contains(',') 
              ? base64Decode(base64.split(',').last) 
              : base64Decode(base64);
          bytes = decodedBytes;
          isSvg = base64.contains('/svg') || 
                  (decodedBytes.length > 20 && utf8.decode(decodedBytes.take(20).toList(), allowMalformed: true).contains('<svg'));
        }
      }

      if (bytes == null || bytes.isEmpty) return pw.SizedBox();

      if (isSvg) {
        return pw.SvgImage(svg: utf8.decode(bytes));
      } else {
        return pw.Image(pw.MemoryImage(bytes));
      }
    } catch (e) {
      print('PdfReportService Logo Error: $e');
      return pw.SizedBox();
    }
  }

  pw.Widget _buildKpiSummary(AnalyticsKpi kpi) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildKpiItem('Total Revenue', _currencyFormat.format(kpi.totalRevenue), PdfColors.blue800),
              _buildKpiItem('Total Returns', _currencyFormat.format(kpi.totalReturns), PdfColors.red800),
              _buildKpiItem('Total Cost', _currencyFormat.format(kpi.totalCost), PdfColors.orange800),
              _buildKpiItem('Net Profit', _currencyFormat.format(kpi.netProfit), PdfColors.green800),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.blue200),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Transactions: ${kpi.transactions}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Low Stock Items: ${kpi.lowStockItems}', style: const pw.TextStyle(fontSize: 12)),
              _buildKpiItem('Credit Dues*', _currencyFormat.format(kpi.totalCreditToCollect), PdfColors.red800),
              _buildKpiItem('Supplier Dues*', _currencyFormat.format(kpi.totalSupplierDues), PdfColors.red800),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              '* Credit Dues and Supplier Dues are current global balances, not limited to the report date range.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildKpiItem(String title, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildProductsTable(List<Map<String, dynamic>> products) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headers: ['Product Name', 'QTY Sold', 'Revenue', 'Profit', 'Margin (%)'],
      data: products.map((p) {
        final revenue = (p['total_revenue'] as num).toDouble();
        final profit = (p['total_profit'] as num).toDouble();
        final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
        final unitStr = p['unit_name'] != null ? ' (${p['unit_name']})' : '';
        return [
          '${p['name']}$unitStr',
          p['total_qty'].toString(),
          _currencyFormat.format(revenue),
          _currencyFormat.format(profit),
          '${margin.toStringAsFixed(1)}%',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1),
      },
    );
  }

  pw.Widget _buildCategoriesTable(List<Map<String, dynamic>> categories) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headers: ['Category Name', 'Total Sales Value'],
      data: categories.map((c) => [
        c['label'],
        _currencyFormat.format((c['value'] as num).toDouble()),
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
      },
    );
  }

  pw.Widget _buildReturnsTable(List<dynamic> transactions) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headers: ['Return Date', 'Invoice #', 'Customer', 'Refund Amt', 'Original Amt', 'Status'],
      data: transactions.map((t) {
        // Support both typed Transaction objects and raw Map from the new query
        final isMap = t is Map<String, dynamic>;
        final invoiceNumber = isMap ? (t['invoice_number'] as String? ?? 'N/A') : t.invoiceNumber;
        final customerName = isMap ? (t['customer_name'] as String? ?? 'Walk-in') : (t.customerName ?? 'Walk-in');
        final returnedAmount = isMap 
            ? (t['event_refund_amount'] as num?)?.toDouble() ?? (t['returned_amount'] as num?)?.toDouble() ?? 0.0
            : t.returnedAmount;
        final finalAmount = isMap ? (t['final_amount'] as num?)?.toDouble() ?? 0.0 : t.finalAmount;
        final isFullReturn = isMap ? (t['is_returned'] as num?)?.toInt() == 1 : t.isReturned;
        // return_event_date is the date the return was processed; fall back to created_at
        final returnDateStr = isMap
            ? (t['return_event_date'] as String? ?? t['created_at'] as String? ?? '')
            : t.createdAt.toIso8601String();
        final returnDate = DateTime.tryParse(returnDateStr) ?? DateTime.now();

        return [
          DateFormat('dd MMM yyyy, HH:mm').format(returnDate),
          invoiceNumber,
          customerName,
          _currencyFormat.format(returnedAmount),
          _currencyFormat.format(finalAmount),
          isFullReturn ? 'FULL' : 'PARTIAL',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.0),
      },
    );
  }
}
