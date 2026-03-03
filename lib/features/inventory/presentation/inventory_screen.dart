import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/entities.dart';
import '../../../core/theme/app_theme.dart';
import '../application/inventory_provider.dart';

class InventoryScreen extends StatelessWidget {
  static const routeName = '/inventory';

  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Categories'),
                      Tab(text: 'Products'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _CategoriesTab(inventory: inventory),
                        _ProductsTab(inventory: inventory),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  final InventoryProvider inventory;

  const _CategoriesTab({required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showCategoryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: inventory.categories.isEmpty
              ? const _EmptyState(
                  icon: Icons.category_outlined,
                  message:
                      'No categories yet.\nCreate your first category to organize products.',
                )
              : ListView.separated(
                  itemCount: inventory.categories.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final category = inventory.categories[index];
                    return ListTile(
                      leading: const Icon(Icons.category),
                      title: Text(category.name),
                      subtitle: Text(
                        category.description ?? 'No description',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _showCategoryDialog(context,
                                    existing: category),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () async {
                              final confirmed =
                                  await showDialog<bool>(
                                        context: context,
                                        builder: (context) =>
                                            AlertDialog(
                                          title:
                                              const Text('Delete Category'),
                                          content: Text(
                                            'Are you sure you want to delete "${category.name}"?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text('No'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: const Text('Yes'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                              if (confirmed) {
                                inventory.deleteCategory(category);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Category deleted successfully.'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context, {
    Category? existing,
  }) async {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              existing == null ? 'Add Category' : 'Edit Category',
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final now = DateTime.now();
                  final category = Category(
                    id: existing?.id,
                    name: nameController.text.trim(),
                    description:
                        descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                    iconName: null,
                    createdAt: existing?.createdAt ?? now,
                  );
                  Provider.of<InventoryProvider>(context,
                          listen: false)
                      .upsertCategory(category);
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.check),
                label: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Category added successfully!'
                : 'Category updated successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _ProductsTab extends StatelessWidget {
  final InventoryProvider inventory;

  const _ProductsTab({required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search by name or barcode',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: inventory.setSearchQuery,
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int?>(
              value: inventory.selectedCategoryId,
              hint: const Text('Filter by category'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All categories'),
                ),
                ...inventory.categories.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.name),
                  ),
                ),
              ],
              onChanged: inventory.setSelectedCategory,
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () =>
                  _showProductDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              // Bulk import CSV/XLSX would be wired here.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Bulk import from Excel is not wired yet.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Import from Excel'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: inventory.filteredProducts.isEmpty
              ? const _EmptyState(
                  icon: Icons.inventory_2_outlined,
                  message:
                      'No products yet.\nClick "Add Product" to start building your catalog.',
                )
              : Card(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Image')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Barcode')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Stock')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: inventory.filteredProducts.map((product) {
                        final lowStock = product.currentStock <=
                            product.lowStockThreshold;
                        return DataRow(
                          color: lowStock
                              ? MaterialStateProperty.all(
                                  AppColors.warning.withOpacity(0.08),
                                )
                              : null,
                          cells: [
                            const DataCell(
                              Icon(Icons.image,
                                  color: AppColors.textSecondary),
                            ),
                            DataCell(Text(product.name)),
                            DataCell(Text(product.barcode ?? '-')),
                            DataCell(Text(
                                '₹${product.sellingPrice.toStringAsFixed(2)}')),
                            DataCell(
                              Text(
                                product.currentStock.toString(),
                                style: TextStyle(
                                  color: lowStock
                                      ? AppColors.warning
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _showProductDialog(
                                      context,
                                      existing: product,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () async {
                                      final confirmed =
                                          await showDialog<bool>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      'Delete Product'),
                                                  content: Text(
                                                    'Are you sure you want to delete "${product.name}"?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(false),
                                                      child:
                                                          const Text('No'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(true),
                                                      child:
                                                          const Text('Yes'),
                                                    ),
                                                  ],
                                                ),
                                              ) ??
                                              false;
                                      if (confirmed) {
                                        Provider.of<InventoryProvider>(
                                                context,
                                                listen: false)
                                            .deleteProduct(product);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Product deleted successfully.'),
                                            backgroundColor:
                                                AppColors.error,
                                          ),
                                        );
                                      }
                                    },
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
        ),
      ],
    );
  }

  Future<void> _showProductDialog(
    BuildContext context, {
    Product? existing,
  }) async {
    final inventory =
        Provider.of<InventoryProvider>(context, listen: false);

    final barcodeController =
        TextEditingController(text: existing?.barcode ?? '');
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final priceController =
        TextEditingController(
            text: existing?.sellingPrice.toStringAsFixed(2) ?? '');
    final costController =
        TextEditingController(
            text: existing?.costPrice?.toStringAsFixed(2) ?? '');
    final stockController =
        TextEditingController(
            text: existing?.currentStock.toString() ?? '0');
    final lowStockController =
        TextEditingController(
            text:
                existing?.lowStockThreshold.toString() ?? '5');

    int? categoryId = existing?.categoryId;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              existing == null ? 'Add Product' : 'Edit Product',
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: barcodeController,
                            decoration: InputDecoration(
                              labelText: 'Barcode',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.qr_code_2),
                                tooltip: 'Generate random barcode',
                                onPressed: () {
                                  barcodeController.text =
                                      DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toString();
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Product name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      value: categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: inventory.categories
                          .map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => categoryId = v,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      validator: (value) {
                        final v = double.tryParse(value ?? '');
                        if (v == null) {
                          return 'Price must be a number';
                        }
                        if (v < 0) {
                          return 'Price cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: costController,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: stockController,
                      decoration: const InputDecoration(
                        labelText: 'Current Stock',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final v = int.tryParse(value ?? '');
                        if (v == null) {
                          return 'Stock must be a number';
                        }
                        if (v < 0) {
                          return 'Stock cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: lowStockController,
                      decoration: const InputDecoration(
                        labelText: 'Low Stock Alert Threshold',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          // Image upload would use file_picker here.
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Image upload not wired yet.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Upload Image'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final product = Product(
                    id: existing?.id,
                    barcode: barcodeController.text.trim().isEmpty
                        ? null
                        : barcodeController.text.trim(),
                    name: nameController.text.trim(),
                    categoryId: categoryId,
                    sellingPrice:
                        double.parse(priceController.text),
                    costPrice: costController.text.trim().isEmpty
                        ? null
                        : double.parse(costController.text),
                    currentStock:
                        int.parse(stockController.text),
                    lowStockThreshold:
                        int.tryParse(lowStockController.text) ??
                            5,
                    imagePath: null,
                    createdAt: existing?.createdAt ??
                        DateTime.now(),
                    updatedAt: existing != null
                        ? DateTime.now()
                        : null,
                  );
                  inventory.upsertProduct(product);
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.check),
                label: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Product added successfully!'
                : 'Product updated successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

