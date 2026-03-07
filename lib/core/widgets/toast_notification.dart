import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

enum ToastType { success, error, warning, info }

class ToastNotification extends StatefulWidget {
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
  State<ToastNotification> createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<ToastNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color color;
    IconData icon;
    switch (widget.type) {
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

    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 380,
          margin: const EdgeInsets.only(top: 80, right: 24), // Below the 64px header
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
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _dismiss,
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
        ),
      ),
    );
  }
}

class AppToast {
  static final Map<OverlayEntry, GlobalKey<_ToastNotificationState>> _activeToasts = {};

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    ToastType type = ToastType.info,
  }) {
    final overlay = Overlay.of(context);
    final toastKey = GlobalKey<_ToastNotificationState>();
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: ToastNotification(
            key: toastKey,
            title: title,
            message: message,
            type: type,
            onDismiss: () {
              overlayEntry.remove();
              _activeToasts.remove(overlayEntry);
            },
          ),
        ),
      ),
    );

    _activeToasts[overlayEntry] = toastKey;
    overlay.insert(overlayEntry);

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        toastKey.currentState?._dismiss();
      }
    });
  }
}
