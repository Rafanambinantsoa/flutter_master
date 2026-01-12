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
        final int unreadCount = notificationService.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: onPressed ??
                  () {
                    // Marquer toutes les notifications comme lues avant de naviguer
                    if (notificationService.unreadCount > 0) {
                      notificationService.markAllAsRead();
                      print(
                        '✅ [NotificationBadgeIcon] Toutes les notifications marquées comme lues',
                      );
                    }
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
