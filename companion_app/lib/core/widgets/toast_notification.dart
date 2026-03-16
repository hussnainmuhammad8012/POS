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
    
    Color color;
    IconData icon;
    switch (widget.type) {
      case ToastType.success:
        color = AppColors.SUCCESS;
        icon = LucideIcons.checkCircle2;
        break;
      case ToastType.error:
        color = AppColors.DANGER;
        icon = LucideIcons.xCircle;
        break;
      case ToastType.warning:
        color = AppColors.STAR_YELLOW;
        icon = LucideIcons.alertTriangle;
        break;
      case ToastType.info:
      default:
        color = AppColors.STAR_BLUE;
        icon = LucideIcons.info;
        break;
    }

    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.STAR_BORDER),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
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
                          style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.STAR_TEXT_PRIMARY,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.STAR_TEXT_SECONDARY,
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
                      color: AppColors.STAR_TEXT_SECONDARY.withOpacity(0.5),
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
        left: 0,
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

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        toastKey.currentState?._dismiss();
      }
    });
  }
}
