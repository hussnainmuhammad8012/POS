import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:companion_app/features/inventory/data/models/product_model.dart';
import 'package:companion_app/core/theme/app_theme.dart';

class ProductDetailsDialog extends StatefulWidget {
  final Product product;
  final VoidCallback onAddStock;

  const ProductDetailsDialog({
    super.key, 
    required this.product,
    required this.onAddStock,
  });

  @override
  State<ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<ProductDetailsDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  String get _barcode => widget.product.barcode ?? widget.product.baseSku;
  String get _qrData => widget.product.qrCode ?? _barcode;

  Future<void> _shareLabel() async {
    setState(() => _isSharing = true);
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/label_${widget.product.id}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Product Label: ${widget.product.name}\nInternal Use Only',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.STAR_BACKGROUND,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProductInfo(),
                  const SizedBox(height: 24),
                  Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: _barcode,
                            width: 250,
                            height: 80,
                            drawText: true,
                            style: const TextStyle(fontSize: 12, color: Colors.black),
                          ),
                          const SizedBox(height: 24),
                          QrImageView(
                            data: _qrData,
                            version: QrVersions.auto,
                            size: 140.0,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Internal Inventory Use Only',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.STAR_PRIMARY,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.package, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Product Details',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      children: [
        _buildInfoRow(LucideIcons.tag, 'SKU', widget.product.baseSku),
        _buildInfoRow(LucideIcons.boxes, 'Current Stock', '${widget.product.currentStock} ${widget.product.unitType}'),
        _buildInfoRow(LucideIcons.banknote, 'Retail Price', 'Rs. ${widget.product.price.toStringAsFixed(0)}'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.STAR_TEXT_SECONDARY),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppColors.STAR_TEXT_SECONDARY, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSharing ? null : _shareLabel,
            icon: _isSharing 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.share2, size: 18),
            label: const Text('Share Label'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.STAR_PRIMARY.withOpacity(0.1),
              foregroundColor: AppColors.STAR_PRIMARY,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onAddStock();
            },
            icon: const Icon(LucideIcons.plusCircle, size: 18),
            label: const Text('Add Stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.STAR_PRIMARY,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
