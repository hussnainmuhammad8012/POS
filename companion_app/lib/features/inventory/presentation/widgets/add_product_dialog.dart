import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:companion_app/core/theme/app_theme.dart';
import 'package:companion_app/core/widgets/custom_text_field.dart';
import 'package:companion_app/core/widgets/app_dropdown.dart';
import 'package:companion_app/features/inventory/application/inventory_provider.dart';
import 'package:companion_app/features/inventory/presentation/screens/scanner_screen.dart';

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
    return AlertDialog(
      backgroundColor: AppColors.STAR_BACKGROUND,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.STAR_PRIMARY,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.packagePlus, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Add New Product', style: TextStyle(color: Colors.white, fontSize: 18)),
            const Spacer(),
            IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 0 
                      ? _buildIdentityStep() 
                      : (_currentStep == 1 ? _buildPricingStep() : _buildStockStep()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        if (_currentStep > 0)
          TextButton(
            onPressed: _isSaving ? null : () => setState(() => _currentStep--),
            child: const Text('Back', style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY)),
          ),
        const Spacer(),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.STAR_PRIMARY,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSaving ? null : _handleNext,
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(_currentStep < 2 ? 'Next Step' : 'Create Product'),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildIndicatorPoint(0, 'Identity'),
        _buildIndicatorLine(0),
        _buildIndicatorPoint(1, 'Pricing'),
        _buildIndicatorLine(1),
        _buildIndicatorPoint(2, 'Stock'),
      ],
    );
  }

  Widget _buildIndicatorPoint(int index, String label) {
    bool isActive = _currentStep == index;
    bool isCompleted = _currentStep > index;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.SUCCESS : (isActive ? AppColors.STAR_PRIMARY : AppColors.STAR_BORDER),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted 
                ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                : Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: isActive ? AppColors.STAR_PRIMARY : AppColors.STAR_TEXT_SECONDARY)),
        ],
      ),
    );
  }

  Widget _buildIndicatorLine(int afterIndex) {
    bool isCompleted = _currentStep > afterIndex;
    return Container(
      width: 20,
      height: 2,
      color: isCompleted ? AppColors.SUCCESS : AppColors.STAR_BORDER,
    );
  }

  Widget _buildIdentityStep() {
    final provider = context.watch<InventoryProvider>();
    return Column(
      key: const ValueKey(0),
      children: [
        AppDropdown<String>(
          label: 'Category',
          hint: 'Select Category',
          prefixIcon: LucideIcons.folder,
          value: _selectedCategoryId,
          isRequired: true,
          items: provider.categories.map((c) => AppDropdownItem<String>(
            value: c.id,
            label: c.name,
            icon: LucideIcons.tag,
          )).toList(),
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
        CustomTextField(
          controller: _skuController,
          label: 'Base SKU',
          prefixIcon: LucideIcons.hash,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _descriptionController,
          label: 'Description (Optional)',
          prefixIcon: LucideIcons.alignLeft,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPricingStep() {
    return Column(
      key: const ValueKey(1),
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _barcodeController,
                label: 'Barcode / SKU',
                prefixIcon: LucideIcons.scan,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.STAR_PRIMARY.withOpacity(0.1),
                  foregroundColor: AppColors.STAR_PRIMARY,
                  elevation: 0,
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: _openScanner,
                child: const Icon(LucideIcons.camera),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _costPriceController,
                label: 'Cost Price',
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.banknote,
                validator: (v) => v == null || double.tryParse(v) == null ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _retailPriceController,
                label: 'Retail Price',
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.tag,
                validator: (v) => v == null || double.tryParse(v) == null ? 'Required' : null,
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
                label: 'Wholesale',
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.users,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _mrpController,
                label: 'MRP (Optional)',
                keyboardType: TextInputType.number,
                prefixIcon: LucideIcons.shieldCheck,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _unitController,
          label: 'Unit Type',
          prefixIcon: LucideIcons.layers,
          hint: 'Pieces, Kg, Liter, etc.',
        ),
      ],
    );
  }

  Widget _buildStockStep() {
    return Column(
      key: const ValueKey(2),
      children: [
        CustomTextField(
          controller: _initialStockController,
          label: 'Initial Stock Pieces',
          keyboardType: TextInputType.number,
          prefixIcon: LucideIcons.boxes,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _lowStockThresholdController,
          label: 'Low Stock Alert Threshold',
          keyboardType: TextInputType.number,
          prefixIcon: LucideIcons.alertTriangle,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.STAR_PRIMARY.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.STAR_PRIMARY.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info, color: AppColors.STAR_PRIMARY, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This will initialize the primary variant with the given stock levels.',
                  style: TextStyle(fontSize: 12, color: AppColors.STAR_TEXT_SECONDARY),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          onScan: (barcode) {
            setState(() {
              _barcodeController.text = barcode;
            });
          },
        ),
      ),
    );
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<InventoryProvider>();
    
    bool success = false;
    try {
      success = await provider.addProduct(
        categoryId: _selectedCategoryId!,
        name: _nameController.text,
        baseSku: _skuController.text,
        description: _descriptionController.text,
        unitType: _unitController.text,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        costPrice: double.parse(_costPriceController.text),
        retailPrice: double.parse(_retailPriceController.text),
        wholesalePrice: double.tryParse(_wholesalePriceController.text),
        mrp: double.tryParse(_mrpController.text),
        initialStock: int.tryParse(_initialStockController.text) ?? 0,
        lowStockThreshold: int.tryParse(_lowStockThresholdController.text) ?? 10,
      );
    } catch (e) {
      debugPrint('Add product error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product Created!'), 
            backgroundColor: AppColors.SUCCESS,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create product'), 
            backgroundColor: AppColors.DANGER,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
