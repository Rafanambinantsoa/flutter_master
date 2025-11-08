import 'package:flutter/material.dart';
import '../services/session_service.dart';

/// Widget qui vérifie la session utilisateur au démarrage
class SessionChecker extends StatefulWidget {
  final Widget child;

  const SessionChecker({super.key, required this.child});

  @override
  State<SessionChecker> createState() => _SessionCheckerState();
}

class _SessionCheckerState extends State<SessionChecker> {
  final SessionService _sessionService = SessionService();
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
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

