import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../inventory/data/models/product_unit_model.dart';
import 'package:utility_store_pos/features/pos/data/models/cart_item.dart';
import '../../application/pos_provider.dart';

class AppUomSelector extends StatefulWidget {
  final CartItem item;
  final ValueChanged<ProductUnit> onSelected;

  const AppUomSelector({
    super.key,
    required this.item,
    required this.onSelected,
  });

  @override
  State<AppUomSelector> createState() => _AppUomSelectorState();
}

class _AppUomSelectorState extends State<AppUomSelector>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate( CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) { _close(); } else { _open(); }
  }

  void _open() {
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward(from: 0);
    setState(() => _isOpen = true);
  }

  void _close() {
    if (!mounted) return;
    _animController.reverse().then((_) => _removeOverlay());
    setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectItem(ProductUnit unit) {
    widget.onSelected(unit);
    _close();
  }

  OverlayEntry _buildOverlay() {
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final screenHeight = MediaQuery.of(context).size.height;
    final showAbove = offset.dy + 250 > screenHeight;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, showAbove ? - (widget.item.productUnits.length * 60.0 + 16.0) : size.height + 6.0),
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    alignment: showAbove ? Alignment.bottomLeft : Alignment.topLeft,
                    child: Container(
                      width: 240,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: widget.item.productUnits.length,
                          itemBuilder: (context, index) {
                            final unit = widget.item.productUnits[index];
                            final isSelected = unit.id == widget.item.unitId;
                            return _UomTile(
                              unit: unit,
                              isSelected: isSelected,
                              onTap: () => _selectItem(unit),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _key,
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(_isOpen ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.primaryColor.withOpacity(_isOpen ? 0.4 : 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.item.unitName ?? widget.item.variantName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 14,
                color: theme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UomTile extends StatefulWidget {
  final ProductUnit unit;
  final bool isSelected;
  final VoidCallback onTap;

  const _UomTile({
    required this.unit,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_UomTile> createState() => _UomTileState();
}

class _UomTileState extends State<_UomTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? theme.primaryColor.withOpacity(0.1) 
                : (_isHovered ? theme.primaryColor.withOpacity(0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected ? theme.primaryColor : theme.dividerColor,
                    width: 2,
                  ),
                ),
                child: widget.isSelected 
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.unit.unitName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Rs ${widget.unit.retailPrice.toStringAsFixed(0)} / ${widget.unit.unitName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.unit.conversionRate > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'x${widget.unit.conversionRate}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
