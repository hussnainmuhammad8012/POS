import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/models/entities.dart';
import '../../../core/widgets/badge_widget.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../application/inventory_provider.dart';

class InventoryScreen extends StatelessWidget {
  static const routeName = '/inventory';

  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassHeader(
            title: 'Inventory',
            subtitle: 'Manage stock and product catalog',
            actions: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(LucideIcons.download),
                label: const Text('Export'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(LucideIcons.plus),
                label: const Text('Add Product'),
              ),
            ],
          ),
          const Expanded(
            child: _InventoryTabs(),
          ),
        ],
      ),
    );
  }
}

class _InventoryTabs extends StatefulWidget {
  const _InventoryTabs();

  @override
  State<_InventoryTabs> createState() => _InventoryTabsState();
}

class _InventoryTabsState extends State<_InventoryTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerTheme.color!,
              ),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 2,
              labelColor: Theme.of(context).textTheme.bodyLarge?.color,
              unselectedLabelColor: Theme.of(context).colorScheme.secondary,
              tabs: const [
                Text('Products'),
                Text('Categories'),
                Text('Stock Movements'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ProductsTab(),
              Center(child: Text('Categories Content')),
              Center(child: Text('Stock Movements Content')),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final products = provider.products.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.barcode != null && p.barcode!.contains(_searchQuery));
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ModernCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomTextField(
                label: 'Search Products',
                prefixIcon: LucideIcons.search,
                hint: 'Filter by name or barcode...',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const Divider(height: 1),
            if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(LucideIcons.packageSearch, size: 48, color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No products found', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    dividerThickness: 1,
                    headingRowColor: WidgetStateProperty.resolveWith(
                      (states) => Theme.of(context).scaffoldBackgroundColor,
                    ),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Barcode')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Stock')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('')),
                    ],
                    rows: products.map((product) {
                      final bool isLow = product.currentStock <= product.lowStockThreshold;
                      final bool isOut = product.currentStock <= 0;
                      
                      BadgeType type = BadgeType.success;
                      String label = 'In Stock';
                      if (isOut) {
                        type = BadgeType.error;
                        label = 'Out of Stock';
                      } else if (isLow) {
                        type = BadgeType.warning;
                        label = 'Low Stock';
                      }

                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Theme.of(context).dividerTheme.color!),
                                  ),
                                  child: Icon(LucideIcons.package, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            )
                          ),
                          DataCell(Text(product.barcode ?? '-', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary))),
                          DataCell(Text('Rs ${product.sellingPrice.toStringAsFixed(2)}')),
                          DataCell(Text(product.currentStock.toString())),
                          DataCell(BadgeWidget(label: label, type: type)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(LucideIcons.pencil, size: 18),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(LucideIcons.trash2, size: 18, color: Theme.of(context).colorScheme.error),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
