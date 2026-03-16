import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../application/inventory_provider.dart';
import '../../data/models/product_summary_model.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/badge_widget.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/toast_notification.dart';
import '../product_details_screen.dart';
import 'add_product_dialog.dart';
import 'add_stock_dialog.dart';
import 'barcode_dialog.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final products = provider.filteredProducts;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ModernCard(
        padding: EdgeInsets.zero,
        mainAxisSize: MainAxisSize.max,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Search bar — no label so it sits flush with the dropdown
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          prefixIcon: LucideIcons.search,
                          hint: 'Filter by name or SKU...',
                          onChanged: (v) => provider.setSearchQuery(v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Category filter using AppDropdown, fixed width for clean parallel look
                      Expanded(
                        flex: 1,
                        child: AppDropdown<String?>(
                          hint: 'All Categories',
                          prefixIcon: LucideIcons.layoutGrid,
                          value: provider.selectedCategoryId,
                          items: [
                            const AppDropdownItem<String?>(
                              value: null,
                              label: 'All Categories',
                              icon: LucideIcons.layoutGrid,
                            ),
                            ...provider.categories.expand((c) => [
                              AppDropdownItem<String?>(
                                value: c.id,
                                label: c.name,
                                icon: LucideIcons.folder,
                              ),
                              ...c.subcategories.map((s) => AppDropdownItem<String?>(
                                value: s.id,
                                label: s.name,
                                subtitle: c.name,
                                icon: LucideIcons.folderOpen,
                              )),
                            ]),
                          ],
                          onChanged: (v) => provider.setSelectedCategory(v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          prefixIcon: LucideIcons.dollarSign,
                          hint: 'Min Price',
                          keyboardType: TextInputType.number,
                          onChanged: (v) => provider.setPriceRange(
                            double.tryParse(v) ?? 0, 
                            provider.maxPrice,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          prefixIcon: LucideIcons.dollarSign,
                          hint: 'Max Price',
                          keyboardType: TextInputType.number,
                          onChanged: (v) => provider.setPriceRange(
                            provider.minPrice, 
                            double.tryParse(v) ?? double.infinity,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          prefixIcon: LucideIcons.boxes,
                          hint: 'Min Stock',
                          keyboardType: TextInputType.number,
                          onChanged: (v) => provider.setStockRange(
                            int.tryParse(v) ?? 0, 
                            provider.maxStock,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          prefixIcon: LucideIcons.boxes,
                          hint: 'Max Stock',
                          keyboardType: TextInputType.number,
                          onChanged: (v) => provider.setStockRange(
                            provider.minStock, 
                            int.tryParse(v) ?? 999999,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: provider.showLowStockOnly,
                            onChanged: (v) => provider.setShowLowStockOnly(v ?? false),
                          ),
                          const Text('Low Stock Only', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (provider.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (products.isEmpty)
              _buildEmptyState(context)
            else
              Expanded(
                child: Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    primary: true,
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      thickness: 8,
                      radius: const Radius.circular(4),
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 48,
                          ),
                          child: DataTable(
                            horizontalMargin: 24,
                            columnSpacing: 24,
                            columns: const [
                              DataColumn(label: Text('Product')),
                              DataColumn(label: Text('SKU')),
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Prices')),
                              DataColumn(label: Text('Current Stock')),
                              DataColumn(label: Text('Unit')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: products.map((product) => _buildProductRow(context, product, provider)).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  DataRow _buildProductRow(BuildContext context, ProductSummary summary, InventoryProvider provider) {
    final product = summary.product;
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (summary.isLowStockWarning) {
            return Theme.of(context).colorScheme.error.withOpacity(0.1);
          }
          return null; // Use default value for other states and when not in warning
        },
      ),
      cells: [
        DataCell(Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(product.baseSku)),
        DataCell(Text(summary.categoryName ?? 'Unknown')),
        DataCell(Text(summary.priceRange)),
        DataCell(
          Text(
            summary.totalStock.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: summary.isLowStockWarning ? Theme.of(context).colorScheme.error : null,
            ),
          )
        ),
        DataCell(Text(product.unitType)),
        DataCell(
          Row(
            children: [
              IconButton(icon: const Icon(LucideIcons.eye, size: 18), onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(productSummary: summary),
                  ),
                );
              }),
              Tooltip(
                message: 'Add Stock',
                child: IconButton(
                  icon: const Icon(LucideIcons.plus, size: 18, color: Colors.blue),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddStockDialog(productSummary: summary),
                    );
                  },
                ),
              ),
              Tooltip(
                message: 'Print Labels',
                child: IconButton(
                  icon: const Icon(LucideIcons.scanLine, size: 18, color: Colors.blue),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => BarcodeDialog(productSummary: summary),
                    );
                  },
                ),
              ),
              IconButton(icon: const Icon(LucideIcons.pencil, size: 18), onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddProductDialog(initialProduct: summary),
                );
              }),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red), 
                onPressed: () {
                  _showDeleteConfirmation(context, summary, provider);
                }
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductSummary summary, InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Delete Product'),
          ],
        ),
        content: Text('Are you sure you want to delete ${summary.product.name}? This action cannot be undone and will soft-delete its variants as well.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.deleteProduct(summary.product.id);
                if (context.mounted) {
                  AppToast.show(
                    context, 
                    title: 'Product Deleted', 
                    message: 'The product has been removed successfully.',
                    type: ToastType.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.show(
                    context, 
                    title: 'Delete Failed', 
                    message: 'Error: $e',
                    type: ToastType.error,
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.packageSearch, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No products found matching your search.'),
          ],
        ),
      ),
    );
  }
}
