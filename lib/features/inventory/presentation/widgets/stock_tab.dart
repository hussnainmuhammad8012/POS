import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../application/stock_provider.dart';
import '../../application/inventory_provider.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/app_dropdown.dart';

class StockTab extends StatelessWidget {
  const StockTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final inventoryProvider = context.watch<InventoryProvider>();
    final movements = provider.filteredMovements;
    
    final categories = inventoryProvider.categories;
    final products = inventoryProvider.filteredProducts;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildFilterChip(context, 'All', 'ALL', provider),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'In', 'IN', provider),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Out', 'OUT', provider),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Category Filter
              Expanded(
                child: AppDropdown<String?>(
                  value: provider.selectedCategoryId,
                  label: 'Category',
                  hint: 'All Categories',
                  prefixIcon: LucideIcons.folder,
                  items: [
                    const AppDropdownItem(value: null, label: 'All Categories'),
                    ...categories.map((c) => AppDropdownItem(value: c.id, label: c.name)),
                  ],
                  onChanged: (val) => provider.setCategoryFilter(val),
                ),
              ),
              const SizedBox(width: 16),
              // Product Filter
              Expanded(
                child: AppDropdown<String?>(
                  value: provider.selectedProductId,
                  label: 'Product',
                  hint: 'All Products',
                  prefixIcon: LucideIcons.package,
                  items: [
                    const AppDropdownItem(value: null, label: 'All Products'),
                    ...products.map((p) => AppDropdownItem(value: p.product.id, label: p.product.name)),
                  ],
                  onChanged: (val) => provider.setProductFilter(val),
                ),
              ),
              if (provider.selectedCategoryId != null || provider.selectedProductId != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 22), // Align with center of dropdowns (which have labels)
                  child: IconButton(
                    icon: const Icon(LucideIcons.xCircle, color: Colors.grey),
                    onPressed: () => provider.clearFilters(),
                    tooltip: 'Clear filters',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ModernCard(
              padding: EdgeInsets.zero,
              mainAxisSize: MainAxisSize.max,
              child: movements.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: movements.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final movement = movements[index];
                        return _buildMovementItem(context, movement);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value, StockProvider provider) {
    final isSelected = provider.movementTypeFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) => provider.setMovementTypeFilter(value),
      backgroundColor: Colors.transparent,
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildMovementItem(BuildContext context, dynamic movement) {
    final bool isIn = movement.quantityChange > 0;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIn ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        child: Icon(
          isIn ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
          color: isIn ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
      title: Text(movement.productName ?? 'Unknown Product', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.tag, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(movement.categoryName ?? 'Uncategorized', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${movement.reason} • By: ${movement.recordedBy ?? 'System'}'),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isIn ? '+' : ''}${movement.quantityChange}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isIn ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM dd, HH:mm').format(movement.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      isThreeLine: true,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.history, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No stock movements recorded for selected filters.'),
        ],
      ),
    );
  }
}
