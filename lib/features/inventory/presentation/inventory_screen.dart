import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/glass_header.dart';
import '../application/inventory_provider.dart';
import '../application/stock_provider.dart';
import 'widgets/category_tab.dart';
import 'widgets/products_tab.dart';
import 'widgets/stock_tab.dart';
import 'widgets/add_category_dialog.dart';
import 'widgets/add_product_dialog.dart';

class InventoryScreen extends StatefulWidget {
  static const routeName = '/inventory';

  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize providers when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().initialize();
      context.read<StockProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassHeader(
          title: 'Inventory',
          subtitle: 'Manage stock and product catalog',
          actions: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.download),
              label: const Text('Export'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add New'),
            ),
          ],
        ),
        const Expanded(
          child: _InventoryTabs(),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What would you like to add?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.package),
              title: const Text('New Product'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const AddProductDialog(),
                );
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.folder),
              title: const Text('New Category'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const AddCategoryDialog(),
                );
              },
            ),
          ],
        ),
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
          height: 50,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.shade300,
              ),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelPadding: const EdgeInsets.symmetric(horizontal: 24),
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              tabs: const [
                Tab(text: 'Products'),
                Tab(text: 'Categories'),
                Tab(text: 'Stock Movements'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              ProductsTab(),
              CategoryTab(),
              StockTab(),
            ],
          ),
        ),
      ],
    );
  }
}
