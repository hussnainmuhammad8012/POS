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
import '../../../../features/settings/application/settings_provider.dart';
import '../product_details_screen.dart';
import 'add_product_dialog.dart';
import 'add_stock_dialog.dart';
import 'barcode_dialog.dart';
import '../../../../features/inventory/data/repositories/product_repository.dart';
import '../../../../core/widgets/app_action_menu.dart';

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
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        horizontalMargin: 16,
                        columnSpacing: 12,
                        columns: const [
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Prices')),
                          DataColumn(label: Text('Current Stock')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: products.map((product) => _buildProductRow(context, product, provider)).toList(),
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
          if (states.contains(WidgetState.hovered)) {
            return Theme.of(context).primaryColor.withOpacity(0.05);
          }
          if (summary.isLowStockWarning) {
            return Theme.of(context).colorScheme.error.withOpacity(0.08);
          }
          return null;
        },
      ),
      cells: [
        DataCell(Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(summary.categoryName ?? 'Unknown')),
        DataCell(Text(summary.priceRange)),
        DataCell(
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              if (!settings.enableUomSystem) {
                return Text(
                  summary.totalStock.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: summary.isLowStockWarning ? Theme.of(context).colorScheme.error : null,
                  ),
                );
              }
              
              // UOM Mode: Format stock string
              return FutureBuilder<String>(
                future: context.read<ProductRepository>().formatStockPieces(product.id, summary.totalStock),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? summary.totalStock.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: summary.isLowStockWarning ? Theme.of(context).colorScheme.error : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
        DataCell(
          AppActionMenu<String>(
            onSelected: (value) async {
              switch (value) {
                case 'view':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(productSummary: summary),
                    ),
                  );
                  break;
                case 'add_stock':
                  showDialog(
                    context: context,
                    builder: (context) => AddStockDialog(productSummary: summary),
                  );
                  break;
                case 'print':
                  showDialog(
                    context: context,
                    builder: (context) => BarcodeDialog(productSummary: summary),
                  );
                  break;
                case 'edit':
                  showDialog(
                    context: context,
                    builder: (context) => AddProductDialog(initialProduct: summary),
                  );
                  break;
                case 'delete':
                  _showDeleteConfirmation(context, summary, provider);
                  break;
              }
            },
            items: const [
              AppDropdownItem(
                value: 'view',
                label: 'View Details',
                icon: LucideIcons.eye,
              ),
              AppDropdownItem(
                value: 'add_stock',
                label: 'Add Stock',
                icon: LucideIcons.plus,
              ),
              AppDropdownItem(
                value: 'print',
                label: 'Print Labels',
                icon: LucideIcons.scanLine,
              ),
              AppDropdownItem(
                value: 'edit',
                label: 'Edit Product',
                icon: LucideIcons.pencil,
              ),
              AppDropdownItem(
                value: 'delete',
                label: 'Delete',
                icon: LucideIcons.trash2,
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
