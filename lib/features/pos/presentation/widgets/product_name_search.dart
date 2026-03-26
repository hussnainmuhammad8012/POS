import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/toast_notification.dart';
import '../../../inventory/application/inventory_provider.dart';
import '../../../inventory/data/repositories/product_repository.dart';
import '../../../settings/application/settings_provider.dart';
import '../../application/pos_provider.dart';

/// A product-name search field.
/// Type a product name and press Enter (or tap a dropdown suggestion) to add it to cart.
class ProductNameSearch extends StatefulWidget {
  const ProductNameSearch({super.key});

  @override
  State<ProductNameSearch> createState() => _ProductNameSearchState();
}

class _ProductNameSearchState extends State<ProductNameSearch> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _addByLookupId(BuildContext ctx, String lookupKey) async {
    final pos = ctx.read<PosProvider>();
    final repo = ctx.read<ProductRepository>();
    final isUomEnabled = ctx.read<SettingsProvider>().enableUomSystem;
    final success = await pos.handleBarcode(lookupKey, repo, isUomEnabled: isUomEnabled);
    if (mounted && !success) {
      AppToast.show(ctx, title: 'Error', message: pos.error ?? 'Product not found', type: ToastType.error);
    }
  }

  Map<String, String> _buildSuggestions(InventoryProvider inventory) {
    final Map<String, String> suggestions = {};
    for (final p in inventory.filteredProducts) {
      if (p.units.isNotEmpty) {
        for (final u in p.units) {
          final label = '${p.product.name} — ${u.unitName}';
          suggestions[label] = u.barcode ?? p.primaryVariantId ?? p.product.id;
        }
      } else {
        suggestions[p.product.name] = p.barcode ?? p.primaryVariantId ?? p.product.id;
      }
    }
    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final suggestions = _buildSuggestions(inventory);

    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        final query = textEditingValue.text.toLowerCase();
        return suggestions.keys.where((s) => s.toLowerCase().contains(query)).take(8);
      },
      onSelected: (label) {
        // User clicked a suggestion
        final id = suggestions[label];
        if (id != null) _addByLookupId(context, id);
      },
      fieldViewBuilder: (ctx, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Search product by name, press Enter to add...',
            prefixIcon: const Icon(LucideIcons.search, size: 18),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (text) {
            if (text.trim().isEmpty) return;
            // Auto-pick the first matching product and add to cart immediately
            final query = text.toLowerCase();
            final firstMatch = suggestions.keys
                .where((s) => s.toLowerCase().contains(query))
                .firstOrNull;
            if (firstMatch != null) {
              final id = suggestions[firstMatch];
              if (id != null) {
                _addByLookupId(ctx, id);
                controller.clear();
                focusNode.unfocus();
              }
            } else {
              AppToast.show(ctx,
                  title: 'Not Found',
                  message: 'No product matched "$text"',
                  type: ToastType.error);
            }
          },
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: const Icon(LucideIcons.package, size: 16),
                    title: Text(option, style: const TextStyle(fontSize: 13)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
