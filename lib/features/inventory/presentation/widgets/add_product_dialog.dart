import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../application/inventory_provider.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/toast_notification.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product_summary_model.dart';
import '../../data/models/product_unit_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../../../features/suppliers/application/suppliers_provider.dart';
import '../../../../features/suppliers/presentation/widgets/add_supplier_dialog.dart';
import '../../../../features/settings/application/settings_provider.dart';

class AddProductDialog extends StatefulWidget {
  final ProductSummary? initialProduct;

  const AddProductDialog({super.key, this.initialProduct});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  int _currentStep = 0;
  bool _isSaving = false;
  bool _isLoadingUoms = false;
  bool _skuManuallyEdited = false;
  bool _isAutoGeneratingSku = false;

  // Step 1: Identity
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedImagePath; 
  String? _selectedCategoryId;
  String? _selectedSupplierId; 

  // Step 2: Pricing & Base Unit
  final _unitController = TextEditingController(text: 'Piece');
  final _barcodeController = TextEditingController();
  final _qrController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _retailPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _mrpController = TextEditingController();

  // Step 3 (Multipliers): List of UOMs mapped locally
  List<ProductUnit> _multiplierUnits = [];

  // Step 4: Stock Management
  final _initialStockController = TextEditingController(text: '0');
  final _lowStockThresholdController = TextEditingController(text: '10');
  double _thresholdConversionRate = 1.0;

  bool get isEditing => widget.initialProduct != null;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _skuController.addListener(_onSkuChanged);
    
    if (isEditing) {
      final p = widget.initialProduct!.product;
      _nameController.text = p.name;
      _skuController.text = p.baseSku;
      _skuManuallyEdited = true; 
      _descriptionController.text = p.description ?? '';
      _selectedCategoryId = p.categoryId;
      _selectedSupplierId = p.supplierId;
      _selectedImagePath = p.mainImagePath;
      _unitController.text = p.unitType;
      
      // Basic Fallback defaults
      _costPriceController.text = widget.initialProduct!.costPrice?.toString() ?? '';
      _retailPriceController.text = widget.initialProduct!.minPrice.toString();
      _wholesalePriceController.text = widget.initialProduct!.wholesalePrice?.toString() ?? '';
      _mrpController.text = widget.initialProduct!.mrp?.toString() ?? '';
      _barcodeController.text = widget.initialProduct!.barcode ?? '';
      _qrController.text = widget.initialProduct!.qrCode ?? '';

      _initialStockController.text = widget.initialProduct!.totalStock.toString();

      _isLoadingUoms = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final repo = context.read<ProductRepository>();
        final units = await repo.getUnitsByProductId(p.id);
        if (units.isNotEmpty) {
           final baseUnit = units.firstWhere((u) => u.isBaseUnit, orElse: () => units.first);
           _unitController.text = baseUnit.unitName;
           _costPriceController.text = baseUnit.costPrice.toString();
           _retailPriceController.text = baseUnit.retailPrice.toString();
           _wholesalePriceController.text = baseUnit.wholesalePrice?.toString() ?? '';
           _mrpController.text = baseUnit.mrp?.toString() ?? '';
           _barcodeController.text = baseUnit.barcode ?? '';
           _qrController.text = baseUnit.qrCode ?? '';
           
           setState(() {
             _multiplierUnits = units.where((u) => !u.isBaseUnit).toList();
             _isLoadingUoms = false;
           });
        } else {
           setState(() => _isLoadingUoms = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _skuController.removeListener(_onSkuChanged);
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUoms) {
      return const AlertDialog(content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())));
    }

    final provider = context.watch<InventoryProvider>();
    final suppliersProvider = context.watch<SuppliersProvider>();
    final isUom = context.watch<SettingsProvider>().enableUomSystem;
    final totalSteps = isUom ? 4 : 3;

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.packagePlus, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(isEditing ? 'Edit Product' : 'New Product Creation'),
        ],
      ),
      content: Container(
        width: 650,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepIndicator(isUom, totalSteps),
            const SizedBox(height: 24),
            Flexible(
              child: Theme(
                data: Theme.of(context).copyWith(
                  scrollbarTheme: ScrollbarThemeData(
                    thumbColor: WidgetStateProperty.all(Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                    thickness: WidgetStateProperty.all(6),
                    radius: const Radius.circular(3),
                  ),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Form(
                        key: _formKey,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentStep == 0 
                            ? _buildStepOne(provider, suppliersProvider) 
                            : (_currentStep == 1 
                                ? _buildStepTwo(isUom) 
                                : (isUom && _currentStep == 2 
                                    ? _buildStepThreeUom() 
                                    : _buildStepStock(isUom))),
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
          onPressed: _isSaving ? null : () => _handleNext(provider, isUom, totalSteps),
          child: _isSaving 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(_currentStep < (totalSteps - 1) ? 'Next' : (isEditing ? 'Save Changes' : 'Create Product')),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(bool isUom, int totalSteps) {
    return Row(
      children: [
        _indicatorItem(0, 'Identity', LucideIcons.tag, totalSteps),
        _indicatorLine(),
        _indicatorItem(1, isUom ? 'Base Unit' : 'Pricing', LucideIcons.coins, totalSteps),
        _indicatorLine(),
        if (isUom) ...[
          _indicatorItem(2, 'Multipliers', LucideIcons.layers, totalSteps),
          _indicatorLine(),
          _indicatorItem(3, 'Stock', LucideIcons.boxes, totalSteps),
        ] else 
          _indicatorItem(2, 'Stock', LucideIcons.boxes, totalSteps),
      ],
    );
  }

  Widget _indicatorItem(int index, String label, IconData icon, int totalSteps) {
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
              color: color.withValues(alpha: 0.1),
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
      width: 15,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.grey.shade300,
    );
  }

  Widget _buildStepOne(InventoryProvider provider, SuppliersProvider suppliersProvider) {
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppDropdown<String>(
                label: 'Default Supplier (Optional)',
                hint: 'Select a primary supplier',
                prefixIcon: LucideIcons.truck,
                value: _selectedSupplierId,
                items: suppliersProvider.suppliers.map((s) => AppDropdownItem<String>(
                  value: s.id!,
                  label: '${s.name}${s.contactPerson != null && s.contactPerson!.isNotEmpty ? ' - ${s.contactPerson}' : ''}',
                  icon: LucideIcons.user,
                )).toList(),
                onChanged: (v) => setState(() => _selectedSupplierId = v),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 24),
              child: IconButton(
                onPressed: () => _showAddSupplier(context),
                icon: const Icon(LucideIcons.plusCircle),
                color: Theme.of(context).primaryColor,
                tooltip: 'Add New Supplier',
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
        CustomTextField(
          controller: _skuController,
          label: 'Base SKU',
          prefixIcon: LucideIcons.tag,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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

  void _showAddSupplier(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddSupplierDialog(),
    );
  }

  Widget _buildStepTwo(bool isUom) {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isUom)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text('Define the native formatting and pricing for the lowest sellable chunk of this product.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _unitController,
                label: isUom ? 'Base Unit Name (e.g. Piece)' : 'Unit Type',
                prefixIcon: LucideIcons.hash,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CustomTextField(
                controller: _barcodeController,
                label: 'Base Barcode',
                prefixIcon: LucideIcons.scanLine,
                hint: 'Scan or enter barcode...',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: IconButton(
                icon: const Icon(LucideIcons.refreshCw),
                onPressed: () => _generateInternalBarcode(_barcodeController),
                tooltip: 'Generate Internal Barcode',
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
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
                hint: 'Generate or enter QR code data...',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: IconButton(
                icon: const Icon(LucideIcons.refreshCw),
                onPressed: () => _generateInternalQr(_qrController),
                tooltip: 'Generate Alphanumeric QR',
                color: Colors.green,
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
                label: 'Wholesale Price (Optional)',
                prefixIcon: LucideIcons.users,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _mrpController,
                label: 'MRP (Optional)',
                prefixIcon: LucideIcons.shieldCheck,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepThreeUom() {
    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
           const Text(
              'Multiplier Units',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddMultiplierDialog(),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add UOM'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Add boxes or cartons based on how many ${_unitController.text}s they contain.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 16),
        if (_multiplierUnits.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: Text('No multipliers added. Product will only be sold as piece/base.', style: TextStyle(color: Colors.grey.shade500)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _multiplierUnits.length,
            itemBuilder: (context, index) {
              final u = _multiplierUnits[index];
              return Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${u.unitName} = ${u.conversionRate} ${_unitController.text}s', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Cost: ${u.costPrice} | Retail: ${u.retailPrice}\nBarcode: ${u.barcode ?? "N/A"}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.red),
                    onPressed: () => setState(() => _multiplierUnits.removeAt(index)),
                  ),
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
    final barcodeCtrl = TextEditingController();
    final qrCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final retailCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Multiplier Unit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(controller: nameCtrl, label: 'Unit Name (e.g. Box)', prefixIcon: LucideIcons.package),
                const SizedBox(height: 12),
                CustomTextField(controller: rateCtrl, label: 'Conversion Rate (How many Base units?)', keyboardType: TextInputType.number, prefixIcon: LucideIcons.layers),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: CustomTextField(controller: barcodeCtrl, label: 'Barcode (Optional)', prefixIcon: LucideIcons.scanLine)),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: IconButton(icon: const Icon(LucideIcons.refreshCw), color: Theme.of(context).primaryColor, tooltip: 'Generate Barcode', onPressed: () => _generateInternalBarcode(barcodeCtrl)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: CustomTextField(controller: qrCtrl, label: 'QR Code (Optional)', prefixIcon: LucideIcons.scanLine)),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: IconButton(icon: const Icon(LucideIcons.refreshCw), color: Colors.green, tooltip: 'Generate QR', onPressed: () => _generateInternalQr(qrCtrl)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(controller: costCtrl, label: 'Cost Price', keyboardType: TextInputType.number, prefixIcon: LucideIcons.arrowDownCircle),
                const SizedBox(height: 12),
                CustomTextField(controller: retailCtrl, label: 'Retail Price', keyboardType: TextInputType.number, prefixIcon: LucideIcons.arrowUpCircle),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty || rateCtrl.text.isEmpty || costCtrl.text.isEmpty || retailCtrl.text.isEmpty) {
                  AppToast.show(ctx, title: 'Error', message: 'Please fill all required fields.', type: ToastType.error);
                  return;
                }
                final rate = int.tryParse(rateCtrl.text) ?? 0;
                if (rate <= 1) {
                  AppToast.show(ctx, title: 'Error', message: 'Conversion rate must be > 1.', type: ToastType.error);
                  return;
                }
                setState(() {
                  _multiplierUnits.add(ProductUnit(
                    id: 'unit_new_${DateTime.now().microsecondsSinceEpoch}',
                    productId: isEditing ? widget.initialProduct!.product.id : '',
                    unitName: nameCtrl.text,
                    conversionRate: rate,
                    isBaseUnit: false,
                    barcode: barcodeCtrl.text.isEmpty ? null : barcodeCtrl.text,
                    qrCode: qrCtrl.text.isEmpty ? null : qrCtrl.text,
                    costPrice: double.parse(costCtrl.text),
                    retailPrice: double.parse(retailCtrl.text),
                    isActive: true,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      }
    );
  }

  Widget _buildStepStock(bool isUom) {
    return Column(
      key: const ValueKey(3),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isUom)
           Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text('Initial stock must be provided in the lowest Base Unit (${_unitController.text}s).', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _initialStockController,
                label: 'Initial Stock',
                prefixIcon: LucideIcons.packageCheck,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid quantity' : null,
              ),
            ),
            const SizedBox(width: 16),
            if (isUom)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _lowStockThresholdController,
                        label: 'Low Stock Alert',
                        prefixIcon: LucideIcons.alertTriangle,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<double>(
                        value: _thresholdConversionRate,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                ),
              )
            else
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
      ],
    );
  }

  void _generateInternalBarcode(TextEditingController ctrl) {
    final random = math.Random();
    String code = '';
    for (int i = 0; i < 12; i++) {
      code += random.nextInt(10).toString();
    }
    setState(() => ctrl.text = code);
    AppToast.show(context, title: 'Barcode Generated', message: 'Internal barcode $code created.', type: ToastType.success);
  }

  void _generateInternalQr(TextEditingController ctrl) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random();
    String code = '';
    for (int i = 0; i < 8; i++) {
      code += chars[random.nextInt(chars.length)];
    }
    setState(() => ctrl.text = code);
    AppToast.show(context, title: 'QR Data Generated', message: 'Internal QR code $code created.', type: ToastType.success);
  }

  void _handleNext(InventoryProvider provider, bool isUom, int totalSteps) async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentStep < (totalSteps - 1)) {
      setState(() => _currentStep++);
    } else {
      setState(() => _isSaving = true);
      
      final baseUnit = ProductUnit(
        id: isEditing ? (widget.initialProduct!.product.id + "_base") : "temp_base", // Will be overridden or used gracefully
        productId: isEditing ? widget.initialProduct!.product.id : '',
        unitName: _unitController.text,
        conversionRate: 1,
        isBaseUnit: true,
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
        qrCode: _qrController.text.isEmpty ? null : _qrController.text,
        costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
        retailPrice: double.tryParse(_retailPriceController.text) ?? 0.0,
        wholesalePrice: double.tryParse(_wholesalePriceController.text),
        mrp: double.tryParse(_mrpController.text),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (isEditing) {
          if (isUom) {
             // For update, we look up the existing base unit ID from the product's units
             final existingBaseUnit = widget.initialProduct!.units.firstWhere((u) => u.isBaseUnit, orElse: () => widget.initialProduct!.units.first);
             final existingBaseId = existingBaseUnit.id;
             final resolvedBaseUnit = ProductUnit(
               id: existingBaseId,
               productId: widget.initialProduct!.product.id,
               unitName: baseUnit.unitName,
               conversionRate: 1,
               isBaseUnit: true,
               barcode: baseUnit.barcode,
               qrCode: baseUnit.qrCode,
               costPrice: baseUnit.costPrice,
               retailPrice: baseUnit.retailPrice,
               wholesalePrice: baseUnit.wholesalePrice,
               mrp: baseUnit.mrp,
               isActive: true,
               createdAt: baseUnit.createdAt,
               updatedAt: DateTime.now(),
             );
             await provider.updateProductWithUoms(
               widget.initialProduct!.product.id,
               categoryId: _selectedCategoryId!,
               name: _nameController.text,
               baseSku: _skuController.text,
               description: _descriptionController.text,
               supplierId: _selectedSupplierId,
               baseUnit: resolvedBaseUnit,
               multiplierUnits: _multiplierUnits,
               manualBaseStockAdjust: (int.tryParse(_initialStockController.text) ?? 0) * _thresholdConversionRate.round(),
               lowStockThreshold: (int.tryParse(_lowStockThresholdController.text) ?? 10) * _thresholdConversionRate.round(),
             );
          } else {
            await provider.updateProduct(
              widget.initialProduct!.product.id,
              categoryId: _selectedCategoryId!,
              name: _nameController.text,
              baseSku: _skuController.text,
              description: _descriptionController.text,
              mainImagePath: _selectedImagePath,
              unitType: _unitController.text,
              supplierId: _selectedSupplierId,
              costPrice: baseUnit.costPrice,
              retailPrice: baseUnit.retailPrice,
              wholesalePrice: baseUnit.wholesalePrice,
              mrp: baseUnit.mrp,
              barcode: baseUnit.barcode,
              qrCode: baseUnit.qrCode,
              initialStock: int.tryParse(_initialStockController.text) ?? 0,
              lowStockThreshold: (int.tryParse(_lowStockThresholdController.text) ?? 10) * _thresholdConversionRate.round(),
            );
          }
        } else {
          if (isUom) {
            final newBaseUnitId = 'unit_${DateTime.now().microsecondsSinceEpoch}';
            final resolvedBaseUnit = ProductUnit(
              id: newBaseUnitId,
              productId: '', // Will be set by the repository after product creation
              unitName: baseUnit.unitName,
              conversionRate: 1,
              isBaseUnit: true,
              barcode: baseUnit.barcode,
              qrCode: baseUnit.qrCode,
              costPrice: baseUnit.costPrice,
              retailPrice: baseUnit.retailPrice,
              wholesalePrice: baseUnit.wholesalePrice,
              mrp: baseUnit.mrp,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await provider.createProductWithUoms(
              categoryId: _selectedCategoryId!,
              name: _nameController.text,
              baseSku: _skuController.text,
              description: _descriptionController.text,
              supplierId: _selectedSupplierId,
              baseUnit: resolvedBaseUnit,
              multiplierUnits: _multiplierUnits,
              initialBaseStock: (int.tryParse(_initialStockController.text) ?? 0) * _thresholdConversionRate.round(),
              lowStockThreshold: (int.tryParse(_lowStockThresholdController.text) ?? 10) * _thresholdConversionRate.round(),
            );
          } else {
            final productId = await provider.createProduct(
              categoryId: _selectedCategoryId!,
              name: _nameController.text,
              baseSku: _skuController.text,
              description: _descriptionController.text,
              mainImagePath: _selectedImagePath,
              unitType: _unitController.text,
              supplierId: _selectedSupplierId,
            );

            await provider.createProductVariant(
              productId: productId,
              variantName: 'Default',
              sku: '${_skuController.text}-DEF',
              barcode: baseUnit.barcode,
              qrCode: baseUnit.qrCode,
              costPrice: baseUnit.costPrice,
              retailPrice: baseUnit.retailPrice,
              wholesalePrice: baseUnit.wholesalePrice,
              mrp: baseUnit.mrp,
              initialStock: int.tryParse(_initialStockController.text) ?? 0,
              lowStockThreshold: int.tryParse(_lowStockThresholdController.text) ?? 10,
            );
          }
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          String errorMsg = e.toString();
          AppToast.show(context, title: 'Operation Failed', message: errorMsg, type: ToastType.error);
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }
}
