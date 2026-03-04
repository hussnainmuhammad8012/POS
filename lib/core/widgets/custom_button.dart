import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isDisabled = widget.onPressed == null;
    final scale = _isPressed ? 0.98 : (_isHovered ? 1.03 : 1.0);
    final intensity = _isPressed ? -0.1 : (_isHovered ? 0.05 : 0.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()..scale(scale),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isDisabled
                ? primaryColor.withAlpha(128)
                : HSLColor.fromColor(primaryColor)
                    .withLightness((HSLColor.fromColor(primaryColor).lightness + intensity).clamp(0.0, 1.0))
                    .toColor(),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _isHovered && !isDisabled && !_isPressed
                ? [
                    BoxShadow(
                      color: primaryColor.withAlpha(50),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isDisabled = widget.onPressed == null;
    final scale = _isPressed ? 0.98 : (_isHovered ? 1.03 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()..scale(scale),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered && !isDisabled 
              ? (isDark ? Colors.white.withAlpha(15) : primaryColor.withAlpha(20)) 
              : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDisabled ? primaryColor.withAlpha(128) : primaryColor,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: primaryColor, size: 18),
                const SizedBox(width: 8),
              ],
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDisabled ? primaryColor.withAlpha(128) : primaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DangerButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const DangerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  State<DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<DangerButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final scale = _isPressed ? 0.98 : (_isHovered ? 1.03 : 1.0);
    final intensity = _isPressed ? -0.1 : (_isHovered ? 0.1 : 0.0); 

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()..scale(scale),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.DANGER.withAlpha(128)
                : HSLColor.fromColor(AppColors.DANGER)
                    .withLightness((HSLColor.fromColor(AppColors.DANGER).lightness + intensity).clamp(0.0, 1.0))
                    .toColor(),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _isHovered && !isDisabled && !_isPressed
                ? [
                    BoxShadow(
                      color: AppColors.DANGER.withAlpha(50),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 20,
  });

  @override
  State<CustomIconButton> createState() => _CustomIconButtonState();
}

class _CustomIconButtonState extends State<CustomIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null;
    final scale = _isPressed ? 0.95 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()..scale(scale),
          transformAlignment: Alignment.center,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _isHovered && !isDisabled
                ? (isDark ? Colors.white.withAlpha(20) : theme.primaryColor.withAlpha(20))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: isDisabled
                ? (widget.color ?? theme.textTheme.bodyLarge?.color ?? Colors.black).withAlpha(128)
                : (widget.color ?? theme.textTheme.bodyLarge?.color ?? Colors.black),
          ),
        ),
      ),
    );
  }
}
