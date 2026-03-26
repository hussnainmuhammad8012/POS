import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:companion_app/features/auth/application/auth_provider.dart';
import 'package:companion_app/features/inventory/application/inventory_provider.dart';
import 'package:companion_app/core/theme/app_theme.dart';
import 'package:companion_app/core/widgets/custom_text_field.dart';
import 'package:companion_app/features/inventory/data/models/product_model.dart';
import 'package:companion_app/features/inventory/data/models/category_model.dart';
import 'package:companion_app/features/inventory/data/models/stock_movement_model.dart';
import 'package:companion_app/features/inventory/presentation/widgets/add_product_dialog.dart';
import 'package:companion_app/features/inventory/presentation/widgets/edit_product_dialog.dart';
import 'package:companion_app/features/inventory/presentation/widgets/add_edit_category_dialog.dart';
import 'package:companion_app/features/inventory/presentation/widgets/mobile_print_label_dialog.dart';
import 'package:companion_app/core/widgets/app_dropdown.dart';
import 'package:companion_app/features/inventory/presentation/widgets/add_supplier_dialog.dart';
import 'package:companion_app/features/inventory/presentation/widgets/product_details_dialog.dart';
import 'package:companion_app/features/inventory/data/models/product_unit_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _catSearchController = TextEditingController();
  String _selectedMovementType = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2) {
        context.read<InventoryProvider>().fetchStockMovements(type: _selectedMovementType);
      }
    });
    Future.microtask(() => context.read<InventoryProvider>().fetchInventory());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _catSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final auth = context.watch<AuthProvider>();

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
            Text(auth.shopName ?? 'Inventory Manager', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(auth.serverIp ?? 'Local Server', style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () {
               inventory.fetchInventory();
               if (_tabController.index == 2) {
                 inventory.fetchStockMovements(type: _selectedMovementType);
               }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Products', icon: Icon(LucideIcons.package, size: 20)),
            Tab(text: 'Categories', icon: Icon(LucideIcons.folder, size: 20)),
            Tab(text: 'Stock Log', icon: Icon(LucideIcons.history, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(inventory),
          _buildCategoriesTab(inventory),
          _buildStockLogTab(inventory),
        ],
      ),
      floatingActionButton: _tabController.index != 2 
        ? FloatingActionButton(
            backgroundColor: AppColors.STAR_PRIMARY,
            child: const Icon(LucideIcons.plus, color: Colors.white),
            onPressed: () {
              if (_tabController.index == 0) {
                _showAddProduct();
              } else {
                _showAddCategory();
              }
            },
          )
        : null,
    );
  }

  // ── PRODUCTS TAB ──

  Widget _buildProductsTab(InventoryProvider inventory) {
    final filteredProducts = inventory.products.where((p) {
      final query = _searchController.text.toLowerCase();
      return p.name.toLowerCase().contains(query) || p.baseSku.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        _buildSearchBar(_searchController, 'Search products by name or SKU...'),
        Expanded(
          child: inventory.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildProductList(filteredProducts),
        ),
      ],
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.pencil, size: 18, color: AppColors.STAR_TEXT_SECONDARY),
                  onPressed: () => _showEditProduct(p),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.printer, size: 18, color: AppColors.STAR_PRIMARY),
                  onPressed: () => _showPrintLabel(p),
                ),
              ],
            ),
            onTap: () {
              _showProductDetails(p);
            },
          ),
        );
      },
    );
  }

  // ── CATEGORIES TAB ──

  Widget _buildCategoriesTab(InventoryProvider inventory) {
    final query = _catSearchController.text.toLowerCase();
    final filteredCategories = inventory.categories.where((c) => c.name.toLowerCase().contains(query)).toList();

    return Column(
      children: [
        _buildSearchBar(_catSearchController, 'Search categories...'),
        Expanded(
          child: inventory.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildCategoryList(filteredCategories),
        ),
      ],
    );
  }

  Widget _buildCategoryList(List<Category> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories found', style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: const Icon(LucideIcons.folder, color: AppColors.STAR_PRIMARY),
            title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(cat.description ?? '${cat.subcategories.length} subcategories', style: const TextStyle(fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 IconButton(
                   icon: const Icon(LucideIcons.pencil, size: 18),
                   onPressed: () => _showEditCategory(cat),
                 ),
                 IconButton(
                   icon: const Icon(LucideIcons.plusCircle, size: 18, color: AppColors.STAR_PRIMARY),
                   onPressed: () => _showAddSubcategory(cat),
                 ),
              ],
            ),
            children: cat.subcategories.map((sub) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 32),
              leading: const Icon(LucideIcons.folderOpen, size: 16, color: Colors.blueGrey),
              title: Text(sub.name, style: const TextStyle(fontSize: 13)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   IconButton(icon: const Icon(LucideIcons.pencil, size: 16), onPressed: () => _showEditCategory(sub)),
                   IconButton(icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.DANGER), onPressed: () => _confirmDeleteCategory(sub)),
                ],
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  // ── STOCK LOG TAB ──

  Widget _buildStockLogTab(InventoryProvider inventory) {
    // Filter out Adjustment, Return, and Damage as requested?
    // User said: "remove the adjustment and return and damage products"
    final movements = inventory.stockMovements.where((m) {
      final reason = m.reason.toLowerCase();
      // Exclude Adjustment and Damage as per early preference, 
      // but include Returns as now requested for desktop parity.
      return !reason.contains('adjustment') && 
             !reason.contains('damage');
    }).toList();

    if (inventory.isLoading && movements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (movements.isEmpty) {
      return const Center(child: Text('No relevant movements found', style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY)));
    }

    return RefreshIndicator(
      onRefresh: () => inventory.fetchStockMovements(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: movements.length,
        itemBuilder: (context, index) {
          final m = movements[index];
          final isReturn = m.reason.toLowerCase().startsWith('returned');
          final isIn = m.quantityChange > 0;
          
          Color iconColor;
          IconData icon;
          
          if (isReturn) {
            iconColor = Colors.orange;
            icon = LucideIcons.cornerDownLeft;
          } else if (isIn) {
            iconColor = Colors.green;
            icon = LucideIcons.arrowDownLeft;
          } else {
            iconColor = Colors.red;
            icon = LucideIcons.arrowUpRight;
          }

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              title: Text(m.productName ?? 'Unknown Product', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.reason, style: const TextStyle(fontSize: 12)),
                  Text(DateFormat('MMM dd, hh:mm a').format(m.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.STAR_TEXT_SECONDARY)),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    '${isIn ? "+" : ""}${m.quantityChange}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: iconColor, fontSize: 16),
                  ),
                  Text('Bal: ${m.quantityAfter}', style: const TextStyle(fontSize: 10, color: AppColors.STAR_TEXT_SECONDARY)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── HELPER WIDGETS ──

  Widget _buildSearchBar(TextEditingController controller, String hint) {
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
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (v) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: const Icon(LucideIcons.search, color: Colors.white, size: 18),
          ),
        ),
      ),
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

    return Text('Stock: ${parts.join(', ')}', style: _getStockStyle(p.currentStock));
  }

  TextStyle _getStockStyle(int stock) {
     return TextStyle(
       fontSize: 12,
       color: stock <= 5 ? AppColors.DANGER : AppColors.STAR_TEXT_SECONDARY,
       fontWeight: stock <= 5 ? FontWeight.bold : FontWeight.normal,
     );
  }

  // ── DIALOG HELPERS ──

  void _showAddProduct() {
    final provider = context.read<InventoryProvider>();
    showDialog(
      context: context, 
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: const AddProductDialog(),
      ),
    );
  }

  void _showEditProduct(Product p) {
    final provider = context.read<InventoryProvider>();
    showDialog(
      context: context, 
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: EditProductDialog(product: p),
      ),
    );
  }

  void _showPrintLabel(Product p) {
    final provider = context.read<InventoryProvider>();
    showDialog(
      context: context, 
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: MobilePrintLabelDialog(product: p),
      ),
    );
  }

  void _showProductDetails(Product p) {
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
  }

  void _showAddCategory() {
    final provider = context.read<InventoryProvider>();
    showDialog(
      context: context, 
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: const AddEditCategoryDialog(),
      ),
    );
  }

  void _showAddSubcategory(Category parent) {
    final provider = context.read<InventoryProvider>();
    showDialog(
      context: context, 
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: AddEditCategoryDialog(parentId: parent.id),
      ),
    );
  }

  void _showEditCategory(Category cat) {
    final provider = context.read<InventoryProvider>();
    showDialog(
      context: context, 
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: AddEditCategoryDialog(category: cat),
      ),
    );
  }

  void _confirmDeleteCategory(Category cat) {
    final provider = context.read<InventoryProvider>();
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "${cat.name}"? This will not delete products but they will become uncategorized.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final error = await provider.deleteCategory(cat.id);
                if (error != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.DANGER));
                }
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.DANGER)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStockDialog(Product product) {
    final inventoryProvider = context.read<InventoryProvider>();
    final hasUnits = product.units.isNotEmpty;
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
    final reasonController = TextEditingController(text: 'Stock added from mobile');
    final formKey = GlobalKey<FormState>();
    
    ProductUnit selectedUnit = baseUnit;
    String? selectedSupplierId;
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: inventoryProvider,
        child: StatefulBuilder(
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
                         Text('Add Stock: ${product.name}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                         Text('Current: ${product.currentStock} ${baseUnit.unitName}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                       ],
                     ),
                   ),
                   IconButton(icon: const Icon(LucideIcons.x, color: Colors.white, size: 20), onPressed: () => Navigator.pop(dialogContext)),
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
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Qty',
                              controller: qtyController,
                              keyboardType: TextInputType.number,
                              prefixIcon: LucideIcons.boxes,
                              validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null) ? 'Required' : null,
                            ),
                          ),
                          if (inventoryProvider.isUomEnabled && hasUnits) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppDropdown<ProductUnit>(
                                label: 'Unit',
                                value: selectedUnit,
                                items: product.units.map((u) => AppDropdownItem<ProductUnit>(
                                  value: u,
                                  label: u.unitName,
                                  icon: LucideIcons.package,
                                )).toList(),
                                onChanged: (v) { if (v != null) setState(() => selectedUnit = v); },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(label: 'Notes', controller: reasonController, prefixIcon: LucideIcons.fileText),
                      const SizedBox(height: 12),
                      AppDropdown<String>(
                        label: 'Supplier (Opt)',
                        value: selectedSupplierId,
                        items: inventoryProvider.suppliers.map((s) => AppDropdownItem<String>(value: s.id, label: s.name, icon: LucideIcons.user)).toList(),
                        onChanged: (v) => setState(() => selectedSupplierId = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final totalBasePieces = (int.parse(qtyController.text) * selectedUnit.conversionRate).toInt();
                  final success = await inventoryProvider.updateStock(product.id, totalBasePieces, reasonController.text);
                  if (dialogContext.mounted && success) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock updated!'), backgroundColor: AppColors.STAR_PRIMARY));
                  }
                },
                child: const Text('Add Stock'),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}

