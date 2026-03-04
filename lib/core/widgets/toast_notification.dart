import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

enum ToastType { success, error, warning, info }

class ToastNotification extends StatelessWidget {
  final String title;
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const ToastNotification({
    super.key,
    required this.title,
    required this.message,
    this.type = ToastType.info,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color color;
    IconData icon;
    switch (type) {
      case ToastType.success:
        color = isDark ? AppColors.SUCCESS_DARK : AppColors.SUCCESS;
        icon = LucideIcons.checkCircle2;
        break;
      case ToastType.error:
        color = isDark ? AppColors.DANGER_DARK : AppColors.DANGER;
        icon = LucideIcons.xCircle;
        break;
      case ToastType.warning:
        color = isDark ? AppColors.WARNING_DARK : AppColors.WARNING;
        icon = LucideIcons.alertTriangle;
        break;
      case ToastType.info:
      default:
        color = isDark ? AppColors.INFO_DARK : AppColors.INFO;
        icon = LucideIcons.info;
        break;
    }

    return Container(
      width: 380,
      margin: const EdgeInsets.only(bottom: 24, right: 24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerTheme.color ?? (isDark ? AppColors.DARK_BORDER_SUBTLE : AppColors.LIGHT_BORDER_SUBTLE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 20),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: theme.colorScheme.secondary.withAlpha(128),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppToast {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    ToastType type = ToastType.info,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: ToastNotification(
            title: title,
            message: message,
            type: type,
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
