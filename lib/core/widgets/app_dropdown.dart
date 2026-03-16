import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

/// A dropdown item model
class AppDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool isGroupHeader;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.isGroupHeader = false,
  });
}

/// A premium, theme-aware dropdown widget that replaces DropdownButtonFormField
class AppDropdown<T> extends StatefulWidget {
  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? label;
  final String hint;
  final IconData? prefixIcon;
  final FormFieldValidator<T>? validator;
  final bool isRequired;
  final double maxMenuHeight;

  const AppDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint = 'Select an option',
    this.prefixIcon,
    this.validator,
    this.isRequired = false,
    this.maxMenuHeight = 280,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _hasError = false;
  String? _errorText;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  final _key = GlobalKey();

  T? get _selectedValue => widget.value;
  AppDropdownItem<T>? get _selectedItem =>
      widget.items.where((i) => i.value == _selectedValue && !i.isGroupHeader).firstOrNull;

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
    _animController.reverse().then((_) => _removeOverlay());
    setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectItem(T value) {
    widget.onChanged(value);
    _close();
    if (widget.isRequired) {
      setState(() {
        _hasError = false;
        _errorText = null;
      });
    }
  }

  OverlayEntry _buildOverlay() {
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    alignment: Alignment.topCenter,
                    child: _DropdownMenu<T>(
                      items: widget.items,
                      selectedValue: _selectedValue,
                      width: size.width,
                      maxHeight: widget.maxMenuHeight,
                      onSelect: _selectItem,
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
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    final borderColor = _hasError
        ? theme.colorScheme.error
        : _isOpen
            ? primary
            : (isDark ? AppColors.DARK_BORDER_PROMINENT : AppColors.LIGHT_BORDER_PROMINENT);

    final fillColor = isDark ? AppColors.DARK_BACKGROUND : AppColors.LIGHT_CARD;
    final textColor = isDark ? AppColors.DARK_TEXT_PRIMARY : AppColors.LIGHT_TEXT_PRIMARY;
    final hintColor = isDark ? AppColors.DARK_TEXT_TERTIARY : AppColors.LIGHT_TEXT_TERTIARY;

    return FormField<T>(
      validator: (_) {
        if (widget.validator != null) {
          final err = widget.validator!(_selectedValue);
          if (mounted) setState(() {
            _hasError = err != null;
            _errorText = err;
          });
          return err;
        }
        return null;
      },
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label! + (widget.isRequired ? ' *' : ''),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: _hasError ? theme.colorScheme.error : textColor,
              ),
            ),
            const SizedBox(height: 6),
          ],
          CompositedTransformTarget(
            link: _layerLink,
            child: GestureDetector(
              key: _key,
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor,
                    width: _isOpen ? 2 : 1,
                  ),
                  boxShadow: _isOpen
                      ? [
                          BoxShadow(
                            color: primary.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    if (widget.prefixIcon != null) ...[
                      Icon(
                        widget.prefixIcon,
                        size: 18,
                        color: _isOpen ? primary : hintColor,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: _selectedItem != null
                          ? Row(
                              children: [
                                if (_selectedItem!.icon != null) ...[
                                  Icon(_selectedItem!.icon, size: 16, color: primary),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    _selectedItem!.label,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              widget.hint,
                              style: theme.textTheme.bodyMedium?.copyWith(color: hintColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: _isOpen ? primary : hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_hasError && _errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              _errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DropdownMenu<T> extends StatefulWidget {
  final List<AppDropdownItem<T>> items;
  final T? selectedValue;
  final double width;
  final double maxHeight;
  final ValueChanged<T> onSelect;

  const _DropdownMenu({
    required this.items,
    required this.selectedValue,
    required this.width,
    required this.maxHeight,
    required this.onSelect,
  });

  @override
  State<_DropdownMenu<T>> createState() => _DropdownMenuState<T>();
}

class _DropdownMenuState<T> extends State<_DropdownMenu<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    final menuBg = isDark ? AppColors.DARK_SURFACE : Colors.white;
    final borderColor = isDark ? AppColors.DARK_BORDER_PROMINENT : AppColors.LIGHT_BORDER_PROMINENT;
    final hoverColor = isDark ? AppColors.DARK_HOVER : AppColors.LIGHT_HOVER;
    final textColor = isDark ? AppColors.DARK_TEXT_PRIMARY : AppColors.LIGHT_TEXT_PRIMARY;
    final subtitleColor = isDark ? AppColors.DARK_TEXT_SECONDARY : AppColors.LIGHT_TEXT_SECONDARY;

    return Container(
      width: widget.width,
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      decoration: BoxDecoration(
        color: menuBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: widget.items.length > 5,
          child: ListView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final isSelected = item.value == widget.selectedValue;

              if (item.isGroupHeader) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Text(
                    item.label.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: subtitleColor,
                      fontSize: 10,
                    ),
                  ),
                );
              }

              return _DropdownMenuTile(
                item: item,
                isSelected: isSelected,
                hoverColor: hoverColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                primary: primary,
                onTap: () => widget.onSelect(item.value as T),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DropdownMenuTile<T> extends StatefulWidget {
  final AppDropdownItem<T> item;
  final bool isSelected;
  final Color hoverColor;
  final Color textColor;
  final Color subtitleColor;
  final Color primary;
  final VoidCallback onTap;

  const _DropdownMenuTile({
    required this.item,
    required this.isSelected,
    required this.hoverColor,
    required this.textColor,
    required this.subtitleColor,
    required this.primary,
    required this.onTap,
  });

  @override
  State<_DropdownMenuTile<T>> createState() => _DropdownMenuTileState<T>();
}

class _DropdownMenuTileState<T> extends State<_DropdownMenuTile<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? widget.primary.withOpacity(0.08)
        : (_isHovered ? widget.hoverColor : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(
                  widget.item.icon,
                  size: 16,
                  color: widget.isSelected ? widget.primary : widget.subtitleColor,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: widget.isSelected ? widget.primary : widget.textColor,
                      ),
                    ),
                    if (widget.item.subtitle != null)
                      Text(
                        widget.item.subtitle!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: widget.subtitleColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.isSelected)
                Icon(Icons.check_rounded, size: 16, color: widget.primary),
            ],
          ),
        ),
      ),
    );
  }
}
