import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:companion_app/core/theme/app_theme.dart';
import 'package:companion_app/features/inventory/application/inventory_provider.dart';
import 'package:companion_app/features/inventory/data/models/product_model.dart';
import 'package:companion_app/features/inventory/data/models/product_unit_model.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MobilePrintLabelDialog extends StatefulWidget {
  final Product product;
  const MobilePrintLabelDialog({super.key, required this.product});

  @override
  State<MobilePrintLabelDialog> createState() => _MobilePrintLabelDialogState();
}

class _MobilePrintLabelDialogState extends State<MobilePrintLabelDialog> {
  int _selectedUnitIndex = 0;
  int _copies = 1;
  bool _isSending = false;
  Map<String, dynamic>? _sentResult;

  List<ProductUnit> get _units => widget.product.units;
  bool get _hasUnits => _units.isNotEmpty;
  ProductUnit? get _selectedUnit => _hasUnits ? _units[_selectedUnitIndex] : null;

  String get _barcode {
    if (_hasUnits && _selectedUnit != null && _selectedUnit!.barcode != null && _selectedUnit!.barcode!.isNotEmpty) {
      return _selectedUnit!.barcode!;
    }
    return widget.product.barcode ?? widget.product.baseSku;
  }

  String get _qrData {
    if (_hasUnits && _selectedUnit != null && _selectedUnit!.qrCode != null && _selectedUnit!.qrCode!.isNotEmpty) {
      return _selectedUnit!.qrCode!;
    }
    return _barcode;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    final isUomEnabled = provider.isUomEnabled;

    return AlertDialog(
      backgroundColor: AppColors.STAR_BACKGROUND,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.STAR_PRIMARY,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.printer, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Print Label', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(widget.product.name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Unit Selector ──
              if (isUomEnabled && _hasUnits) ...[
                const Text('Select Unit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.STAR_TEXT_SECONDARY)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_units.length, (i) {
                      final unit = _units[i];
                      final isSelected = _selectedUnitIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedUnitIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.STAR_PRIMARY : Colors.white,
                              border: Border.all(color: isSelected ? AppColors.STAR_PRIMARY : AppColors.STAR_BORDER),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(unit.unitName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : AppColors.STAR_TEXT_PRIMARY,
                                      fontSize: 13,
                                    )),
                                Text(
                                  unit.isBaseUnit ? 'Base' : '× ${unit.conversionRate}',
                                  style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : AppColors.STAR_TEXT_SECONDARY),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Barcode Preview ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.STAR_BORDER),
                ),
                child: Column(
                  children: [
                    Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
                    if (_hasUnits && _selectedUnit != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.STAR_PRIMARY.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_selectedUnit!.unitName,
                            style: const TextStyle(fontSize: 11, color: AppColors.STAR_PRIMARY, fontWeight: FontWeight.w600)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 60,
                      child: BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: _barcode,
                        drawText: false,
                        width: double.infinity,
                        height: 60,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_barcode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.STAR_TEXT_SECONDARY)),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 80,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                    const Text('QR Preview', style: TextStyle(fontSize: 10, color: AppColors.STAR_TEXT_SECONDARY)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Copies ──
              Row(
                children: [
                  const Text('Copies:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
                    icon: const Icon(LucideIcons.minus, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.STAR_BORDER,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$_copies', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _copies < 10 ? () => setState(() => _copies++) : null,
                    icon: const Icon(LucideIcons.plus, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.STAR_PRIMARY,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),

              // ── Result banner ──
              if (_sentResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.SUCCESS.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.SUCCESS),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.checkCircle, color: AppColors.SUCCESS, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Job #${_sentResult!['jobId']} queued! Position: ${_sentResult!['position']}',
                          style: const TextStyle(color: AppColors.SUCCESS, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY)),
        ),
        ElevatedButton.icon(
          onPressed: _isSending ? null : () async {
            setState(() => _isSending = true);
            final result = await provider.requestPrintLabel(
              productId: widget.product.id,
              productName: widget.product.name,
              barcode: _barcode,
              qrData: _qrData,
              unitId: _selectedUnit?.id,
              unitName: _selectedUnit?.unitName,
              copies: _copies,
            );
            if (mounted) {
              setState(() {
                _isSending = false;
                _sentResult = result;
              });
              if (result == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to send print request'), backgroundColor: AppColors.DANGER),
                );
              }
            }
          },
          icon: _isSending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.printer, size: 16),
          label: const Text('Send to Desktop Printer'),
        ),
      ],
    );
  }
}
