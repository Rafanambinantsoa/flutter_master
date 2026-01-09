import 'package:flutter_master/services/pusher_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_master/services/notification_service.dart';
import 'package:flutter_master/notifiers/commande_notifier.dart';
import 'package:flutter_master/widgets/pusher_notification_handler.dart';
import 'data/mock_repository.dart';
import 'services/mock_api_service.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Pusher AVANT de lancer l'application
  print('🚀 [main] Initialisation de Pusher...');
  await PusherService().initPusher();
  print('✅ [main] Pusher initialisé');

  runApp(const RestaurantServerApp());
}

class RestaurantServerApp extends StatefulWidget {
  const RestaurantServerApp({super.key});

  @override
  State<RestaurantServerApp> createState() => _RestaurantServerAppState();
}

class _RestaurantServerAppState extends State<RestaurantServerApp> {
  // Créer la clé du Navigator une seule fois pour la partager
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF262626),
      onPrimary: Color(0xFFFBFBFB),
      secondary: Color(0xFFF7F7F7),
      onSecondary: Color(0xFF262626),
      error: Color(0xFFE24A34),
      onError: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF252525),
    );

    final repo = MockRepository();
    final apiService = MockApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        ChangeNotifierProvider<CommandeNotifier>(
          create: (context) => CommandeNotifier(),
        ),
      ],
      child: PusherNotificationHandler(
        navigatorKey: _navigatorKey,
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Serveur',
          theme: ThemeData(
            colorScheme: colorScheme,
            useMaterial3: true,
            scaffoldBackgroundColor: colorScheme.surface,
            appBarTheme: AppBarTheme(
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
              centerTitle: true,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              bodyLarge: TextStyle(fontSize: 16),
              bodyMedium: TextStyle(fontSize: 14),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(color: colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          initialRoute: '/splash',
          onGenerateRoute: (settings) => appRouter(settings, repo, apiService),
          // Redirection vers la sélection de client après login
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: Text('Route inconnue: ${settings.name}')),
              ),
            );
          },
        ),
      ),
    );
  }
}
