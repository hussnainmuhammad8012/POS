import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../data/models/product_summary_model.dart';
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
                                  _buildInfoRow(LucideIcons.boxes, 'Current Stock', '${productSummary.totalStock}', 
                                    valueColor: productSummary.isLowStockWarning ? Colors.orange.shade700 : null),
                                ],
                              ),
                            ),
                          ),
                        ],
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
