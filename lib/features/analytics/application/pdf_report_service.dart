import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import '../application/analytics_provider.dart';

class PdfReportService {
  static final _currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
  static final _dateFormat = DateFormat('dd MMM yyyy');

  Future<String?> generateAndSaveReport({
    required String storeName,
    required String storeAddress,
    required DateTime start,
    required DateTime end,
    required AnalyticsKpi kpi,
    required List<Map<String, dynamic>> topProducts,
    required List<Map<String, dynamic>> topCategories,
  }) async {
    final pdf = pw.Document();

    // ... (rest of PDF generation stays same)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(storeName, storeAddress, start, end),
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

  pw.Widget _buildHeader(String name, String address, DateTime start, DateTime end) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
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
                pw.Text('BUSINESS REPORT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
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
              _buildKpiItem('Total Cost', _currencyFormat.format(kpi.totalCost), PdfColors.orange800),
              _buildKpiItem('Net Profit', _currencyFormat.format(kpi.netProfit), PdfColors.green800),
              _buildKpiItem('Outstanding Credit', _currencyFormat.format(kpi.totalCreditToCollect), PdfColors.red800),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.blue200),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Transactions: ${kpi.transactions}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Low Stock Alerts: ${kpi.lowStockItems}', style: const pw.TextStyle(fontSize: 12)),
            ],
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
}
