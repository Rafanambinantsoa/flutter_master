import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/mock_repository.dart';
import 'services/mock_api_service.dart';
import 'services/notification_service.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => NotificationService(),
      child: const RestaurantServerApp(),
    ),
  );
}

class RestaurantServerApp extends StatelessWidget {
  const RestaurantServerApp({super.key});

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

    return MaterialApp(
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
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
    );
  }
}
