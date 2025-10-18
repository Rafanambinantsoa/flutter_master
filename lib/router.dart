import 'package:flutter/material.dart';
import 'data/mock_repository.dart';
import 'models/table.dart';
import 'screens/login_screen.dart';
import 'screens/accueil_screen.dart';
import 'screens/order_screen.dart';
import 'screens/commandes_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/order_detail_screen.dart';

Route<dynamic> appRouter(RouteSettings settings, MockRepository repo) {
  switch (settings.name) {
    case '/login':
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case '/':
      return MaterialPageRoute(builder: (_) => AccueilScreen(repo: repo));
    case '/order':
      final table = settings.arguments as DiningTable;
      return MaterialPageRoute(
        builder: (_) => OrderScreen(repo: repo, table: table),
      );
    case '/orders':
      return MaterialPageRoute(builder: (_) => const CommandesScreen());
    case '/notifications':
      return MaterialPageRoute(builder: (_) => const NotificationsScreen());
    default:
      // dynamic order details: /orders/{id}
      if (settings.name != null && settings.name!.startsWith('/orders/')) {
        final id = settings.name!.substring('/orders/'.length);
        final args = (settings.arguments as Map?) ?? {};
        return MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            id: id,
            createdAt: args['createdAt'] as DateTime?,
            status: args['status'],
            total: (args['total'] as num?)?.toDouble(),
            lines: (args['lines'] as List?)?.cast<Map<String, dynamic>>(),
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
