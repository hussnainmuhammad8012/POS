import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/entities.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/toast_notification.dart';
import '../../application/suppliers_provider.dart';

class AddSupplierDialog extends StatefulWidget {
  final Supplier? initialSupplier;

  const AddSupplierDialog({super.key, this.initialSupplier});

  @override
  State<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<AddSupplierDialog> {
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialSupplier != null) {
      _nameController.text = widget.initialSupplier!.name;
      _contactPersonController.text = widget.initialSupplier!.contactPerson ?? '';
      _phoneController.text = widget.initialSupplier!.phone ?? '';
      _emailController.text = widget.initialSupplier!.email ?? '';
      _addressController.text = widget.initialSupplier!.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialSupplier != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isEditing ? LucideIcons.edit3 : LucideIcons.truck,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Edit Supplier' : 'Add New Supplier',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'Company Name *',
                    hint: 'e.g., Prime Distributors',
                    controller: _nameController,
                    prefixIcon: LucideIcons.building,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter a name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Contact Person',
                    hint: 'e.g., John Doe',
                    controller: _contactPersonController,
                    prefixIcon: LucideIcons.user,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Phone Number',
                          hint: 'e.g., 0300...',
                          controller: _phoneController,
                          prefixIcon: LucideIcons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: 'Email Address',
                          hint: 'e.g., john@example.com',
                          controller: _emailController,
                          prefixIcon: LucideIcons.mail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Physical Address',
                    hint: 'e.g., 123 Industrial Area...',
                    controller: _addressController,
                    prefixIcon: LucideIcons.mapPin,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saveSupplier,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(isEditing ? 'Save Changes' : 'Add Supplier'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SuppliersProvider>();
    final supplier = Supplier(
      id: widget.initialSupplier?.id,
      name: _nameController.text.trim(),
      contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      totalPurchased: widget.initialSupplier?.totalPurchased ?? 0.0,
      currentDue: widget.initialSupplier?.currentDue ?? 0.0,
      createdAt: widget.initialSupplier?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.initialSupplier != null) {
        await provider.updateSupplier(supplier);
      } else {
        await provider.addSupplier(supplier);
      }
      
      if (mounted) {
        Navigator.pop(context);
        AppToast.show(
          context,
          title: 'Success',
          message: 'Supplier saved successfully',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: 'Error',
          message: 'Failed to save supplier: $e',
          type: ToastType.error,
        );
      }
    }
  }
}
