import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

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

class AppDropdown<T> extends StatefulWidget {
  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? label;
  final String hint;
  final IconData? prefixIcon;
  final FormFieldValidator<T>? validator;
  final bool isRequired;

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
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _hasError = false;
  String? _errorText;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final _key = GlobalKey();

  T? get _selectedValue => widget.value;
  AppDropdownItem<T>? get _selectedItem =>
      widget.items.where((i) => i.value == _selectedValue && !i.isGroupHeader).firstOrNull;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) _close(); else _open();
  }

  void _open() {
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();
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
                  child: Container(
                    width: size.width,
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: AppColors.STAR_CARD,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.STAR_BORDER),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        return ListTile(
                          leading: item.icon != null ? Icon(item.icon, size: 20, color: AppColors.STAR_PRIMARY) : null,
                          title: Text(item.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: item.subtitle != null ? Text(item.subtitle!, style: const TextStyle(fontSize: 12)) : null,
                          onTap: () {
                            widget.onChanged(item.value);
                            _close();
                          },
                        );
                      },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: _key,
            onTap: _toggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.STAR_CARD,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _isOpen ? AppColors.STAR_PRIMARY : AppColors.STAR_BORDER, width: _isOpen ? 2 : 1),
              ),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    Icon(widget.prefixIcon, size: 20, color: AppColors.STAR_TEXT_SECONDARY),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      _selectedItem?.label ?? widget.hint,
                      style: TextStyle(
                        color: _selectedItem != null ? AppColors.STAR_TEXT_PRIMARY : AppColors.STAR_TEXT_SECONDARY.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Icon(LucideIcons.chevronDown, size: 18, color: AppColors.STAR_TEXT_SECONDARY),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
