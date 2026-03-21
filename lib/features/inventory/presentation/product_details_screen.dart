import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../data/models/product_summary_model.dart';
import '../data/models/product_unit_model.dart';
import '../data/repositories/product_repository.dart';
import '../../../../features/settings/application/settings_provider.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/badge_widget.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductSummary productSummary;

  const ProductDetailsScreen({
    super.key,
    required this.productSummary,
  });

  @override
  Widget build(BuildContext context) {
    final product = productSummary.product;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                if (product.mainImagePath != null)
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(product.mainImagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      ),
                    ),
                  )
                else
                  _buildPlaceholderImage(size: 300),
                
                const SizedBox(width: 32),
                
                // Details Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          BadgeWidget(
                            label: product.isActive ? 'Active' : 'Inactive',
                            type: product.isActive ? BadgeType.success : BadgeType.error,
                          ),
                          const SizedBox(width: 12),
                          if (productSummary.isLowStockWarning)
                            const BadgeWidget(
                              label: 'Low Stock',
                              type: BadgeType.warning,
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      ModernCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Basic Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 32),
                            _buildInfoRow(LucideIcons.tag, 'SKU', product.baseSku),
                            if (productSummary.barcode != null && productSummary.barcode!.isNotEmpty)
                              _buildInfoRow(LucideIcons.scanLine, 'Barcode', productSummary.barcode!),
                            _buildInfoRow(LucideIcons.folder, 'Category', productSummary.categoryName ?? 'Unknown'),
                            _buildInfoRow(LucideIcons.hash, 'Unit Type', product.unitType),
                            if (product.description != null && product.description!.isNotEmpty)
                              _buildInfoRow(LucideIcons.fileText, 'Description', product.description!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ModernCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pricing',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Divider(height: 32),
                                  if (productSummary.costPrice != null)
                                    _buildInfoRow(LucideIcons.arrowDownCircle, 'Cost Price', '\$${productSummary.costPrice!.toStringAsFixed(2)}'),
                                  _buildInfoRow(LucideIcons.dollarSign, 'Retail Price', productSummary.priceRange),
                                  if (productSummary.wholesalePrice != null)
                                    _buildInfoRow(LucideIcons.users, 'Wholesale Price', '\$${productSummary.wholesalePrice!.toStringAsFixed(2)}'),
                                  if (productSummary.mrp != null)
                                    _buildInfoRow(LucideIcons.shieldCheck, 'MRP', '\$${productSummary.mrp!.toStringAsFixed(2)}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: ModernCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Stock Overview',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Divider(height: 32),
                                  Consumer<SettingsProvider>(
                                    builder: (context, settings, _) {
                                      if (!settings.enableUomSystem) {
                                        return _buildInfoRow(LucideIcons.boxes, 'Current Stock', '${productSummary.totalStock}', 
                                          valueColor: productSummary.isLowStockWarning ? Colors.orange.shade700 : null);
                                      }
                                      return FutureBuilder<String>(
                                        future: context.read<ProductRepository>().formatStockPieces(product.id, productSummary.totalStock),
                                        builder: (context, snapshot) {
                                          return _buildInfoRow(LucideIcons.boxes, 'Current Stock', snapshot.data ?? '${productSummary.totalStock}', 
                                            valueColor: productSummary.isLowStockWarning ? Colors.orange.shade700 : null);
                                        },
                                      );
                                    },
                                  ),
                                  _buildInfoRow(LucideIcons.alertTriangle, 'Low Stock At', '${productSummary.lowStockThreshold}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // UOMs Section (Dynamic if Enabled)
                      if (context.watch<SettingsProvider>().enableUomSystem)
                        ModernCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Units of Measure (UOM)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(height: 32),
                              FutureBuilder<List<ProductUnit>>(
                                future: context.read<ProductRepository>().getUnitsByProductId(product.id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Text('Error loading UOMs: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                                  }
                                  
                                  final units = snapshot.data ?? [];
                                  if (units.isEmpty) {
                                    return const Text('No explicit units defined.');
                                  }

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: units.length,
                                    separatorBuilder: (_, __) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final unit = units[index];
                                      return ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(unit.isBaseUnit ? LucideIcons.star : LucideIcons.layers, 
                                            color: Theme.of(context).primaryColor, size: 20),
                                        ),
                                        title: Row(
                                          children: [
                                            Text(unit.unitName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            if (unit.isBaseUnit)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                                child: Text('BASE', style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                                              )
                                          ],
                                        ),
                                        subtitle: Text(
                                          'Conversion: ${unit.conversionRate}x | Barcode: ${unit.barcode ?? "N/A"}\n'
                                          'Cost: \$${unit.costPrice.toStringAsFixed(2)} | Retail: \$${unit.retailPrice.toStringAsFixed(2)}'
                                          '${unit.wholesalePrice != null ? " | WS: \$${unit.wholesalePrice!.toStringAsFixed(2)}" : ""}\n'
                                          'Total in this Unit: ${(productSummary.totalStock / unit.conversionRate).toStringAsFixed(2)} ${unit.unitName}'
                                        ),
                                        isThreeLine: true,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage({double size = 300}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.imageOff, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No Image Available',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
