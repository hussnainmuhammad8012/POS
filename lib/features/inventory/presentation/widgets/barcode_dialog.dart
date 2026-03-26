import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../data/models/product_summary_model.dart';
import '../../data/models/product_unit_model.dart';
import '../../../../core/widgets/toast_notification.dart';
import '../../../../features/settings/application/settings_provider.dart';
import 'package:pasteboard/pasteboard.dart';

class BarcodeDialog extends StatefulWidget {
  final ProductSummary productSummary;

  const BarcodeDialog({super.key, required this.productSummary});

  @override
  State<BarcodeDialog> createState() => _BarcodeDialogState();
}

class _BarcodeDialogState extends State<BarcodeDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isProcessing = false;
  int _selectedUnitIndex = 0;

  // --- Data helpers ---

  bool get _isUomMode =>
      context.read<SettingsProvider>().enableUomSystem &&
      widget.productSummary.units.isNotEmpty;

  List<ProductUnit> get _units => widget.productSummary.units;

  ProductUnit? get _selectedUnit =>
      _isUomMode ? _units[_selectedUnitIndex] : null;

  /// The barcode value to display for the currently selected context.
  String get _barcode {
    if (_isUomMode && _selectedUnit != null) {
      final unitBarcode = _selectedUnit!.barcode;
      if (unitBarcode != null && unitBarcode.isNotEmpty) return unitBarcode;
      // Fallback: unit name appended to SKU so it's not empty
      return '${widget.productSummary.product.baseSku}-${_selectedUnit!.unitName}';
    }
    return (widget.productSummary.barcode?.isNotEmpty == true)
        ? widget.productSummary.barcode!
        : widget.productSummary.product.baseSku;
  }

  /// The QR data for the currently selected context.
  String get _qrData {
    if (_isUomMode && _selectedUnit != null) {
      final unitQr = _selectedUnit!.qrCode;
      if (unitQr != null && unitQr.isNotEmpty) return unitQr;
      return _barcode;
    }
    return (widget.productSummary.qrCode?.isNotEmpty == true)
        ? widget.productSummary.qrCode!
        : _barcode;
  }

  String get _productName => widget.productSummary.product.name;

  /// True if this unit actually has a barcode stored in the database.
  bool get _hasCustomBarcode {
    if (_isUomMode && _selectedUnit != null) {
      return _selectedUnit!.barcode != null && _selectedUnit!.barcode!.isNotEmpty;
    }
    return widget.productSummary.barcode != null &&
        widget.productSummary.barcode!.isNotEmpty;
  }

  bool get _hasCustomQr {
    if (_isUomMode && _selectedUnit != null) {
      return _selectedUnit!.qrCode != null && _selectedUnit!.qrCode!.isNotEmpty;
    }
    return widget.productSummary.qrCode != null &&
        widget.productSummary.qrCode!.isNotEmpty;
  }

  String get _labelSubtitle {
    if (_isUomMode && _selectedUnit != null) {
      return '${_selectedUnit!.unitName} · ${_selectedUnit!.conversionRate == 1 ? 'Base Unit' : '× ${_selectedUnit!.conversionRate} pieces'}';
    }
    return 'Product Label';
  }

  // --- Actions ---

  Future<void> _printLabel() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(_productName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              if (_isUomMode && _selectedUnit != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(_labelSubtitle, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
              pw.SizedBox(height: 10),
              pw.BarcodeWidget(
                data: _barcode,
                barcode: pw.Barcode.code128(),
                width: 200,
                height: 80,
              ),
              pw.SizedBox(height: 5),
              pw.Text(_barcode, style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.BarcodeWidget(
                data: _qrData,
                barcode: pw.Barcode.qrCode(),
                width: 100,
                height: 100,
              ),
              pw.SizedBox(height: 10),
              pw.Text('Internal Inventory Use Only', style: const pw.TextStyle(fontSize: 8)),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  Future<void> _saveAsPng() async {
    setState(() => _isProcessing = true);
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final safeUnitName = _isUomMode && _selectedUnit != null
          ? '_${_selectedUnit!.unitName.replaceAll(' ', '_')}'
          : '';
      final fileName = '${_productName.replaceAll(' ', '_')}${safeUnitName}_label.png';

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Barcode Label',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (outputPath != null) {
        if (!outputPath.endsWith('.png')) outputPath += '.png';
        final file = File(outputPath);
        await file.writeAsBytes(image);
        if (mounted) {
          AppToast.show(context, title: 'Saved', message: 'Label saved to: $outputPath', type: ToastType.success);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, title: 'Error', message: e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareToWhatsApp() async {
    setState(() => _isProcessing = true);
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        await Pasteboard.writeImage(image);
        if (mounted) {
          AppToast.show(
            context,
            title: 'Copied to Clipboard',
            message: 'Label image copied! Paste (Ctrl+V) in WhatsApp.',
            type: ToastType.success,
          );
        }
      }

      final unitInfo = _isUomMode && _selectedUnit != null
          ? ' (${_selectedUnit!.unitName})'
          : '';
      final message = Uri.encodeComponent(
          'Product Label: $_productName$unitInfo\nCode: $_barcode\n(Internal Use Only)');
      final appUrl = 'whatsapp://send?text=$message';
      final webUrl = 'https://wa.me/?text=$message';

      if (await canLaunchUrl(Uri.parse(appUrl))) {
        await launchUrl(Uri.parse(appUrl));
      } else if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl));
      } else {
        if (mounted) {
          AppToast.show(context, title: 'Error', message: 'Could not launch WhatsApp', type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, title: 'Error', message: 'Failed to share: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    final isUom = context.read<SettingsProvider>().enableUomSystem &&
        widget.productSummary.units.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isUom ? 540 : 450,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolbar(),
            if (isUom) _buildUnitSelector(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildLabelPreview(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.scanLine, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory Labels',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  _productName,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.x, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.layers, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Select Unit to Print Label For',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_units.length, (index) {
                final unit = _units[index];
                final isSelected = _selectedUnitIndex == index;
                final hasBarcode = unit.barcode != null && unit.barcode!.isNotEmpty;
                final hasQr = unit.qrCode != null && unit.qrCode!.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 10),
                  child: InkWell(
                    onTap: () => setState(() => _selectedUnitIndex = index),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            unit.isBaseUnit ? LucideIcons.package : LucideIcons.packageOpen,
                            size: 14,
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unit.unitName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                              Text(
                                unit.isBaseUnit
                                    ? 'Base'
                                    : '× ${unit.conversionRate}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          // Indicator dots for available codes
                          Row(
                            children: [
                              _codeIndicator(hasBarcode, isSelected, LucideIcons.barChart2, 'Barcode'),
                              const SizedBox(width: 3),
                              _codeIndicator(hasQr, isSelected, LucideIcons.qrCode, 'QR'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeIndicator(bool available, bool isSelected, IconData icon, String tooltip) {
    return Tooltip(
      message: available ? '$tooltip code set' : '$tooltip not configured',
      child: Icon(
        icon,
        size: 12,
        color: available
            ? (isSelected ? Colors.white : Colors.green)
            : (isSelected ? Colors.white38 : Colors.grey.shade400),
      ),
    );
  }

  Widget _buildLabelPreview() {
    return Screenshot(
      controller: _screenshotController,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _productName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (_isUomMode && _selectedUnit != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _labelSubtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Missing barcode warning
            if (!_hasCustomBarcode)
              _buildMissingCodeWarning('Barcode', 'Using SKU-based code as fallback')
            else ...[
              BarcodeWidget(
                barcode: Barcode.code128(),
                data: _barcode,
                width: 280,
                height: 90,
                drawText: true,
                style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 24),
            if (!_hasCustomQr)
              _buildMissingCodeWarning('QR Code', 'Using barcode data as fallback for QR')
            else
              QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 160.0,
                backgroundColor: Colors.white,
              ),
            // Always show QR with fallback data even if not custom
            if (_hasCustomQr || true) ...[
              if (!_hasCustomQr)
                QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 140.0,
                  backgroundColor: Colors.white,
                ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Internal Inventory Use Only',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const Text(
              'Not GS1 Registered',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingCodeWarning(String type, String hint) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle, size: 14, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No $type configured for this unit',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.bold),
              ),
              Text(
                hint,
                style: TextStyle(fontSize: 10, color: Colors.orange.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildActionButton(
          icon: LucideIcons.printer,
          label: 'Print',
          onPressed: _printLabel,
          color: Colors.blue,
        ),
        _buildActionButton(
          icon: LucideIcons.download,
          label: 'Save PNG',
          onPressed: _saveAsPng,
          color: Colors.green,
        ),
        _buildActionButton(
          icon: LucideIcons.messageCircle,
          label: 'WhatsApp',
          onPressed: _shareToWhatsApp,
          color: const Color(0xFF25D366),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }
}
