import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import 'app_dropdown.dart'; // Reuse AppDropdownItem and styles

class AppActionMenu<T> extends StatefulWidget {
  final IconData icon;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final String? tooltip;

  const AppActionMenu({
    super.key,
    this.icon = LucideIcons.moreVertical,
    required this.items,
    required this.onSelected,
    this.tooltip,
  });

  @override
  State<AppActionMenu<T>> createState() => _AppActionMenuState<T>();
}

class _AppActionMenuState<T> extends State<AppActionMenu<T>>
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
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
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

  void _selectItem(T value) {
    widget.onSelected(value);
    _close();
  }

  OverlayEntry _buildOverlay() {
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    // Calculate if we should show above or below
    final screenHeight = MediaQuery.of(context).size.height;
    final showAbove = offset.dy + 300 > screenHeight;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(-160.0 + size.width, showAbove ? - (widget.items.length * 45.0 + 20.0) : size.height + 4.0),
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    alignment: showAbove ? Alignment.bottomRight : Alignment.topRight,
                    child: Container(
                      width: 200,
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
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: widget.items.length,
                          itemBuilder: (context, index) {
                            final item = widget.items[index];
                            return _MenuTile(
                              item: item,
                              onTap: () => _selectItem(item.value),
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
    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        key: _key,
        icon: Icon(widget.icon, size: 20),
        onPressed: _toggle,
        tooltip: widget.tooltip ?? 'Actions',
        color: _isOpen ? Theme.of(context).primaryColor : null,
      ),
    );
  }
}

class _MenuTile<T> extends StatefulWidget {
  final AppDropdownItem<T> item;
  final VoidCallback onTap;

  const _MenuTile({required this.item, required this.onTap});

  @override
  State<_MenuTile<T>> createState() => _MenuTileState<T>();
}

class _MenuTileState<T> extends State<_MenuTile<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hoverColor = isDark 
        ? theme.primaryColor.withOpacity(0.1) 
        : theme.primaryColor.withOpacity(0.05);
    final iconColor = widget.item.label.toLowerCase().contains('delete') 
        ? Colors.red 
        : (isDark ? theme.primaryColor.withOpacity(0.8) : theme.primaryColor);
    final textColor = widget.item.label.toLowerCase() == 'delete' 
        ? Colors.red 
        : (isDark ? Colors.white : Colors.black87);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(widget.item.icon, size: 18, color: iconColor),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (_isHovered)
                Icon(LucideIcons.chevronRight, size: 14, color: iconColor.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
