import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:companion_app/core/theme/app_theme.dart';
import 'package:companion_app/core/widgets/custom_text_field.dart';
import 'package:companion_app/features/inventory/application/inventory_provider.dart';

class AddSupplierDialog extends StatefulWidget {
  const AddSupplierDialog({super.key});

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
  bool _isSaving = false;

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
            const Icon(LucideIcons.truck, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Add New Supplier', style: TextStyle(color: Colors.white, fontSize: 18)),
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Company Name *',
                  hint: 'e.g., Prime Distributors',
                  prefixIcon: LucideIcons.building,
                  validator: (v) => v == null || v.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _contactPersonController,
                  label: 'Contact Person',
                  hint: 'e.g., John Doe',
                  prefixIcon: LucideIcons.user,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'e.g., 0300...',
                  prefixIcon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'e.g., john@example.com',
                  prefixIcon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'Physical Address',
                  hint: 'e.g., 123 Industrial Area...',
                  prefixIcon: LucideIcons.mapPin,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY)),
        ),
        const Spacer(),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.STAR_PRIMARY,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSaving ? null : _saveSupplier,
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Add Supplier'),
        ),
      ],
    );
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final provider = context.read<InventoryProvider>();
    final success = await provider.addSupplier(
      name: _nameController.text.trim(),
      contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Supplier Added Successfully!'), 
            backgroundColor: AppColors.SUCCESS,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add supplier'), 
            backgroundColor: AppColors.DANGER,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
