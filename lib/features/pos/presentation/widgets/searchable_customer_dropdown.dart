import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/entities.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../customers/application/customers_provider.dart';

class SearchableCustomerDropdown extends StatefulWidget {
  final Customer? value;
  final ValueChanged<Customer?> onChanged;

  const SearchableCustomerDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SearchableCustomerDropdown> createState() => _SearchableCustomerDropdownState();
}

class _SearchableCustomerDropdownState extends State<SearchableCustomerDropdown> {
  final _searchController = TextEditingController();
  bool _isMenuOpen = false;
  final _link = LayerLink();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _searchController.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _hideOverlay,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardTheme.color,
              child: Container(
                width: size.width,
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: _CustomerSearchList(
                  onSelect: (c) {
                    widget.onChanged(c);
                    _hideOverlay();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() => _isMenuOpen = true);
  }

  void _hideOverlay() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isMenuOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: InkWell(
        onTap: _showOverlay,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _isMenuOpen ? Theme.of(context).primaryColor : Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.user, size: 18, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.value?.name ?? 'Walk-in Customer',
                  style: TextStyle(
                    color: widget.value == null ? Theme.of(context).hintColor : null,
                    fontWeight: widget.value != null ? FontWeight.w500 : null,
                  ),
                ),
              ),
              Icon(_isMenuOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerSearchList extends StatefulWidget {
  final ValueChanged<Customer?> onSelect;

  const _CustomerSearchList({required this.onSelect});

  @override
  State<_CustomerSearchList> createState() => _CustomerSearchListState();
}

class _CustomerSearchListState extends State<_CustomerSearchList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomersProvider>();
    final results = provider.customers.where((c) {
      final q = _query.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          (c.phone?.contains(q) ?? false) ||
          (c.whatsappNumber?.contains(q) ?? false);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomTextField(
            hint: 'Search by name or phone...',
            prefixIcon: LucideIcons.search,
            onChanged: (v) => setState(() => _query = v),
            autofocus: true,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.userX, size: 20),
                title: const Text('Walk-in Customer'),
                onTap: () => widget.onSelect(null),
              ),
              ...results.map((c) => ListTile(
                leading: const Icon(LucideIcons.userCheck, size: 20),
                title: Text(c.name),
                subtitle: Text(c.phone ?? ''),
                trailing: c.currentCredit > 0 
                  ? Text('Rs ${c.currentCredit.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.DANGER, fontSize: 12))
                  : null,
                onTap: () => widget.onSelect(c),
              )),
            ],
          ),
        ),
      ],
    );
  }
}
