import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:companion_app/core/theme/app_theme.dart';
import 'package:companion_app/core/widgets/custom_text_field.dart';
import 'package:companion_app/core/widgets/app_dropdown.dart';
import 'package:companion_app/features/inventory/application/inventory_provider.dart';
import 'package:companion_app/features/inventory/data/models/product_unit_model.dart';
import 'package:companion_app/features/inventory/presentation/screens/scanner_screen.dart';
import 'package:companion_app/features/inventory/presentation/widgets/add_supplier_dialog.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSaving = false;
  double _thresholdConversionRate = 1.0;
  bool _skuManuallyEdited = false;
  bool _isAutoGeneratingSku = false;

  // Step 1: Identity
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedSupplierId;

  // Step 2: Pricing & Base Unit
  final _unitController = TextEditingController(text: 'Pieces');
  final _barcodeController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _qrController = TextEditingController();
  final _taxRateController = TextEditingController();
  bool _qrManuallyEdited = false;
  bool _isAutoGeneratingQr = false;

  // Step 3: Multiplier Units (UOM)
  List<ProductUnit> _multiplierUnits = [];

  // Step 4: Stock Management
  final _initialStockController = TextEditingController(text: '0');
  final _lowStockThresholdController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _skuController.addListener(_onSkuChanged);
    _qrController.addListener(_onQrChanged);
    
    // Initialize tax rate from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InventoryProvider>();
      _taxRateController.text = provider.defaultTaxRate.toString();
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _skuController.removeListener(_onSkuChanged);
    _qrController.removeListener(_onQrChanged);
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _retailPriceController.dispose();
    _wholesalePriceController.dispose();
    _mrpController.dispose();
    _qrController.dispose();
    _taxRateController.dispose();
    _initialStockController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (!_skuManuallyEdited && _nameController.text.isNotEmpty) {
      _isAutoGeneratingSku = true;
      final text = _nameController.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final prefix = text.length >= 3 ? text.substring(0, 3) : (text.isNotEmpty ? text : 'PRD');
      final random = (1000 + math.Random().nextInt(9000)).toString();
      _skuController.text = '$prefix-$random';
      _isAutoGeneratingSku = false;
    } else if (!_skuManuallyEdited && _nameController.text.isEmpty) {
      _isAutoGeneratingSku = true;
      _skuController.text = '';
      _isAutoGeneratingSku = false;
    }
  }

  void _onSkuChanged() {
    if (!_isAutoGeneratingSku && _skuController.text.isNotEmpty) {
      _skuManuallyEdited = true;
    }
  }

  void _onQrChanged() {
    if (!_isAutoGeneratingQr && _qrController.text.isNotEmpty) {
      _qrManuallyEdited = true;
    }
  }

  void _generateInternalBarcode() {
    final random = math.Random();
    String code = '';
    for (int i = 0; i < 12; i++) {
      code += random.nextInt(10).toString();
    }
    setState(() {
      _barcodeController.text = code;
    });
  }

  void _generateInternalQr() {
    _isAutoGeneratingQr = true;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random();
    String code = '';
    for (int i = 0; i < 8; i++) {
      code += chars[random.nextInt(chars.length)];
    }
    setState(() {
      _qrController.text = code;
      _qrManuallyEdited = false;
    });
    _isAutoGeneratingQr = false;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Dialog(
      backgroundColor: AppColors.STAR_BACKGROUND,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: screenSize.width * 0.95,
        height: screenSize.height * 0.85,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDialogHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildStepIndicator(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildCurrentStep(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildDialogActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    final isUom = context.read<InventoryProvider>().isUomEnabled;
    switch (_currentStep) {
      case 0: return _buildIdentityStep();
      case 1: return _buildPricingStep();
      case 2: return isUom ? _buildUomStep() : _buildStockStep();
      case 3: return isUom ? _buildStockStep() : const SizedBox();
      default: return const SizedBox();
    }
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.STAR_PRIMARY,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.package, color: Colors.white),
          const SizedBox(width: 12),
          const Text('Add New Product', style: TextStyle(color: Colors.white, fontSize: 18)),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _isSaving ? null : () {
                setState(() => _currentStep--);
              },
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
              : Text(_currentStep < (context.read<InventoryProvider>().isUomEnabled ? 3 : 2) ? 'Next Step' : 'Create Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final isUom = context.read<InventoryProvider>().isUomEnabled;
    return Row(
      children: [
        _buildIndicatorPoint(0, 'Identity'),
        _buildIndicatorLine(0),
        _buildIndicatorPoint(1, 'Pricing'),
        if (isUom) ...[
          _buildIndicatorLine(1),
          _buildIndicatorPoint(2, 'Multi-Units'),
          _buildIndicatorLine(2),
          _buildIndicatorPoint(3, 'Stock'),
        ] else ...[
          _buildIndicatorLine(1),
          _buildIndicatorPoint(2, 'Stock'),
        ]
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.SUCCESS : (isActive ? AppColors.STAR_PRIMARY : AppColors.STAR_BORDER),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted 
                ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                : Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 8, color: isActive ? AppColors.STAR_PRIMARY : AppColors.STAR_TEXT_SECONDARY)),
        ],
      ),
    );
  }

  Widget _buildIndicatorLine(int afterIndex) {
    bool isCompleted = _currentStep > afterIndex;
    return Container(
      width: 15,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppDropdown<String>(
                label: 'Supplier (Optional)',
                hint: 'Select Supplier',
                prefixIcon: LucideIcons.truck,
                value: _selectedSupplierId,
                items: provider.suppliers.map((s) => AppDropdownItem<String>(
                  value: s.id,
                  label: '${s.name}${s.contactPerson != null && s.contactPerson!.isNotEmpty ? ' - ${s.contactPerson}' : ''}',
                  icon: LucideIcons.user,
                )).toList(),
                onChanged: (v) => setState(() => _selectedSupplierId = v),
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
                onPressed: () => _showAddSupplier(context),
                child: const Icon(LucideIcons.plusCircle, size: 20),
              ),
            ),
          ],
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CustomTextField(
                controller: _skuController,
                label: 'Base SKU',
                prefixIcon: LucideIcons.hash,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.STAR_PRIMARY.withOpacity(0.1),
                foregroundColor: AppColors.STAR_PRIMARY,
                elevation: 0,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _skuManuallyEdited = false;
                _onNameChanged();
              },
              child: const Icon(LucideIcons.refreshCw, size: 20),
            ),
          ],
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
                label: 'Base Barcode',
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openScanner,
                child: const Icon(LucideIcons.camera),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  setState(() {
                    _barcodeController.text = 'BAR-${DateTime.now().millisecondsSinceEpoch}';
                  });
                },
                child: const Icon(LucideIcons.refreshCw),
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
          label: context.read<InventoryProvider>().isUomEnabled ? 'Base Unit Name' : 'Unit Type',
          prefixIcon: LucideIcons.layers,
          hint: 'Pieces, Kg, Liter, etc.',
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CustomTextField(
                controller: _qrController,
                label: 'Internal QR Code',
                prefixIcon: LucideIcons.scanLine,
                hint: 'Auto-generate or type...',
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.STAR_PRIMARY.withOpacity(0.1),
                foregroundColor: AppColors.STAR_PRIMARY,
                elevation: 0,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _openScannerForQr,
              child: const Icon(LucideIcons.camera, size: 20),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(bottom: 2), // Align visually
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.STAR_PRIMARY.withOpacity(0.1),
                  foregroundColor: AppColors.STAR_PRIMARY,
                  elevation: 0,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _generateInternalQr,
                child: const Icon(LucideIcons.refreshCw, size: 20),
              ),
            ),
          ],
        ),
        if (context.read<InventoryProvider>().isTaxEnabled) ...[
          const SizedBox(height: 16),
          CustomTextField(
            controller: _taxRateController,
            label: 'Tax Rate (%)',
            hint: 'e.g. 18.0',
            prefixIcon: LucideIcons.percent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ],
    );
  }

  Widget _buildUomStep() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Multiplier Units', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.STAR_TEXT)),
            ElevatedButton.icon(
              onPressed: _showAddMultiplierDialog,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add UOM'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.STAR_PRIMARY,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_multiplierUnits.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(LucideIcons.layers, size: 48, color: AppColors.STAR_BORDER),
                  const SizedBox(height: 12),
                  const Text('No Multiplier Units Added', style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY)),
                  const Text('e.g. Pet = 6 Pieces', style: TextStyle(fontSize: 12, color: AppColors.STAR_TEXT_SECONDARY)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _multiplierUnits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final unit = _multiplierUnits[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.STAR_BORDER),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.STAR_PRIMARY.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(LucideIcons.package, size: 18, color: AppColors.STAR_PRIMARY),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(unit.unitName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('1 ${unit.unitName} = ${unit.conversionRate} ${_unitController.text}', style: const TextStyle(fontSize: 12, color: AppColors.STAR_TEXT_SECONDARY)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Rs. ${unit.retailPrice}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.STAR_PRIMARY)),
                        GestureDetector(
                          onTap: () => setState(() => _multiplierUnits.removeAt(index)),
                          child: const Text('Remove', style: TextStyle(color: AppColors.DANGER, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
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
    final defaultTaxRate = provider.defaultTaxRate;
    final taxCtrl = TextEditingController(text: defaultTaxRate.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Multiplier Unit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: nameCtrl, label: 'Unit Name (e.g. Pet, Box)', prefixIcon: LucideIcons.type),
              const SizedBox(height: 12),
              CustomTextField(controller: rateCtrl, label: 'Conversion Rate (vs Base)', prefixIcon: LucideIcons.hash, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              CustomTextField(controller: costCtrl, label: 'Cost Price', prefixIcon: LucideIcons.banknote, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              CustomTextField(controller: retailCtrl, label: 'Retail Price', prefixIcon: LucideIcons.tag, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: CustomTextField(controller: barcodeCtrl, label: 'Unit Barcode', prefixIcon: LucideIcons.scan)),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.STAR_PRIMARY.withOpacity(0.1),
                      foregroundColor: AppColors.STAR_PRIMARY,
                      elevation: 0,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (ctx) => ScannerScreen(onScan: (code) => barcodeCtrl.text = code)));
                    },
                    child: const Icon(LucideIcons.camera, size: 20),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.STAR_PRIMARY.withOpacity(0.1),
                      foregroundColor: AppColors.STAR_PRIMARY,
                      elevation: 0,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => barcodeCtrl.text = 'BAR-${DateTime.now().millisecondsSinceEpoch}',
                    child: const Icon(LucideIcons.refreshCw, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: CustomTextField(controller: qrCtrl, label: 'Unit QR Code', prefixIcon: LucideIcons.scanLine)),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.STAR_PRIMARY.withOpacity(0.1),
                      foregroundColor: AppColors.STAR_PRIMARY,
                      elevation: 0,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (ctx) => ScannerScreen(onScan: (code) => qrCtrl.text = code)));
                    },
                    child: const Icon(LucideIcons.camera, size: 20),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.STAR_PRIMARY.withOpacity(0.1),
                      foregroundColor: AppColors.STAR_PRIMARY,
                      elevation: 0,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => qrCtrl.text = 'QR-${DateTime.now().microsecondsSinceEpoch}',
                    child: const Icon(LucideIcons.refreshCw, size: 20),
                  ),
                ],
              ),
              if (isTaxEnabled) ...[
                const SizedBox(height: 12),
                CustomTextField(
                  controller: taxCtrl,
                  label: 'Tax Rate (%)',
                  prefixIcon: LucideIcons.percent,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
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
                  productId: '',
                  unitName: nameCtrl.text,
                  conversionRate: int.tryParse(rateCtrl.text) ?? 1,
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

  Widget _buildStockStep() {
    return Column(
      key: const ValueKey(3),
      children: [
        CustomTextField(
          controller: _initialStockController,
          label: context.read<InventoryProvider>().isUomEnabled ? 'Initial Stock (Base Units)' : 'Initial Stock',
          keyboardType: TextInputType.number,
          prefixIcon: LucideIcons.boxes,
        ),
        const SizedBox(height: 16),
        if (context.read<InventoryProvider>().isUomEnabled)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _lowStockThresholdController,
                  label: 'Low Stock Threshold',
                  keyboardType: TextInputType.number,
                  prefixIcon: LucideIcons.alertTriangle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<double>(
                  value: _thresholdConversionRate,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.STAR_BORDER),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.STAR_BORDER),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.STAR_PRIMARY, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: [
                    DropdownMenuItem(value: 1.0, child: Text(_unitController.text.isNotEmpty ? _unitController.text : 'Base Unit', overflow: TextOverflow.ellipsis)),
                    ..._multiplierUnits.map((u) => DropdownMenuItem(value: u.conversionRate.toDouble(), child: Text(u.unitName, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _thresholdConversionRate = val ?? 1.0;
                    });
                  },
                ),
              ),
            ],
          )
        else
          CustomTextField(
            controller: _lowStockThresholdController,
            label: 'Low Stock Alert Threshold',
            keyboardType: TextInputType.number,
            prefixIcon: LucideIcons.alertTriangle,
          ),
        const SizedBox(height: 24),
        if (context.read<InventoryProvider>().isUomEnabled)
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
                    'This will initialize the product with the given stock levels in ${_unitController.text}.',
                    style: const TextStyle(fontSize: 12, color: AppColors.STAR_TEXT_SECONDARY),
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

  void _openScannerForQr() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          onScan: (barcode) {
            setState(() {
              _qrController.text = barcode;
            });
          },
        ),
      ),
    );
  }

  void _showAddSupplier(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddSupplierDialog(),
    );
  }

  void _handleNext() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<InventoryProvider>();

    final totalSteps = provider.isUomEnabled ? 4 : 3;
    if (_currentStep < (totalSteps - 1)) {
      setState(() => _currentStep++);
      return;
    }

    setState(() => _isSaving = true);
    
    String? error;
    try {
      error = await provider.addProduct(
        categoryId: _selectedCategoryId!,
        name: _nameController.text,
        baseSku: _skuController.text,
        description: _descriptionController.text,
        supplierId: _selectedSupplierId,
        unitType: _unitController.text,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        costPrice: double.parse(_costPriceController.text),
        retailPrice: double.parse(_retailPriceController.text),
        wholesalePrice: double.tryParse(_wholesalePriceController.text),
        mrp: double.tryParse(_mrpController.text),
        taxRate: double.tryParse(_taxRateController.text) ?? 0.0,
        initialStock: (int.tryParse(_initialStockController.text) ?? 0) * _thresholdConversionRate.round(),
        lowStockThreshold: (int.tryParse(_lowStockThresholdController.text) ?? 10) * _thresholdConversionRate.round(),
        qrCode: _qrController.text.isEmpty ? null : _qrController.text,
        units: [
          ProductUnit(
            id: 'unit_base_${DateTime.now().millisecondsSinceEpoch}',
            productId: '', 
            unitName: _unitController.text,
            conversionRate: 1,
            isBaseUnit: true,
            barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
            qrCode: _qrController.text.isEmpty ? null : _qrController.text,
            costPrice: double.parse(_costPriceController.text),
            retailPrice: double.parse(_retailPriceController.text),
            wholesalePrice: double.tryParse(_wholesalePriceController.text),
            mrp: double.tryParse(_mrpController.text),
            taxRate: double.tryParse(_taxRateController.text) ?? 0.0,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ..._multiplierUnits,
        ],
      );
    } catch (e) {
      error = e.toString();
      debugPrint('Add product error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (mounted) {
      if (error == null) {
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
            content: Text(error), 
            backgroundColor: AppColors.DANGER,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
