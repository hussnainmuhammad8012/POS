import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:companion_app/features/auth/application/auth_provider.dart';
import 'package:companion_app/features/inventory/application/inventory_provider.dart';
import 'package:companion_app/core/theme/app_theme.dart';
import 'package:companion_app/core/widgets/custom_text_field.dart';
import 'package:companion_app/features/inventory/presentation/widgets/add_product_dialog.dart';
import 'package:companion_app/features/inventory/data/models/product_model.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final auth = context.watch<AuthProvider>();

    final filteredProducts = inventory.products.where((p) {
      final query = _searchController.text.toLowerCase();
      return p.name.toLowerCase().contains(query) || p.baseSku.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.STAR_BACKGROUND,
      appBar: AppBar(
        backgroundColor: AppColors.STAR_PRIMARY,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => auth.resetMode(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              auth.shopName ?? 'Inventory Manager', 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            Text(
              auth.serverIp ?? 'Local Server', 
              style: const TextStyle(fontSize: 10, color: AppColors.STAR_TEXT_SECONDARY),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => inventory.fetchInventory(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.plusCircle),
            onPressed: () {
              final provider = context.read<InventoryProvider>();
              showDialog(
                context: context,
                builder: (context) => ChangeNotifierProvider.value(
                  value: provider,
                  child: const AddProductDialog(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: inventory.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildProductList(filteredProducts),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.STAR_PRIMARY,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          onChanged: (v) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search by name or SKU...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            icon: Icon(LucideIcons.search, color: Colors.white70, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    if (products.isEmpty) {
      return const Center(child: Text('No products found', style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                Text('SKU: ${p.baseSku}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  'Stock: ${p.currentStock} ${p.unitType}',
                  style: TextStyle(
                    fontSize: 13,
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
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.STAR_PRIMARY.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(LucideIcons.plus, size: 16, color: AppColors.STAR_PRIMARY),
                ),
              ],
            ),
            onTap: () => _showAddStockDialog(p),
          ),
        );
      },
    );
  }

  void _showAddStockDialog(Product product) {
    final qtyController = TextEditingController();
    final reasonController = TextEditingController(text: 'Restock from mobile');
    final formKey = GlobalKey<FormState>();
    final inventoryProvider = context.read<InventoryProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.packagePlus, color: AppColors.STAR_PRIMARY),
            const SizedBox(width: 12),
            Expanded(child: Text('Stock Update: ${product.name}', style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Adjustment Quantity',
                hint: 'e.g. 10 or -5',
                keyboardType: TextInputType.number,
                controller: qtyController,
                prefixIcon: LucideIcons.hash,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Reason for Adjustment',
                hint: 'e.g. Fresh stock, damage, etc.',
                controller: reasonController,
                prefixIcon: LucideIcons.text,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text('Cancel', style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.STAR_PRIMARY,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              final qty = int.parse(qtyController.text);
              final reason = reasonController.text;
              
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              
              bool success = false;
              try {
                success = await inventoryProvider.updateStock(
                  product.id,
                  qty,
                  reason,
                );
              } catch (e) {
                debugPrint('Update error: $e');
              } finally {
                navigator.pop(); // Close loading
              }
              
              if (success) {
                navigator.pop(); // Close adjustment dialog
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Stock Updated successfully!'), 
                    backgroundColor: AppColors.SUCCESS,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Update failed. Check connection.'), 
                    backgroundColor: AppColors.DANGER,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Update Stock'),
          ),
        ],
      ),
    );
  }
}
