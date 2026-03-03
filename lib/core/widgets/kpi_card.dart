import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? trend;
  final bool isTrendPositive;
  final bool isPrimary;
  final Color? accentColor;
  final Color? softBackground;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.trend,
    this.isTrendPositive = true,
    this.isPrimary = false,
    this.accentColor,
    this.softBackground,
  });

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryAccent = widget.accentColor ?? (isDark ? AppColors.PRIMARY_ACCENT_DARK : AppColors.PRIMARY_ACCENT_LIGHT);
    final bgColor = widget.softBackground ?? (widget.isPrimary 
        ? null 
        : (isDark ? AppColors.DARK_CARD : AppColors.LIGHT_CARD));
    
    final textColor = widget.isPrimary ? Colors.white : theme.textTheme.displayMedium?.color;
    final secondaryColor = widget.isPrimary ? Colors.white.withAlpha(200) : theme.colorScheme.secondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.isPrimary ? null : bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: widget.isPrimary
              ? LinearGradient(
                  colors: [primaryAccent, primaryAccent.withAlpha(200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            if (_isHovered) ...[
              BoxShadow(
                color: (widget.isPrimary ? primaryAccent : Colors.black).withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 40,
                offset: const Offset(0, 12),
                spreadRadius: -4,
              ),
            ] else ...[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ],
          border: Border.all(
            color: _isHovered 
                ? primaryAccent.withValues(alpha: 0.2)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.value,
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isPrimary ? Colors.white.withAlpha(40) : (widget.accentColor ?? primaryAccent).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: widget.isPrimary ? Colors.white : (widget.accentColor ?? primaryAccent),
                    ),
                  ),
                ],
              ),
              if (widget.trend != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      widget.isTrendPositive ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: widget.isPrimary
                          ? Colors.white
                          : (widget.isTrendPositive
                              ? AppColors.SUCCESS
                              : AppColors.DANGER),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.trend!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.isPrimary
                            ? Colors.white
                            : (widget.isTrendPositive
                                ? AppColors.SUCCESS
                                : AppColors.DANGER),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'v last week',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: secondaryColor.withAlpha(180),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
