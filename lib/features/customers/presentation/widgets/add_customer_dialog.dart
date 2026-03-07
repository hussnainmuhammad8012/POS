import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/entities.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/toast_notification.dart';
import '../../application/customers_provider.dart';

class AddCustomerDialog extends StatefulWidget {
  final Customer? initialCustomer;

  const AddCustomerDialog({super.key, this.initialCustomer});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;
  late final TextEditingController _creditLimitController;

  bool _isSaving = false;
  bool get isEditing => widget.initialCustomer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCustomer;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _whatsappController = TextEditingController(text: c?.whatsappNumber ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _creditLimitController = TextEditingController(text: c?.creditLimit.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  String? _validatePakistaniPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    // Valid formats: 03XXxxxxxxx, +923XXxxxxxxx, 923XXxxxxxxx
    final regExp = RegExp(r'^((\+92)|(0092)|(92)|0)?3\d{2}-?\d{7}$');
    if (!regExp.hasMatch(value.replaceAll(' ', ''))) {
      return 'Enter a valid Pakistani mobile number (e.g., 03001234567)';
    }
    return null;
  }

  void _copyPhoneToWhatsapp() {
    if (_phoneController.text.isNotEmpty) {
      setState(() {
        _whatsappController.text = _phoneController.text;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<CustomersProvider>();

    try {
      final customer = Customer(
        id: widget.initialCustomer?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        whatsappNumber: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0.0,
        currentCredit: widget.initialCustomer?.currentCredit ?? 0.0,
        loyaltyPoints: widget.initialCustomer?.loyaltyPoints ?? 0,
        totalSpent: widget.initialCustomer?.totalSpent ?? 0.0,
        lastPurchaseDate: widget.initialCustomer?.lastPurchaseDate,
        createdAt: widget.initialCustomer?.createdAt ?? DateTime.now(),
      );

      if (isEditing) {
        await provider.updateCustomer(customer);
        if (mounted) {
          AppToast.show(
            context,
            title: 'Success',
            message: 'Customer updated successfully',
            type: ToastType.success,
          );
        }
      } else {
        await provider.addCustomer(customer);
        if (mounted) {
          AppToast.show(
            context,
            title: 'Success',
            message: 'Customer added successfully',
            type: ToastType.success,
          );
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: 'Action Failed',
          message: e.toString(),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(isEditing ? LucideIcons.userCog : LucideIcons.userPlus, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: LucideIcons.user,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        prefixIcon: LucideIcons.phone,
                        validator: _validatePakistaniPhone,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Copy to WhatsApp',
                      child: IconButton(
                        icon: const Icon(LucideIcons.copy, size: 18),
                        onPressed: _copyPhoneToWhatsapp,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomTextField(
                        controller: _whatsappController,
                        label: 'WhatsApp',
                        prefixIcon: LucideIcons.messageCircle,
                        validator: _validatePakistaniPhone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  prefixIcon: LucideIcons.mail,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'Address (Optional)',
                  prefixIcon: LucideIcons.mapPin,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _creditLimitController,
                  label: 'Credit Limit (Optional)',
                  prefixIcon: LucideIcons.badgeDollarSign,
                  keyboardType: TextInputType.number,
                  hint: '0.00',
                  validator: (v) => v != null && v.isNotEmpty && double.tryParse(v) == null ? 'Must be a valid amount' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEditing ? 'Save Changes' : 'Add Customer'),
        ),
      ],
    );
  }
}
