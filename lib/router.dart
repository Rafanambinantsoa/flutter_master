import 'package:flutter/material.dart';
import 'data/mock_repository.dart';
import 'models/table.dart';
import 'models/reservation.dart';
import 'services/mock_api_service.dart';
import 'widgets/session_checker.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/accueil_screen.dart';
import 'screens/order_screen.dart';
import 'screens/commandes_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/client_selection_screen.dart';
import 'screens/reservation_lookup_screen.dart';
import 'screens/reservation_detail_screen.dart';
import 'screens/available_tables_screen.dart';

/// Widget helper pour protéger les routes
class _ProtectedRoute extends StatelessWidget {
  final Widget child;

  const _ProtectedRoute({required this.child});

  @override
  Widget build(BuildContext context) {
    return SessionChecker(child: child);
  }
}

Route<dynamic> appRouter(
  RouteSettings settings,
  MockRepository repo,
  MockApiService apiService,
) {
  switch (settings.name) {
    case '/splash':
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    case '/login':
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case '/':
    case '/accueil':
      return MaterialPageRoute(
        builder: (_) => _ProtectedRoute(child: AccueilScreen(repo: repo)),
      );
    case '/client-selection':
      return MaterialPageRoute(
        builder: (_) => _ProtectedRoute(
          child: ClientSelectionScreen(repo: repo, apiService: apiService),
        ),
      );
    case '/reservation-lookup':
      final args = (settings.arguments as Map<String, dynamic>?) ?? {};
      return MaterialPageRoute(
        builder: (_) => _ProtectedRoute(
          child: ReservationLookupScreen(
            apiService: apiService,
            clientType: args['type'] as dynamic,
          ),
        ),
      );
    case '/reservation-detail':
      final args = (settings.arguments as Map<String, dynamic>?) ?? {};
      return MaterialPageRoute(
        builder: (_) => _ProtectedRoute(
          child: ReservationDetailScreen(
            reservation: args['reservation'] as Reservation,
            apiService: apiService,
          ),
        ),
      );
    case '/available-tables':
      final args = (settings.arguments as Map<String, dynamic>?) ?? {};
      return MaterialPageRoute(
        builder: (_) => _ProtectedRoute(
          child: AvailableTablesScreen(
            reservation: args['reservation'] as Reservation,
            availableTables: args['availableTables'] as List<DiningTable>,
            selectedTable: args['selectedTable'] as DiningTable?,
            apiService: apiService,
          ),
        ),
      );
    case '/order':
      final args = settings.arguments;
      DiningTable table;
      Reservation? reservation;

      if (args is DiningTable) {
        // Ancien format pour compatibilité
        table = args;
        reservation = null;
      } else if (args is Map<String, dynamic>) {
        // Nouveau format avec réservation optionnelle
        table = args['table'] as DiningTable;
        reservation = args['reservation'] as Reservation?;
      } else {
        throw ArgumentError('Invalid arguments for /order route');
      }

      return MaterialPageRoute(
        builder: (_) => _ProtectedRoute(
          child: OrderScreen(
            repo: repo,
            table: table,
            reservation: reservation,
          ),
        ),
      );
    case '/orders':
      return MaterialPageRoute(
        builder: (_) => _ProtectedRoute(child: const CommandesScreen()),
      );
    case '/notifications':
      return MaterialPageRoute(
        builder: (_) => _ProtectedRoute(child: const NotificationsScreen()),
      );
    default:
      // dynamic order details: /orders/{id}
      if (settings.name != null && settings.name!.startsWith('/orders/')) {
        final id = settings.name!.substring('/orders/'.length);
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => _ProtectedRoute(
            child: OrderDetailScreen(
              id: id,
              createdAt: args['createdAt'] as DateTime?,
              status: args['status'],
              total: (args['total'] as num?)?.toDouble(),
              lines: (args['lines'] as List?)?.cast<Map<String, dynamic>>(),
            ),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('Unknown route ${settings.name}')),
        ),
      );
  }
}
