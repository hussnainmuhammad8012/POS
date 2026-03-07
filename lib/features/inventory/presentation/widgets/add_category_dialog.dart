import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/category_model.dart';
import '../../application/inventory_provider.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/app_dropdown.dart';

class AddCategoryDialog extends StatefulWidget {
  final String? parentId;
  final Category? category;
  const AddCategoryDialog({super.key, this.parentId, this.category});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  String? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _descController = TextEditingController(text: widget.category?.description);
    _selectedParentId = widget.category?.parentId ?? widget.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final isEditing = widget.category != null;
    
    return AlertDialog(
      title: Text(isEditing 
        ? 'Edit Category' 
        : (widget.parentId == null ? 'Add Category' : 'Add Subcategory')),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Category Name',
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descController,
                  label: 'Description',
                  maxLines: 2,
                ),
                if (widget.parentId == null) ...[
                  const SizedBox(height: 16),
                  AppDropdown<String?>(
                    label: 'Parent Category',
                    hint: 'None (Root Category)',
                    prefixIcon: LucideIcons.folderTree,
                    value: _selectedParentId,
                    items: [
                      const AppDropdownItem<String?>(
                        value: null,
                        label: 'None (Root Category)',
                        icon: LucideIcons.layoutGrid,
                      ),
                      ...provider.categories
                        .where((c) => c.parentId == null)
                        .map((c) => AppDropdownItem<String?>(
                          value: c.id,
                          label: c.name,
                          icon: LucideIcons.folder,
                        )),
                    ],
                    onChanged: (v) => setState(() => _selectedParentId = v),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (isEditing) {
                await provider.updateCategory(
                  widget.category!.id,
                  name: _nameController.text,
                  parentId: _selectedParentId,
                  description: _descController.text,
                );
              } else {
                await provider.createCategory(
                  name: _nameController.text,
                  parentId: _selectedParentId,
                  description: _descController.text,
                );
              }
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
