import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../application/stock_provider.dart';
import '../../../../core/widgets/modern_card.dart';
import '../../../../core/widgets/badge_widget.dart';

class StockTab extends StatelessWidget {
  const StockTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final movements = provider.filteredMovements;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildFilterChip(context, 'All', 'ALL', provider),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'In', 'IN', provider),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Out', 'OUT', provider),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add Stock'),
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
    // Simplified filter chip logic
    return FilterChip(
      selected: false, // Replace with provider.movementTypeFilter == value
      label: Text(label),
      onSelected: (selected) => provider.setMovementTypeFilter(value),
    );
  }

  Widget _buildMovementItem(BuildContext context, dynamic movement) {
    final bool isIn = movement.quantityChange > 0;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
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
            movement.createdAt.toString().split('.')[0], // Simple format
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
          Icon(LucideIcons.history, size: 48, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No stock movements recorded yet.'),
        ],
      ),
    );
  }
}
