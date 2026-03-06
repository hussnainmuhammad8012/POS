import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../application/inventory_provider.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/theme/app_theme.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1: Identity
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedImagePath; // replaces the text path field
  String? _selectedCategoryId;

  // Step 2: Pricing & Units
  final _unitController = TextEditingController(text: 'Pieces');
  final _barcodeController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _mrpController = TextEditingController();

  // Step 3: Stock Management
  final _initialStockController = TextEditingController(text: '0');
  final _lowStockThresholdController = TextEditingController(text: '10');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.packagePlus, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          const Text('New Product Creation'),
        ],
      ),
      content: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 24),
            Flexible(
              child: Theme(
                data: Theme.of(context).copyWith(
                  scrollbarTheme: ScrollbarThemeData(
                    thumbColor: WidgetStateProperty.all(Theme.of(context).primaryColor.withOpacity(0.3)),
                    thickness: WidgetStateProperty.all(6),
                    radius: const Radius.circular(3),
                  ),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Form(
                        key: _formKey,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentStep == 0 
                            ? _buildStepOne(provider) 
                            : (_currentStep == 1 ? _buildStepTwo() : _buildStepThree()),
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
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_currentStep > 0)
          OutlinedButton(
            onPressed: _isSaving ? null : () => setState(() => _currentStep--),
            child: const Text('Previous'),
          ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _handleNext(provider),
          child: _isSaving 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(_currentStep < 2 ? 'Next' : 'Create Product'),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _indicatorItem(0, 'Identity', LucideIcons.tag),
        _indicatorLine(),
        _indicatorItem(1, 'Pricing', LucideIcons.coins),
        _indicatorLine(),
        _indicatorItem(2, 'Stock', LucideIcons.boxes),
      ],
    );
  }

  Widget _indicatorItem(int index, String label, IconData icon) {
    bool isActive = _currentStep == index;
    bool isCompleted = _currentStep > index;
    Color color = isActive || isCompleted 
        ? Theme.of(context).primaryColor 
        : Colors.grey.shade400;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(isCompleted ? Icons.check : icon, size: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicatorLine() {
    return Container(
      width: 20, // Slightly shorter for 3 steps
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.grey.shade300,
    );
  }

  Widget _buildStepOne(InventoryProvider provider) {
    return Column(
      key: const ValueKey(0),
      mainAxisSize: MainAxisSize.min,
      children: [
        AppDropdown<String>(
          label: 'Product Category',
          hint: 'Select a category',
          prefixIcon: LucideIcons.folderTree,
          value: _selectedCategoryId,
          isRequired: true,
          validator: (v) => v == null ? 'Please select a category' : null,
          items: provider.categories.expand((c) => [
            AppDropdownItem<String>(
              value: c.id,
              label: c.name,
              icon: LucideIcons.folder,
              isGroupHeader: false,
            ),
            ...c.subcategories.map((s) => AppDropdownItem<String>(
              value: s.id,
              label: s.name,
              subtitle: c.name,
              icon: LucideIcons.folderOpen,
            )),
          ]).toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _nameController,
          label: 'Product Name',
          prefixIcon: LucideIcons.package,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _skuController,
                label: 'Base SKU',
                prefixIcon: LucideIcons.tag,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _unitController,
                label: 'Unit Type',
                prefixIcon: LucideIcons.hash,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _descriptionController,
          label: 'Description (Optional)',
          maxLines: 2,
          prefixIcon: LucideIcons.text,
        ),
        const SizedBox(height: 16),
        _buildImagePicker(),
      ],
    );
  }

  Widget _buildImagePicker() {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;

    return GestureDetector(
      onTap: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          setState(() => _selectedImagePath = result.files.single.path);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 110,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedImagePath != null ? primary : Colors.grey.shade300,
            width: _selectedImagePath != null ? 1.5 : 1,
            style: BorderStyle.solid,
          ),
        ),
        child: _selectedImagePath != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(
                      File(_selectedImagePath!),
                      width: double.infinity,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImagePath = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.imagePlus, size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Click to upload product image',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PNG, JPG, WEBP',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStepTwo() {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _costPriceController,
                label: 'Cost Price',
                prefixIcon: LucideIcons.arrowDownCircle,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid price' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _retailPriceController,
                label: 'Retail Price',
                prefixIcon: LucideIcons.arrowUpCircle,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid price' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _wholesalePriceController,
                label: 'Wholesale Price',
                prefixIcon: LucideIcons.users,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _mrpController,
                label: 'MRP',
                prefixIcon: LucideIcons.shieldCheck,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _barcodeController,
          label: 'Product Barcode',
          prefixIcon: LucideIcons.scanLine,
          hint: 'Scan or enter barcode...',
        ),
      ],
    );
  }

  Widget _buildStepThree() {
    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _initialStockController,
                label: 'Initial Stock (Pieces)',
                prefixIcon: LucideIcons.packageCheck,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid quantity' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _lowStockThresholdController,
                label: 'Low Stock Alert',
                prefixIcon: LucideIcons.alertTriangle,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid threshold' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.info, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'This will initialize your live inventory. You can manage cartons and batches later in the Stock tab.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleNext(InventoryProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      setState(() => _isSaving = true);
      try {
        // 1. Create Product
        final productId = await provider.createProduct(
          categoryId: _selectedCategoryId!,
          name: _nameController.text,
          baseSku: _skuController.text,
          description: _descriptionController.text,
          mainImagePath: _selectedImagePath,
          unitType: _unitController.text,
        );

        // 2. Create Default Variant with Stock
        await provider.createProductVariant(
          productId: productId,
          variantName: 'Default',
          sku: '${_skuController.text}-DEF',
          barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
          costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
          retailPrice: double.tryParse(_retailPriceController.text) ?? 0.0,
          wholesalePrice: _wholesalePriceController.text.isEmpty ? null : double.tryParse(_wholesalePriceController.text),
          mrp: _mrpController.text.isEmpty ? null : double.tryParse(_mrpController.text),
          initialStock: int.tryParse(_initialStockController.text) ?? 0,
          lowStockThreshold: int.tryParse(_lowStockThresholdController.text) ?? 10,
        );

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.DANGER),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }
}
