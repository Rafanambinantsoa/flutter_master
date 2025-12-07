import 'package:flutter/material.dart';
import '../services/session_service.dart';

/// Écran de démarrage qui vérifie la session
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Attendre un peu pour l'animation
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Vérifier si l'utilisateur est connecté
    final isLoggedIn = await _sessionService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // Utilisateur connecté - aller au dashboard
      Navigator.of(context).pushReplacementNamed('/accueil');
    } else {
      // Pas de session - aller au login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Restaurant OS',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
