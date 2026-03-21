import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/product_summary_model.dart';
import '../../data/models/product_variant_model.dart';
import '../../data/models/product_unit_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../application/inventory_provider.dart';
import '../../application/stock_provider.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/toast_notification.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../settings/application/settings_provider.dart';
import '../../../suppliers/application/suppliers_provider.dart';
import '../../../suppliers/presentation/widgets/add_supplier_dialog.dart';

class AddStockDialog extends StatefulWidget {
  final ProductSummary productSummary;

  const AddStockDialog({super.key, required this.productSummary});

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final _quantityController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  List<ProductVariant> _variants = [];
  ProductVariant? _selectedVariant;
  List<ProductUnit> _productUnits = [];
  ProductUnit? _selectedUnit; // for UOM mode
  String? _selectedSupplierId;
  DateTime? _dueDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    final repo = context.read<ProductRepository>();
    final isUomEnabled = context.read<SettingsProvider>().enableUomSystem;
    final data = await repo.getProductWithVariants(widget.productSummary.product.id);
    
    if (mounted) {
      if (isUomEnabled) {
        // Load UOM units instead of variants
        final units = await repo.getUnitsByProductId(widget.productSummary.product.id);
        setState(() {
          _productUnits = units;
          _selectedUnit = units.isNotEmpty ? units.firstWhere((u) => u.isBaseUnit, orElse: () => units.first) : null;
          _selectedSupplierId = widget.productSummary.product.supplierId;
          _isLoading = false;
        });
      } else if (data != null) {
        setState(() {
          _variants = data['variants'] as List<ProductVariant>;
          if (_variants.isNotEmpty) {
            _selectedVariant = _variants.first;
          }
          _selectedSupplierId = widget.productSummary.product.supplierId;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 450, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading 
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.plusCircle, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Add Stock: ${widget.productSummary.product.name}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // ── UOM Unit Selector ──
                    Consumer<SettingsProvider>(
                      builder: (ctx, settings, _) {
                        if (!settings.enableUomSystem) {
                          // Classic variant selector
                          if (_variants.length > 1) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Select Variant', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<ProductVariant>(
                                  value: _selectedVariant,
                                  items: _variants.map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v.variantName ?? v.sku),
                                  )).toList(),
                                  onChanged: (v) => setState(() => _selectedVariant = v),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        // UOM mode: unit dropdown
                        if (_productUnits.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Receiving Unit', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<ProductUnit>(
                              value: _selectedUnit,
                              items: _productUnits.map((u) => DropdownMenuItem(
                                value: u,
                                child: Text('${u.unitName}${u.isBaseUnit ? " (Base)" : " (×${u.conversionRate})"}'),
                              )).toList(),
                              onChanged: (u) => setState(() => _selectedUnit = u),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_selectedUnit != null && !_selectedUnit!.isBaseUnit)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  '1 ${_selectedUnit!.unitName} = ${_selectedUnit!.conversionRate} base units. Qty will be auto-converted.',
                                  style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                                ),
                              ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),

                    CustomTextField(
                      label: 'Quantity to Add',
                      hint: 'e.g. 10',
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      prefixIcon: LucideIcons.boxes,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Invalid quantity';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: 'Optional Notes',
                      hint: 'Reason for adjustment...',
                      controller: _notesController,
                      prefixIcon: LucideIcons.fileText,
                    ),
                    const SizedBox(height: 16),

                    Consumer2<SuppliersProvider, SettingsProvider>(
                      builder: (context, suppliersProv, settingsProv, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Supplier (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppDropdown<String>(
                                    hint: 'Select a supplier',
                                    prefixIcon: LucideIcons.truck,
                                    value: _selectedSupplierId,
                                    items: suppliersProv.suppliers.map((s) => AppDropdownItem<String>(
                                      value: s.id!,
                                      label: '${s.name}${s.contactPerson != null && s.contactPerson!.isNotEmpty ? ' - ${s.contactPerson}' : ''}',
                                      icon: LucideIcons.user,
                                    )).toList(),
                                    onChanged: (v) => setState(() => _selectedSupplierId = v),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _showAddSupplier(context),
                                  icon: const Icon(LucideIcons.plusCircle),
                                  color: Theme.of(context).primaryColor,
                                  tooltip: 'Add New Supplier',
                                ),
                              ],
                            ),
                            if (_selectedSupplierId != null && settingsProv.isSupplierLedgerEnabled) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      label: 'Total Cost (Purchase)',
                                      hint: '0.0',
                                      controller: _totalCostController,
                                      keyboardType: TextInputType.number,
                                      prefixIcon: LucideIcons.banknote,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'Required';
                                        if (double.tryParse(v) == null || double.parse(v) < 0) return 'Invalid';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: CustomTextField(
                                      label: 'Amount Paid Now',
                                      hint: '0.0',
                                      controller: _paidAmountController,
                                      keyboardType: TextInputType.number,
                                      prefixIcon: LucideIcons.coins,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return null; // Optional to pay
                                        if (double.tryParse(v) == null || double.parse(v) < 0) return 'Invalid';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _dueDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                  );
                                  if (date != null) {
                                    setState(() => _dueDate = date);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Due Date (For unpaid balance)',
                                    prefixIcon: const Icon(LucideIcons.calendar),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(
                                    _dueDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_dueDate!),
                                    style: TextStyle(
                                      color: _dueDate == null ? Theme.of(context).hintColor : null,
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Add Stock'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

  Future<void> _submit() async {
    final isUomEnabled = context.read<SettingsProvider>().enableUomSystem;
    
    // Validate guard rail
    if (isUomEnabled) {
      if (_selectedUnit == null) {
        AppToast.show(context, title: 'No Unit Selected', message: 'Please select a receiving unit.', type: ToastType.error);
        return;
      }
    } else {
      if (!_formKey.currentState!.validate() || _selectedVariant == null) return;
    }
    if (!_formKey.currentState!.validate()) return;

    final enteredQty = int.parse(_quantityController.text);
    final notes = _notesController.text;
    
    // For UOM mode, multiply entered qty by conversion rate to get base unit quantity
    final int baseQtyToAdd;
    final String effectiveVariantId;
    if (isUomEnabled && _selectedUnit != null) {
      // Find the base unit to know which stock_level row to update
      final baseUnit = _productUnits.firstWhere((u) => u.isBaseUnit, orElse: () => _selectedUnit!);
      baseQtyToAdd = enteredQty * _selectedUnit!.conversionRate;
      effectiveVariantId = baseUnit.id; // stock_levels row is always keyed by base unit ID
    } else {
      baseQtyToAdd = enteredQty;
      effectiveVariantId = _selectedVariant!.id;
    }
    
    final stockProvider = context.read<StockProvider>();
    final inventoryProvider = context.read<InventoryProvider>();
    final suppliersProv = context.read<SuppliersProvider>();
    final settingsProv = context.read<SettingsProvider>();

    try {
      if (_selectedSupplierId != null) {
        final totalCost = double.tryParse(_totalCostController.text) ?? 0.0;
        final costPerPiece = baseQtyToAdd > 0 ? (totalCost / baseQtyToAdd) : 0.0;
        final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
        
        final cartonId = await stockProvider.receiveCarton(
          productVariantId: effectiveVariantId,
          cartonNumber: 'CTN-${DateTime.now().millisecondsSinceEpoch}',
          piecesPerCarton: baseQtyToAdd,
          costPerPiece: costPerPiece,
          receivedQuantity: baseQtyToAdd,
          supplierId: _selectedSupplierId,
          unitId: isUomEnabled ? _selectedUnit?.id : null,
          unitName: isUomEnabled ? _selectedUnit?.unitName : null,
          notes: notes.isNotEmpty 
            ? notes 
            : isUomEnabled && _selectedUnit != null
                ? 'Received $enteredQty ${_selectedUnit!.unitName}(s) = $baseQtyToAdd base units'
                : 'Purchased from supplier',
        );

        if (settingsProv.isSupplierLedgerEnabled) {
          await suppliersProv.recordPurchase(_selectedSupplierId!, totalCost, referenceId: cartonId, notes: 'Carton $cartonId', dueDate: _dueDate);
          if (paidAmount > 0) {
            await suppliersProv.recordPayment(_selectedSupplierId!, paidAmount, notes: 'Payment for Carton $cartonId');
          }
        }
      } else {
        await stockProvider.recordAdjustment(
          productVariantId: effectiveVariantId,
          quantityAdjustment: baseQtyToAdd,
          reason: isUomEnabled && _selectedUnit != null
            ? 'Manual Addition: $enteredQty ${_selectedUnit!.unitName}(s) → $baseQtyToAdd base units'
            : 'Manual Stock Addition',
          notes: notes,
          unitId: isUomEnabled ? _selectedUnit?.id : null,
          unitName: isUomEnabled ? _selectedUnit?.unitName : null,
        );
      }
      
      await inventoryProvider.loadProducts();
      
      if (mounted) {
        Navigator.pop(context);
        AppToast.show(
          context, 
          title: 'Stock Updated', 
          message: isUomEnabled && _selectedUnit != null
            ? 'Added $enteredQty ${_selectedUnit!.unitName}(s) (+$baseQtyToAdd base units) successfully.'
            : 'Stock has been added successfully.',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context, 
          title: 'Update Failed', 
          message: 'Error: $e',
          type: ToastType.error,
        );
      }
    }
  }
}
