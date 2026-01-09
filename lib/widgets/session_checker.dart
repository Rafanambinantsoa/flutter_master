import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../services/pusher_service.dart';
import 'dart:async';
import 'dart:convert'; // Added for JSON decoding

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
  StreamSubscription? _pusherSubscription;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
    _listenToPusherEvents();
  }

  void _listenToPusherEvents() {
    _pusherSubscription = _pusherService.events.listen((event) {
      if (mounted) {
        String snackBarMessage = 'Événement Pusher reçu: ${event.eventName}';

        if (event.data != null && event.data!.isNotEmpty) {
          try {
            final Map<String, dynamic> data = json.decode(event.data!);
            if (event.eventName == 'commande-terminer' &&
                data.containsKey('message')) {
              snackBarMessage = data['message'];
            } else {
              snackBarMessage =
                  'Événement Pusher reçu: ${event.eventName} sur ${event.channelName} avec les données: ${event.data}';
            }
          } catch (e) {
            print('Erreur de décodage JSON: $e');
            snackBarMessage =
                'Événement Pusher reçu: ${event.eventName} sur ${event.channelName} avec données non parsables.';
          }
        }

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
    _pusherSubscription?.cancel();
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
