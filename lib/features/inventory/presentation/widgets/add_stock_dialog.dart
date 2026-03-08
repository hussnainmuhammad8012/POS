import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../data/models/product_summary_model.dart';
import '../../data/models/product_variant_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../application/inventory_provider.dart';
import '../../application/stock_provider.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/toast_notification.dart';

class AddStockDialog extends StatefulWidget {
  final ProductSummary productSummary;

  const AddStockDialog({super.key, required this.productSummary});

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  List<ProductVariant> _variants = [];
  ProductVariant? _selectedVariant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    final repo = context.read<ProductRepository>();
    final data = await repo.getProductWithVariants(widget.productSummary.product.id);
    
    if (mounted && data != null) {
      setState(() {
        _variants = data['variants'] as List<ProductVariant>;
        if (_variants.isNotEmpty) {
          _selectedVariant = _variants.first;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
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
                    
                    if (_variants.length > 1) ...[
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedVariant == null) return;

    final quantity = int.parse(_quantityController.text);
    final notes = _notesController.text;
    final stockProvider = context.read<StockProvider>();
    final inventoryProvider = context.read<InventoryProvider>();

    try {
      await stockProvider.recordAdjustment(
        productVariantId: _selectedVariant!.id,
        quantityAdjustment: quantity,
        reason: 'Manual Stock Addition',
        notes: notes,
      );
      
      // Refresh the products list to show updated stock
      await inventoryProvider.loadProducts();
      
      if (mounted) {
        Navigator.pop(context);
        AppToast.show(
          context, 
          title: 'Stock Updated', 
          message: 'Stock has been added successfully.',
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
