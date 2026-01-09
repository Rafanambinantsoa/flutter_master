import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Added
import '../services/session_service.dart';
import '../services/pusher_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_master/services/notification_service.dart'; // Added
import 'package:flutter_master/models/app_notification.dart'; // Added
import 'package:uuid/uuid.dart'; // Added for unique IDs

/// Widget qui vérifie la session utilisateur au démarrage
class SessionChecker extends StatefulWidget {
  final Widget child;

  const SessionChecker({super.key, required this.child});

  @override
  State<SessionChecker> createState() => _SessionCheckerState();
}

class _SessionCheckerState extends State<SessionChecker> {
  final SessionService _sessionService = SessionService();
  final PusherService _pusherService = PusherService();
  // final NotificationService _notificationService; // Removed
  StreamSubscription? _pusherSubscription;
  final Uuid _uuid = const Uuid(); // Added
  bool _isChecking = true;

  late final NotificationService _notificationService;

  @override
  void initState() {
    print('DEBUG SessionChecker: initState called.'); // Debug print
    super.initState();
    _notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    ); // Get from Provider
    // _pusherService.subscribe('commandes'); // Removed
    _checkSession();
    _listenToPusherEvents();
  }

  void _listenToPusherEvents() {
    _pusherSubscription = _pusherService.events.listen((event) async {
      // Changed to async
      if (mounted) {
        String snackBarMessage = 'Événement Pusher reçu: ${event.eventName}';
        String notificationTitle = 'Nouvel événement Pusher';
        String notificationBody = '${event.eventName} sur ${event.channelName}';

        if (event.data != null && event.data!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = json.decode(event.data!);
            if (event.eventName == 'commande-terminer') {
              notificationTitle = 'Commande terminée';
              notificationBody = data['message'] ?? notificationBody;
              snackBarMessage = data['message'] ?? snackBarMessage;
            }
          } catch (e) {
            print('Erreur de décodage JSON: $e');
            snackBarMessage =
                'Événement Pusher reçu: ${event.eventName} sur ${event.channelName} avec données non parsables.';
            notificationBody = snackBarMessage;
          }
        }

        // Créer et ajouter la notification
        final newNotification = AppNotification(
          id: _uuid.v4(),
          title: notificationTitle,
          body: notificationBody,
          timestamp: DateTime.now(),
          expiryTime: DateTime.now().add(
            const Duration(hours: 2),
          ), // Expiration après 2 heures
        );
        print(
          'DEBUG: Creating new notification: $newNotification',
        ); // Debug print
        await _notificationService.addNotification(newNotification);
        print('DEBUG: Notification added to service.'); // Debug print

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackBarMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    print('DEBUG SessionChecker: dispose called.'); // Debug print
    _pusherSubscription?.cancel();
    // _pusherService.unsubscribe('commandes'); // Removed
    super.dispose();
  }

  Future<void> _checkSession() async {
    // Vérifier si l'utilisateur est connecté
    final isLoggedIn = await _sessionService.isLoggedIn();

    if (!mounted) return;

    if (!isLoggedIn) {
      // Token expiré ou pas de session - rediriger vers login
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      // Session valide
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Afficher un loader pendant la vérification
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return widget.child;
  }
}
