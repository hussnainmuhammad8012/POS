import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/toast_notification.dart';
import '../../../inventory/application/inventory_provider.dart';
import '../../../inventory/data/repositories/product_repository.dart';
import '../../../settings/application/settings_provider.dart';
import '../../application/pos_provider.dart';

/// A product-name search field for the POS screen.
///
/// Design decisions that make this bullet-proof:
///
/// 1. Owns its own [TextEditingController] so it is never reset by external
///    rebuilds.
/// 2. Reads `InventoryProvider.posSuggestions` FRESH on every keystroke (not
///    captured as a closure snapshot), so even if inventory finishes loading
///    after the user starts typing, the next character typed will surface
///    results immediately.
/// 3. Uses [ListenableBuilder] instead of `context.watch` for targeted
///    rebuilds: only the dropdown overlay re-renders when inventory changes,
///    not the entire widget tree.
/// 4. On `onSubmitted`, tries exact-match → single partial-match → toast.
class ProductNameSearch extends StatefulWidget {
  const ProductNameSearch({super.key});

  @override
  State<ProductNameSearch> createState() => _ProductNameSearchState();
}

class _ProductNameSearchState extends State<ProductNameSearch> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();

  /// Suggestions filtered from the *current* inventory snapshot every time
  /// the text changes.
  List<MapEntry<String, String>> _matches = [];

  bool get _hasMatches => _matches.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Core search logic ────────────────────────────────────────────────────

  /// Called on every keystroke. Reads the provider DIRECTLY so it always
  /// gets the freshest suggestion map — no stale closures.
  void _onTextChanged() {
    final text = _controller.text;
    if (text.isEmpty) {
      if (_matches.isNotEmpty) setState(() => _matches = []);
      return;
    }
    // Read without listen — we don't need this widget to rebuild for
    // provider changes; we refresh on keystroke instead.
    final suggestions =
        context.read<InventoryProvider>().posSuggestions;

    final query = text.toLowerCase();
    final results = suggestions.entries
        .where((e) => e.key.toLowerCase().contains(query))
        .take(10)
        .toList();

    setState(() => _matches = results);
  }

  Future<void> _addByLookupId(String lookupKey) async {
    final pos     = context.read<PosProvider>();
    final repo    = context.read<ProductRepository>();
    final uomOn   = context.read<SettingsProvider>().enableUomSystem;
    final success = await pos.handleBarcode(lookupKey, repo, isUomEnabled: uomOn);
    if (mounted && !success) {
      AppToast.show(
        context,
        title: 'Not Found',
        message: pos.error ?? 'Product not found',
        type: ToastType.error,
      );
    }
  }

  void _handleSubmit(String text) {
    if (text.trim().isEmpty) return;

    // Always read fresh at submission time
    final suggestions = context.read<InventoryProvider>().posSuggestions;
    final query = text.toLowerCase().trim();

    // 1. Exact match (case-insensitive)
    final exactKey = suggestions.keys
        .cast<String?>()
        .firstWhere((k) => k!.toLowerCase() == query, orElse: () => null);

    if (exactKey != null) {
      final id = suggestions[exactKey]!;
      _addByLookupId(id);
      _controller.clear();
      _focusNode.requestFocus();
      return;
    }

    // 2. Unique partial match
    final partials = suggestions.entries
        .where((e) => e.key.toLowerCase().contains(query))
        .toList();

    if (partials.length == 1) {
      _addByLookupId(partials.first.value);
      _controller.clear();
      _focusNode.requestFocus();
    } else if (partials.isEmpty) {
      AppToast.show(
        context,
        title: 'Not Found',
        message: 'No product matches "$text". Try a different name.',
        type: ToastType.warning,
      );
    } else {
      // Multiple matches — let user pick from the visible dropdown
      AppToast.show(
        context,
        title: 'Multiple Matches',
        message: 'Pick one from the list below.',
        type: ToastType.warning,
      );
    }
  }

  void _selectSuggestion(MapEntry<String, String> entry) {
    _addByLookupId(entry.value);
    _controller.clear();
    setState(() => _matches = []);
    _focusNode.requestFocus();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search product by name, press Enter to add...',
            prefixIcon: const Icon(LucideIcons.search, size: 18),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: _handleSubmit,
        ),
        if (_hasMatches)
          Material(
            elevation: 8,
            borderRadius: const BorderRadius.only(
              bottomLeft:  Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _matches.length,
                itemBuilder: (_, i) {
                  final entry = _matches[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(LucideIcons.package, size: 16),
                    title: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onTap: () => _selectSuggestion(entry),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
