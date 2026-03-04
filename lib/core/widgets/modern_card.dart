import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ModernCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? title;
  final Widget? trailing;

  const ModernCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.title,
    this.trailing,
  });

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: _isHovered 
                ? primaryColor.withAlpha(100)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            if (_isHovered) ...[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 40,
                offset: const Offset(0, 12),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ] else ...[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.title != null || widget.trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          style: theme.textTheme.titleLarge,
                        ),
                      if (widget.trailing != null) widget.trailing!,
                    ],
                  ),
                ),
              Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
