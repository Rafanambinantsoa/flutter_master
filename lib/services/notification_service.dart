import 'package:flutter/foundation.dart';
import 'package:flutter_master/screens/notifications_screen.dart';

class NotificationService extends ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(AppNotification notification) {
    _notifications.insert(
      0,
      notification,
    ); // Add new notifications at the beginning
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }
}
