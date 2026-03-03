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
    Color bg;
    Color fg;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case BadgeType.success:
        bg = AppColors.success.withOpacity(isDark ? 0.2 : 0.1);
        fg = isDark ? AppColors.success : AppColors.successForeground;
        break;
      case BadgeType.warning:
        bg = AppColors.warning.withOpacity(isDark ? 0.2 : 0.1);
        fg = isDark ? AppColors.warning : AppColors.warningForeground;
        break;
      case BadgeType.error:
        bg = AppColors.danger.withOpacity(isDark ? 0.2 : 0.1);
        fg = isDark ? AppColors.danger : AppColors.dangerForeground;
        break;
      case BadgeType.info:
        bg = AppColors.info.withOpacity(isDark ? 0.2 : 0.1);
        fg = isDark ? AppColors.info : AppColors.infoForeground;
        break;
      case BadgeType.neutral:
      default:
        bg = isDark ? AppColors.darkBorder : AppColors.border;
        fg = isDark ? AppColors.darkText : AppColors.textPrimary;
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
