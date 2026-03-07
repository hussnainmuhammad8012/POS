import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:utility_store_pos/core/features/notifications/application/notification_provider.dart';
import 'package:utility_store_pos/features/customers/presentation/credits_screen.dart';

class NotificationModal extends StatelessWidget {
  const NotificationModal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifications = context.watch<NotificationProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications', style: theme.textTheme.titleLarge),
                  if (notifications.notifications.isNotEmpty)
                    TextButton(
                      onPressed: () => notifications.clearAll(),
                      child: const Text('Clear All'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (notifications.notifications.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.bellOff, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notifications', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  itemCount: notifications.notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notif = notifications.notifications[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notif.isRead 
                            ? theme.disabledColor.withOpacity(0.1)
                            : theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          notif.type == 'CREDIT_REMINDER' ? LucideIcons.creditCard : LucideIcons.bell,
                          color: notif.isRead ? theme.disabledColor : theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        notif.title,
                        style: TextStyle(
                          fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notif.message),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM, hh:mm a').format(notif.createdAt),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      onTap: () {
                        notifications.markAsRead(notif.id);
                        if (notif.type == 'CREDIT_REMINDER') {
                           Navigator.pop(context); // Close modal
                           // Navigate to credits screen (need to handle navigation logic)
                           // For now, let's just assume CreditsScreen is available
                           Navigator.push(
                             context,
                             MaterialPageRoute(builder: (context) => CreditsScreen()),
                           );
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
