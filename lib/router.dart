import 'package:flutter/material.dart';
import 'data/mock_repository.dart';
import 'models/table.dart';
import 'models/reservation.dart';
import 'models/reservation_detail.dart';
import 'services/mock_api_service.dart';
import 'widgets/session_checker.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/tables_screen.dart';
import 'screens/order_screen.dart';
import 'screens/commandes_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/client_selection_screen.dart';
import 'screens/reservation_lookup_screen.dart';
import 'screens/reservation_detail_screen.dart';
import 'screens/reservation_detail_prepaid_screen.dart';
import 'screens/available_tables_screen.dart';
import 'screens/client_info_screen.dart';
import 'models/client_info.dart';

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
        builder: (_) => _ProtectedRoute(child: const DashboardScreen()),
      );
    case '/tables':
      return MaterialPageRoute(
        builder: (_) => _ProtectedRoute(child: TablesScreen(repo: repo)),
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
            clientType: args['type'] as ClientType?,
          ),
        ),
      );
    case '/reservation-detail':
      final args = (settings.arguments as Map<String, dynamic>?) ?? {};
      final reservation = args['reservation'];

      // Si c'est une ReservationDetail (nouveau format), utiliser le nouvel écran
      if (reservation is ReservationDetail) {
        return MaterialPageRoute(
          builder: (_) => _ProtectedRoute(
            child: ReservationDetailPrepaidScreen(reservation: reservation),
          ),
        );
      }

      // Sinon, utiliser l'ancien écran pour compatibilité
      if (reservation is Reservation) {
        return MaterialPageRoute(
          builder: (_) => _ProtectedRoute(
            child: ReservationDetailScreen(
              reservation: reservation,
              apiService: apiService,
            ),
          ),
        );
      }

      // Erreur si le type n'est pas reconnu
      return MaterialPageRoute(
        builder: (_) =>
            Scaffold(body: Center(child: Text('Type de réservation invalide'))),
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
    case '/client-info':
      final args = (settings.arguments as Map<String, dynamic>?) ?? {};
      return MaterialPageRoute(
        builder: (_) => _ProtectedRoute(
          child: ClientInfoScreen(table: args['table'] as DiningTable),
        ),
      );
    case '/order':
      final args = settings.arguments;
      DiningTable table;
      Reservation? reservation;
      ClientInfo? clientInfo;

      if (args is DiningTable) {
        // Ancien format pour compatibilité
        table = args;
        reservation = null;
        clientInfo = null;
      } else if (args is Map<String, dynamic>) {
        // Nouveau format avec réservation et infos client optionnelles
        table = args['table'] as DiningTable;
        reservation = args['reservation'] as Reservation?;
        clientInfo = args['clientInfo'] as ClientInfo?;
      } else {
        throw ArgumentError('Invalid arguments for /order route');
      }

      return MaterialPageRoute(
        builder: (_) => _ProtectedRoute(
          child: OrderScreen(
            repo: repo,
            table: table,
            reservation: reservation,
            clientInfo: clientInfo,
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
        final args = (settings.arguments as Map<String, dynamic>?) ?? {};
        // Si commandeId est fourni, l'utiliser, sinon utiliser id
        final commandeId = args['commandeId'] as String? ?? id;
        return MaterialPageRoute(
          builder: (_) =>
              _ProtectedRoute(child: OrderDetailScreen(commandeId: commandeId)),
        );
      }
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('Unknown route ${settings.name}')),
        ),
      );
  }
}
