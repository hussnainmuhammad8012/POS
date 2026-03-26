import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:companion_app/core/theme/app_theme.dart';
import 'package:companion_app/core/widgets/custom_text_field.dart';
import 'package:companion_app/core/widgets/app_dropdown.dart';
import 'package:companion_app/features/inventory/application/inventory_provider.dart';
import 'package:companion_app/features/inventory/data/models/product_model.dart';
import 'package:companion_app/features/inventory/data/models/product_unit_model.dart';
import 'package:companion_app/core/utils/code_generator.dart';
import 'package:companion_app/features/inventory/presentation/screens/scanner_screen.dart';
import 'package:companion_app/features/inventory/presentation/widgets/add_supplier_dialog.dart';

class EditProductDialog extends StatefulWidget {
  final Product product;
  const EditProductDialog({super.key, required this.product});

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSaving = false;
  
  // Step 1: Identity
  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _descCtrl;
  String? _selectedCategoryId;
  String? _selectedSupplierId;

  // Step 2: Pricing & Base Unit
  late final TextEditingController _unitCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _qrCtrl;
  late final TextEditingController _costPriceCtrl;
  late final TextEditingController _retailPriceCtrl;
  late final TextEditingController _wholesalePriceCtrl;
  late final TextEditingController _mrpCtrl;
  late final TextEditingController _taxRateCtrl;

  // Step 3: Multipliers
  List<ProductUnit> _multiplierUnits = [];

  // Step 4: Stock Thresholds
  late final TextEditingController _thresholdCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p.name);
    _skuCtrl = TextEditingController(text: p.baseSku);
    _descCtrl = TextEditingController(text: p.description ?? '');
    _selectedCategoryId = p.categoryId;
    _selectedSupplierId = p.supplierId;

    _unitCtrl = TextEditingController(text: p.unitType);
    _barcodeCtrl = TextEditingController(text: p.barcode ?? '');
    _qrCtrl = TextEditingController(text: p.qrCode ?? '');
    
    // Find base unit for prices
    final baseUnit = p.units.firstWhere((u) => u.isBaseUnit, orElse: () => p.units.first);
    _costPriceCtrl = TextEditingController(text: baseUnit.costPrice.toString());
    _retailPriceCtrl = TextEditingController(text: baseUnit.retailPrice.toString());
    _wholesalePriceCtrl = TextEditingController(text: baseUnit.wholesalePrice?.toString() ?? '');
    _mrpCtrl = TextEditingController(text: baseUnit.mrp?.toString() ?? '');
    _taxRateCtrl = TextEditingController(text: baseUnit.taxRate.toString());

    _multiplierUnits = p.units.where((u) => !u.isBaseUnit).toList();
    _thresholdCtrl = TextEditingController(text: '10'); // Default or from model
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _descCtrl.dispose();
    _unitCtrl.dispose();
    _barcodeCtrl.dispose();
    _qrCtrl.dispose();
    _costPriceCtrl.dispose();
    _retailPriceCtrl.dispose();
    _wholesalePriceCtrl.dispose();
    _mrpCtrl.dispose();
    _taxRateCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUom = context.watch<InventoryProvider>().isUomEnabled;
    final totalSteps = isUom ? 4 : 3;
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: AppColors.STAR_BACKGROUND,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: screenSize.width * 0.95,
        height: screenSize.height * 0.85,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildStepIndicator(isUom, totalSteps),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildCurrentStep(isUom),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(isUom),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.STAR_PRIMARY,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.pencil, color: Colors.white),
          const SizedBox(width: 12),
          Text('Edit: ${widget.product.name}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(bool isUom, int totalSteps) {
    return Row(
      children: [
        _indicatorPoint(0, 'Identity'),
        _indicatorLine(0),
        _indicatorPoint(1, 'Pricing'),
        if (isUom) ...[
          _indicatorLine(1),
          _indicatorPoint(2, 'Multi-Units'),
          _indicatorLine(2),
          _indicatorPoint(3, 'Threshold'),
        ] else ...[
          _indicatorLine(1),
          _indicatorPoint(2, 'Threshold'),
        ]
      ],
    );
  }

  Widget _indicatorPoint(int index, String label) {
    bool isActive = _currentStep == index;
    bool isCompleted = _currentStep > index;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.SUCCESS : (isActive ? AppColors.STAR_PRIMARY : AppColors.STAR_BORDER),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted 
                ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                : Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 8, color: isActive ? AppColors.STAR_PRIMARY : AppColors.STAR_TEXT_SECONDARY)),
        ],
      ),
    );
  }

  Widget _indicatorLine(int afterIndex) {
    return Container(width: 15, height: 2, color: _currentStep > afterIndex ? AppColors.SUCCESS : AppColors.STAR_BORDER);
  }

  Widget _buildCurrentStep(bool isUom) {
    switch (_currentStep) {
      case 0: return _buildStepIdentity();
      case 1: return _buildStepPricing();
      case 2: return isUom ? _buildStepUom() : _buildStepThreshold();
      case 3: return isUom ? _buildStepThreshold() : const SizedBox();
      default: return const SizedBox();
    }
  }

  Widget _buildStepIdentity() {
    final provider = context.watch<InventoryProvider>();
    return Column(
      key: const ValueKey(0),
      children: [
        AppDropdown<String>(
          label: 'Category',
          value: _selectedCategoryId,
          items: provider.categories.map((c) => AppDropdownItem<String>(value: c.id, label: c.name, icon: LucideIcons.folder)).toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
        ),
        const SizedBox(height: 16),
        CustomTextField(label: 'Product Name', controller: _nameCtrl, prefixIcon: LucideIcons.package, validator: (v) => v!.isEmpty ? 'Required' : null),
        const SizedBox(height: 16),
        CustomTextField(label: 'Base SKU', controller: _skuCtrl, prefixIcon: LucideIcons.tag, validator: (v) => v!.isEmpty ? 'Required' : null),
        const SizedBox(height: 16),
        CustomTextField(label: 'Description', controller: _descCtrl, prefixIcon: LucideIcons.fileText, maxLines: 2),
      ],
    );
  }

  Widget _buildStepPricing() {
    return Column(
      key: const ValueKey(1),
      children: [
        Row(
          children: [
            Expanded(child: CustomTextField(label: 'Barcode', controller: _barcodeCtrl, prefixIcon: LucideIcons.scan)),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(LucideIcons.camera), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => ScannerScreen(onScan: (c) => setState(() => _barcodeCtrl.text = c))))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: CustomTextField(label: 'Cost', controller: _costPriceCtrl, prefixIcon: LucideIcons.banknote, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: CustomTextField(label: 'Retail', controller: _retailPriceCtrl, prefixIcon: LucideIcons.tag, keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(label: 'Base Unit Name', controller: _unitCtrl, prefixIcon: LucideIcons.layers, hint: 'e.g. Pieces'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: CustomTextField(label: 'QR Code', controller: _qrCtrl, prefixIcon: LucideIcons.scanLine)),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(LucideIcons.refreshCw), onPressed: () => setState(() => _qrCtrl.text = CodeGenerator.generateInternalQrCode())),
          ],
        ),
      ],
    );
  }

  Widget _buildStepUom() {
    return Column(
      key: const ValueKey(2),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             const Text('Multiplier Units', style: TextStyle(fontWeight: FontWeight.bold)),
             ElevatedButton(onPressed: _showAddMultiplierDialog, child: const Text('Add UOM')),
          ],
        ),
        const SizedBox(height: 12),
        ..._multiplierUnits.asMap().entries.map((e) => Card(
          child: ListTile(
            title: Text('${e.value.unitName} = ${e.value.conversionRate} ${_unitCtrl.text}'),
            subtitle: Text('Retail: Rs. ${e.value.retailPrice}'),
            trailing: IconButton(icon: const Icon(LucideIcons.trash2, color: Colors.red), onPressed: () => setState(() => _multiplierUnits.removeAt(e.key))),
          ),
        )),
      ],
    );
  }

  void _showAddMultiplierDialog() {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final retailCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();
    final qrCtrl = TextEditingController();
    final provider = context.read<InventoryProvider>();
    final isTaxEnabled = provider.isTaxEnabled;
    final taxCtrl = TextEditingController(text: provider.defaultTaxRate.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.STAR_BACKGROUND,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Multiplier Unit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: nameCtrl, label: 'Unit Name (e.g. Box)', prefixIcon: LucideIcons.type),
              const SizedBox(height: 12),
              CustomTextField(controller: rateCtrl, label: 'Conversion Rate', prefixIcon: LucideIcons.hash, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: CustomTextField(controller: costCtrl, label: 'Cost', keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: CustomTextField(controller: retailCtrl, label: 'Retail', keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(controller: barcodeCtrl, label: 'Barcode', prefixIcon: LucideIcons.scan),
              const SizedBox(height: 12),
              CustomTextField(controller: qrCtrl, label: 'QR Code', prefixIcon: LucideIcons.scanLine),
              if (isTaxEnabled) ...[
                const SizedBox(height: 12),
                CustomTextField(controller: taxCtrl, label: 'Tax Rate (%)', keyboardType: TextInputType.number),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty || rateCtrl.text.isEmpty || retailCtrl.text.isEmpty) return;
              setState(() {
                _multiplierUnits.add(ProductUnit(
                  id: 'unit_mul_${DateTime.now().millisecondsSinceEpoch}',
                  productId: widget.product.id,
                  unitName: nameCtrl.text,
                  conversionRate: int.parse(rateCtrl.text),
                  isBaseUnit: false,
                  barcode: barcodeCtrl.text.isEmpty ? null : barcodeCtrl.text,
                  qrCode: qrCtrl.text.isEmpty ? null : qrCtrl.text,
                  costPrice: double.tryParse(costCtrl.text) ?? 0,
                  retailPrice: double.parse(retailCtrl.text),
                  taxRate: double.tryParse(taxCtrl.text) ?? 0.0,
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));
              });
              Navigator.pop(dialogCtx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepThreshold() {
    return Column(
      key: const ValueKey(3),
      children: [
        CustomTextField(label: 'Low Stock Threshold', controller: _thresholdCtrl, prefixIcon: LucideIcons.alertTriangle, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildActions(bool isUom) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0) TextButton(onPressed: () => setState(() => _currentStep--), child: const Text('Back')),
          const Spacer(),
          ElevatedButton(
            onPressed: _isSaving ? null : _handleNext,
            child: _isSaving ? const CircularProgressIndicator() : Text(_currentStep < (isUom ? 3 : 2) ? 'Next' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    final isUom = context.read<InventoryProvider>().isUomEnabled;
    final maxSteps = isUom ? 3 : 2;
    
    if (_currentStep < maxSteps) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _isSaving = true);
      final provider = context.read<InventoryProvider>();
      final error = await provider.editProduct(
        productId: widget.product.id,
        name: _nameCtrl.text.trim(),
        baseSku: _skuCtrl.text.trim(),
        categoryId: _selectedCategoryId,
        description: _descCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim(),
        retailPrice: double.tryParse(_retailPriceCtrl.text),
        costPrice: double.tryParse(_costPriceCtrl.text),
        // Additional fields like units, thresholds...
      );
      
      if (mounted) {
        setState(() => _isSaving = false);
        if (error == null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product Updated!')));
        }
      }
    }
  }
}
