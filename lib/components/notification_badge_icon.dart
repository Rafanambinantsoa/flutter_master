import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_master/services/notification_service.dart';

class NotificationBadgeIcon extends StatelessWidget {
  final VoidCallback? onPressed;
  const NotificationBadgeIcon({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        print(
          'DEBUG: Rebuilding NotificationBadgeIcon. Unread count: ${notificationService.unreadCount}',
        ); // Debug print
        final int unreadCount = notificationService.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed:
                  onPressed ??
                  () {
                    Navigator.of(context).pushNamed('/notifications');
                  },
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
