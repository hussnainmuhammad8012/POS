import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../application/inventory_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import 'scanner_screen.dart';
import '../../data/models/product_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<InventoryProvider>().fetchInventory());
  }

  void _showAddStockDialog(Product product) {
    final qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stock Update: ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Add Quantity',
              hint: 'e.g. 10 or -5',
              keyboardType: TextInputType.number,
              controller: qtyController,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text);
              if (qty != null) {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                
                final success = await context.read<InventoryProvider>().updateStock(
                  product.id,
                  qty,
                  'Companion App Update',
                );
                
                if (success) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Stock Updated!'), backgroundColor: AppColors.SUCCESS),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.STAR_BACKGROUND,
      appBar: AppBar(
        title: const Text('Inventory Manager'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => context.read<InventoryProvider>().fetchInventory(),
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          final products = provider.products.where((p) => 
            p.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            p.baseSku.toLowerCase().contains(_searchController.text.toLowerCase())
          ).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CustomTextField(
                  hint: 'Search by Product Name or SKU...',
                  prefixIcon: LucideIcons.search,
                  onChanged: (v) => setState(() {}),
                  controller: _searchController,
                ),
              ),
              Expanded(
                child: provider.isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProductList(products),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScannerScreen(
                onScan: (sku) {
                  final provider = context.read<InventoryProvider>();
                  final product = provider.products.where((p) => p.baseSku == sku).firstOrNull;
                  if (product != null) {
                    _showAddStockDialog(product);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product not found'), backgroundColor: AppColors.DANGER),
                    );
                  }
                },
              ),
            ),
          );
        },
        backgroundColor: AppColors.STAR_PRIMARY,
        child: const Icon(LucideIcons.scanLine, color: Colors.white),
      ),
    );
  }

  Widget _buildProductList(List products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.packageSearch, size: 60, color: AppColors.STAR_TEXT_SECONDARY.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No products found', style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.STAR_BACKGROUND,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.package, color: AppColors.STAR_PRIMARY),
            ),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SKU: ${p.baseSku}'),
                Text(
                  'Stock: ${p.currentStock} ${p.unitType}',
                  style: TextStyle(
                    color: p.currentStock <= 5 ? AppColors.DANGER : AppColors.STAR_TEXT_SECONDARY,
                    fontWeight: p.currentStock <= 5 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Rs. ${p.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.STAR_PRIMARY),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.STAR_PRIMARY.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(LucideIcons.plus, size: 14, color: AppColors.STAR_PRIMARY),
                ),
              ],
            ),
            onTap: () => _showAddStockDialog(p),
          ),
        );
      },
    );
  }
}
