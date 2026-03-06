import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../application/inventory_provider.dart';
import '../../../../core/widgets/modern_card.dart';
import 'add_category_dialog.dart';

class CategoryTab extends StatelessWidget {
  const CategoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final categories = provider.categories;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddCategoryDialog(context, provider),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add Category'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: categories.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _buildCategoryItem(context, category, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, dynamic category, InventoryProvider provider) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(LucideIcons.folder, color: Theme.of(context).colorScheme.primary),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(category.description ?? 'No description'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 18),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(LucideIcons.plusCircle, size: 18),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AddCategoryDialog(parentId: category.id),
              ),
              tooltip: 'Add Subcategory',
            ),
          ],
        ),
        children: [
          if (category.subcategories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No subcategories'),
            )
          else
            ...category.subcategories.map((sub) => ListTile(
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                  leading: const Icon(LucideIcons.cornerDownRight, size: 16),
                  title: Text(sub.name),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.pencil, size: 16),
                    onPressed: () {},
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.layers,
              size: 48,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No categories found'),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );
  }
}
