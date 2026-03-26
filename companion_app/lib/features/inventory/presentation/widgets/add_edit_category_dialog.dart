import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:companion_app/core/theme/app_theme.dart';
import 'package:companion_app/core/widgets/custom_text_field.dart';
import 'package:companion_app/core/widgets/app_dropdown.dart';
import 'package:companion_app/features/inventory/application/inventory_provider.dart';
import 'package:companion_app/features/inventory/data/models/category_model.dart';

class AddEditCategoryDialog extends StatefulWidget {
  final Category? category; // null = add mode
  final String? parentId;   // pre-set when adding subcategory

  const AddEditCategoryDialog({super.key, this.category, this.parentId});

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  String? _selectedParentId;
  bool _isSaving = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _descCtrl = TextEditingController(text: widget.category?.description ?? '');
    _selectedParentId = widget.parentId ?? widget.category?.parentId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    final parentCategories = provider.categories.where((c) => c.parentId == null).toList();

    return AlertDialog(
      backgroundColor: AppColors.STAR_BACKGROUND,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.STAR_PRIMARY,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Icon(_isEditing ? LucideIcons.pencil : LucideIcons.folderPlus, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              _isEditing ? 'Edit Category' : (_selectedParentId != null ? 'Add Subcategory' : 'Add Category'),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Category Name',
                controller: _nameCtrl,
                prefixIcon: LucideIcons.folder,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Description (optional)',
                controller: _descCtrl,
                prefixIcon: LucideIcons.fileText,
              ),
              if (!_isEditing || widget.parentId != null) ...[
                const SizedBox(height: 12),
                AppDropdown<String?>(
                  label: 'Parent Category (leave empty for root)',
                  hint: 'No parent (root category)',
                  prefixIcon: LucideIcons.folder,
                  value: _selectedParentId,
                  items: [
                    const AppDropdownItem<String?>(value: null, label: 'Root Category'),
                    ...parentCategories.map((c) => AppDropdownItem<String?>(value: c.id, label: c.name, icon: LucideIcons.folder)),
                  ],
                  onChanged: (v) => setState(() => _selectedParentId = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.STAR_TEXT_SECONDARY)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : () async {
            if (!_formKey.currentState!.validate()) return;
            setState(() => _isSaving = true);

            String? error;
            if (_isEditing) {
              error = await provider.editCategory(
                categoryId: widget.category!.id,
                name: _nameCtrl.text.trim(),
                description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              );
            } else {
              error = await provider.addCategory(
                name: _nameCtrl.text.trim(),
                parentId: _selectedParentId,
                description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              );
            }

            if (mounted) {
              setState(() => _isSaving = false);
              if (error == null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isEditing ? 'Category updated!' : 'Category added!'),
                    backgroundColor: AppColors.STAR_PRIMARY,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error'), backgroundColor: AppColors.DANGER),
                );
              }
            }
          },
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isEditing ? 'Save Changes' : 'Add Category'),
        ),
      ],
    );
  }
}
