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
import 'package:path_provider/path_provider.dart';
import '../../data/models/product_summary_model.dart';
import '../../../../core/widgets/toast_notification.dart';
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

  String get _barcode => (widget.productSummary.barcode?.isNotEmpty == true) 
      ? widget.productSummary.barcode! 
      : widget.productSummary.product.baseSku;
      
  String get _productName => widget.productSummary.product.name;
  
  String get _qrData => (widget.productSummary.qrCode?.isNotEmpty == true) 
      ? widget.productSummary.qrCode! 
      : _barcode;

  Future<void> _printLabel() async {
    final doc = pw.Document();
    final barcodeType = Barcode.code128();
    
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(_productName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.BarcodeWidget(
                data: _barcode,
                barcode: barcodeType,
                width: 200,
                height: 80,
              ),
              pw.SizedBox(height: 5),
              pw.Text(_barcode, style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.Container(
                width: 100,
                height: 100,
                child: pw.BarcodeWidget(
                  data: _qrData,
                  barcode: pw.Barcode.qrCode(),
                  width: 100,
                  height: 100,
                ),
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

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Barcode Label',
        fileName: '${_productName.replaceAll(' ', '_')}_label.png',
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
      // 1. Capture the label as an image
      final Uint8List? image = await _screenshotController.capture();
      
      if (image != null) {
        // 2. Copy the image to the system clipboard (Pasteboard)
        await Pasteboard.writeImage(image);
        
        if (mounted) {
          AppToast.show(
            context, 
            title: 'Copied to Clipboard', 
            message: 'Label image copied! You can now paste (Ctrl+V) in WhatsApp.', 
            type: ToastType.success
          );
        }
      }

      // 3. Launch WhatsApp
      final message = Uri.encodeComponent(
          'Product Label: $_productName\nCode: $_barcode\n(Internal Use Only)');
      
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToolbar(),
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
          const Text(
            'Inventory Labels',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.x, size: 20),
          ),
        ],
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
            const SizedBox(height: 24),
            BarcodeWidget(
              barcode: Barcode.code128(),
              data: _barcode,
              width: 280,
              height: 90,
              drawText: true,
              style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: 160.0,
              backgroundColor: Colors.white,
            ),
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
