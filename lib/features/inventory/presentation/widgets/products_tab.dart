import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../application/inventory_provider.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/badge_widget.dart';
import '../../../../core/widgets/app_dropdown.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Search bar — no label so it sits flush with the dropdown
                  Expanded(
                    child: CustomTextField(
                      prefixIcon: LucideIcons.search,
                      hint: 'Filter by name or SKU...',
                      onChanged: (v) => provider.setSearchQuery(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Category filter using AppDropdown, fixed width for clean parallel look
                  SizedBox(
                    width: 220,
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
            ),
            const Divider(height: 1),
            if (provider.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (products.isEmpty)
              _buildEmptyState(context)
            else
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('SKU')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Unit')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: products.map((product) => _buildProductRow(context, product)).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  DataRow _buildProductRow(BuildContext context, dynamic product) {
    return DataRow(
      cells: [
        DataCell(Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(product.baseSku)),
        DataCell(Text('Category ID: ${product.categoryId}')), // Replace with category name lookup if needed
        DataCell(Text(product.unitType)),
        DataCell(BadgeWidget(
          label: product.isActive ? 'Active' : 'Inactive',
          type: product.isActive ? BadgeType.success : BadgeType.error,
        )),
        DataCell(
          Row(
            children: [
              IconButton(icon: const Icon(LucideIcons.eye, size: 18), onPressed: () {}),
              IconButton(icon: const Icon(LucideIcons.pencil, size: 18), onPressed: () {}),
            ],
          ),
        ),
      ],
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
