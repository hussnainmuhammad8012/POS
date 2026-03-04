import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeType { neutral, success, warning, error, info }

class BadgeWidget extends StatelessWidget {
  final String label;
  final BadgeType type;

  const BadgeWidget({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    Color bg;
    Color fg;

    switch (type) {
      case BadgeType.success:
        bg = AppColors.SUCCESS.withOpacity(isDark ? 0.2 : 0.1);
        fg = isDark ? AppColors.SUCCESS_DARK : AppColors.SUCCESS;
        break;
      case BadgeType.warning:
        bg = AppColors.WARNING.withOpacity(isDark ? 0.2 : 0.1);
        fg = isDark ? AppColors.WARNING_DARK : AppColors.WARNING;
        break;
      case BadgeType.error:
        bg = AppColors.DANGER.withOpacity(isDark ? 0.2 : 0.1);
        fg = isDark ? AppColors.DANGER_DARK : AppColors.DANGER;
        break;
      case BadgeType.info:
        bg = AppColors.INFO.withOpacity(isDark ? 0.2 : 0.1);
        fg = isDark ? AppColors.INFO_DARK : AppColors.INFO;
        break;
      case BadgeType.neutral:
      default:
        bg = primaryColor.withOpacity(0.1);
        fg = primaryColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fg.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
