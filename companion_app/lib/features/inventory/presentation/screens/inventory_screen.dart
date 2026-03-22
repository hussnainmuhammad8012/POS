import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:companion_app/features/auth/application/auth_provider.dart';
import 'package:companion_app/features/inventory/application/inventory_provider.dart';
import 'package:companion_app/core/theme/app_theme.dart';
import 'package:companion_app/core/widgets/custom_text_field.dart';
import 'package:companion_app/features/inventory/data/models/product_model.dart';
import 'package:companion_app/features/inventory/presentation/widgets/add_product_dialog.dart';
import 'package:companion_app/core/widgets/app_dropdown.dart';
import 'package:companion_app/features/inventory/presentation/widgets/add_supplier_dialog.dart';
import 'package:companion_app/features/inventory/presentation/widgets/product_details_dialog.dart';
import 'package:companion_app/features/inventory/data/models/product_unit_model.dart';

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
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: (v) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search by name or SKU...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: const Icon(LucideIcons.search, color: Colors.white, size: 20),
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
                _buildStockDisplay(p),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Rs. ${p.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.STAR_PRIMARY, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Material(
                  color: AppColors.STAR_PRIMARY.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _showAddStockDialog(p),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.plus, size: 14, color: AppColors.STAR_PRIMARY),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.package, size: 14, color: AppColors.STAR_PRIMARY),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              final provider = context.read<InventoryProvider>();
              showDialog(
                context: context,
                builder: (context) => ChangeNotifierProvider.value(
                  value: provider,
                  child: ProductDetailsDialog(
                    product: p,
                    onAddStock: () => _showAddStockDialog(p),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStockDisplay(Product p) {
    final inventoryProvider = context.read<InventoryProvider>();
    if (!inventoryProvider.isUomEnabled || p.units.isEmpty) {
      return Text('Stock: ${p.currentStock} ${p.unitType}', style: _getStockStyle(p.currentStock));
    }

    final baseUnit = p.units.firstWhere((u) => u.isBaseUnit, orElse: () => p.units.first);
    final multiplierUnits = p.units.where((u) => !u.isBaseUnit).toList()
      ..sort((a, b) => b.conversionRate.compareTo(a.conversionRate));

    if (multiplierUnits.isEmpty) {
      return Text('Stock: ${p.currentStock} ${baseUnit.unitName}', style: _getStockStyle(p.currentStock));
    }

    int remaining = p.currentStock;
    List<String> parts = [];

    for (var unit in multiplierUnits) {
       int rate = unit.conversionRate.toInt();
       if (rate > 0) {
         int count = remaining ~/ rate;
         if (count > 0) {
           parts.add('$count ${unit.unitName}');
           remaining %= rate;
         }
       }
    }

    if (remaining > 0 || parts.isEmpty) {
      parts.add('$remaining ${baseUnit.unitName}');
    }

    return Text(
      'Stock: ${parts.join(', ')}',
      style: _getStockStyle(p.currentStock),
    );
  }

  TextStyle _getStockStyle(int stock) {
     return TextStyle(
       fontSize: 13,
       color: stock <= 5 ? AppColors.DANGER : AppColors.STAR_TEXT_SECONDARY,
       fontWeight: stock <= 5 ? FontWeight.bold : FontWeight.normal,
     );
  }

  void _showAddStockDialog(Product product) {
    final inventoryProvider = context.read<InventoryProvider>();
    
    // Check if we need units. If UOM is disabled or no units found but UOM is enabled, handle gracefully.
    final hasUnits = product.units.isNotEmpty;
    
    // Create a fallback base unit if none exists (for old products)
    final baseUnit = hasUnits 
        ? product.units.firstWhere((u) => u.isBaseUnit, orElse: () => product.units.first)
        : ProductUnit(
            id: 'virtual_base',
            productId: product.id,
            unitName: product.unitType,
            conversionRate: 1,
            isBaseUnit: true,
            costPrice: 0,
            retailPrice: product.price,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

    final qtyController = TextEditingController();
    final totalCostController = TextEditingController(text: '0.0');
    final paidAmountController = TextEditingController(text: '0.0');
    final reasonController = TextEditingController(text: 'Purchased from mobile');
    final formKey = GlobalKey<FormState>();
    
    ProductUnit selectedUnit = baseUnit;
    String? selectedSupplierId;
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.STAR_BACKGROUND,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.STAR_PRIMARY,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                   const Icon(LucideIcons.package, color: Colors.white),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'Add Stock: ${product.name}', 
                           style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                         ),
                         Text(
                           'Current: ${product.currentStock} ${baseUnit.unitName}',
                           style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                         ),
                       ],
                     ),
                   ),
                   IconButton(
                     icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                     onPressed: () => Navigator.pop(dialogContext),
                   ),
                ],
              ),
            ),
            titlePadding: EdgeInsets.zero,
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              label: 'Quantity',
                              hint: 'e.g. 10',
                              keyboardType: TextInputType.number,
                              controller: qtyController,
                              prefixIcon: LucideIcons.boxes,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (int.tryParse(v) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          if (inventoryProvider.isUomEnabled && hasUnits) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: AppDropdown<ProductUnit>(
                                label: 'Unit',
                                hint: 'Select Unit',
                                prefixIcon: LucideIcons.layers,
                                value: selectedUnit,
                                items: product.units.map((u) => AppDropdownItem<ProductUnit>(
                                  value: u,
                                  label: u.unitName,
                                  subtitle: 'x${u.conversionRate.toInt()} ${baseUnit.unitName}',
                                  icon: u.isBaseUnit ? LucideIcons.box : LucideIcons.layers,
                                )).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => selectedUnit = v);
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Optional Notes',
                        hint: 'e.g. Purchased 10 ${selectedUnit.unitName}...',
                        controller: reasonController,
                        prefixIcon: LucideIcons.fileText,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppDropdown<String>(
                              label: 'Supplier (Optional)',
                              hint: 'Select Supplier',
                              prefixIcon: LucideIcons.truck,
                              value: selectedSupplierId,
                              items: inventoryProvider.suppliers.map((s) => AppDropdownItem<String>(
                                value: s.id,
                                label: '${s.name}${s.contactPerson != null && s.contactPerson!.isNotEmpty ? ' - ${s.contactPerson}' : ''}',
                                icon: LucideIcons.user,
                              )).toList(),
                              onChanged: (v) => setState(() => selectedSupplierId = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            margin: const EdgeInsets.only(top: 24),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.STAR_PRIMARY.withOpacity(0.1),
                                foregroundColor: AppColors.STAR_PRIMARY,
                                elevation: 0,
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (c) => const AddSupplierDialog(),
                                );
                              },
                              child: const Icon(LucideIcons.plusCircle, size: 20),
                            ),
                          ),
                        ],
                      ),
                      if (selectedSupplierId != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Total Cost',
                                keyboardType: TextInputType.number,
                                controller: totalCostController,
                                prefixIcon: LucideIcons.banknote,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'Paid Now',
                                keyboardType: TextInputType.number,
                                controller: paidAmountController,
                                prefixIcon: LucideIcons.coins,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: dueDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (date != null) {
                              setState(() => dueDate = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Due Date (For unpaid balance)',
                              prefixIcon: const Icon(LucideIcons.calendar),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              dueDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(dueDate!),
                              style: TextStyle(
                                color: dueDate == null ? Theme.of(context).hintColor : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext), 
                child: const Text('Cancel', style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.STAR_PRIMARY,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  final qty = int.parse(qtyController.text);
                  // COMPUTE REAL STOCK BASED ON UOM
                  final totalBasePieces = (qty * selectedUnit.conversionRate).toInt();
                  bool success = false;

                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final stockReason = '${reasonController.text} (Added $qty ${selectedUnit.unitName})';
                    if (selectedSupplierId != null) {
                      success = await inventoryProvider.receiveCarton(
                        productId: product.id,
                        quantity: totalBasePieces,
                        totalCost: double.tryParse(totalCostController.text) ?? 0,
                        paidAmount: double.tryParse(paidAmountController.text) ?? 0,
                        supplierId: selectedSupplierId,
                        notes: stockReason,
                        dueDate: dueDate,
                      );
                    } else {
                      success = await inventoryProvider.updateStock(
                        product.id, 
                        totalBasePieces, 
                        stockReason,
                      );
                    }
                  } finally {
                    Navigator.of(context).pop(); // Close loading
                  }

                  if (dialogContext.mounted && success) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stock updated successfully!'),
                        backgroundColor: AppColors.STAR_PRIMARY,
                      ),
                    );
                  }
                },
                child: const Text('Add Stock'),
              ),
            ],
          );
        },
      ),
    );
  }
}
