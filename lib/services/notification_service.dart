import 'package:flutter/material.dart';
import 'package:pusher_client/pusher_client.dart';
import '../screens/notifications_screen.dart'; // To use AppNotification

class NotificationService extends ChangeNotifier {
  PusherClient? pusher;
  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  NotificationService() {
    _initPusher();
  }

  void _initPusher() {
    // Replace with your Pusher app key and cluster
    pusher = PusherClient(
      "64847502664fa3c1a5d6", // Replace with actual key
      PusherOptions(
        cluster: "mt1", // Replace with actual cluster
        // Other options like encrypted, auth, etc.
      ),
      enableLogging: true,
    );

    pusher?.connect();

    pusher?.onConnectionStateChange((state) {
      print("Pusher connection state changed: ${state?.currentState}");
    });

    // Handle general errors
    pusher?.onConnectionError((error) {
      print("Pusher connection error: ${error?.message}");
    });

    // Subscribe to the 'server-notifications' channel
    Channel? channel = pusher?.subscribe('server-notifications');

    // Bind to the 'order-ready' event
    channel?.bind('order-ready', (event) {
      if (event?.data != null) {
        final data = event!.data;
        // Parse the data and create an AppNotification
        final newNotification = AppNotification(
          id: DateTime.now().millisecondsSinceEpoch, // Generate a unique ID
          title: 'Commande prête',
          message: 'La commande  est prête à être servie.',
          createdAt: DateTime.now(),
          kind: NotificationKind.order,
          isRead: false,
        );
        _notifications.insert(
          0,
          newNotification,
        ); // Add to the beginning of the list
        notifyListeners(); // Notify listeners to rebuild UI
      }
    });
  }

  void markAsRead(AppNotification notification) {
    if (!notification.isRead) {
      notification.isRead = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    pusher?.disconnect();
    super.dispose();
  }
}
