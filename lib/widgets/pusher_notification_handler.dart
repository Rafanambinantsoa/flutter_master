import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/pusher_service.dart';
import '../services/notification_service.dart';
import '../services/notification_feedback_service.dart';

/// Widget global qui gère les notifications Pusher de manière unique
/// Ce widget est monté une seule fois au niveau de l'application
/// pour garantir qu'un seul gestionnaire de notifications est actif
class PusherNotificationHandler extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  const PusherNotificationHandler({
    super.key,
    required this.child,
    this.navigatorKey,
  });

  @override
  State<PusherNotificationHandler> createState() =>
      _PusherNotificationHandlerState();
}

class _PusherNotificationHandlerState extends State<PusherNotificationHandler> {
  NotificationService? _notificationService;
  final NotificationFeedbackService _feedbackService =
      NotificationFeedbackService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérer le service une seule fois quand le contexte est disponible
    if (_notificationService == null) {
      _notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      // Enregistrer le gestionnaire UNE SEULE FOIS
      _registerPusherHandler();
    }
  }

  void _registerPusherHandler() {
    print(
      '🔧 [PusherNotificationHandler] Enregistrement du gestionnaire unique...',
    );
    PusherService().registerNotificationHandler((
      notification,
      snackBarMessage,
    ) async {
      print(
        '📬 [PusherNotificationHandler] Réception d\'une notification: ${notification.title}',
      );

      // Jouer le son de notification
      await _feedbackService.playNotificationSound();

      // Ajouter la notification au service
      if (_notificationService != null) {
        await _notificationService!.addNotification(notification);
        print('✅ [PusherNotificationHandler] Notification ajoutée au service');
      }

      // Afficher le SnackBar en utilisant le contexte du Navigator
      // MaterialApp fournit automatiquement un ScaffoldMessenger
      final navigatorContext = widget.navigatorKey?.currentContext;
      if (navigatorContext != null && snackBarMessage != null) {
        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(
            content: Text(snackBarMessage),
            duration: const Duration(seconds: 5),
          ),
        );
        print('✅ [PusherNotificationHandler] SnackBar affiché');
      } else {
        print(
          '⚠️ [PusherNotificationHandler] Contexte non disponible pour SnackBar',
        );
      }
    });
    print('✅ [PusherNotificationHandler] Gestionnaire enregistré avec succès');
  }

  @override
  Widget build(BuildContext context) {
    // Retourner simplement l'enfant - MaterialApp fournit déjà le ScaffoldMessenger
    return widget.child;
  }
}
