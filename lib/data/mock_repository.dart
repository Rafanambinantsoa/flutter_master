import 'package:flutter/material.dart';
import '../models/table.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

class MockRepository extends ChangeNotifier {
  final List<DiningTable> tables = List.generate(
    12,
    (i) => DiningTable(id: 't$i', number: i + 1, capacity: i % 4 == 0 ? 6 : 4),
  );

  final List<MenuItemModel> menu = const [
    MenuItemModel(
      id: 'm1',
      name: 'Burger Classique',
      category: MenuCategory.dish,
      price: 9.5,
      temperature: MenuTemperature.hot,
      description: 'Steak, fromage, salade et sauce spéciale.',
      imageUrl: 'https://picsum.photos/seed/burger/400/300',
    ),
    MenuItemModel(
      id: 'm2',
      name: 'Pâtes Alfredo',
      category: MenuCategory.dish,
      price: 11.0,
      temperature: MenuTemperature.hot,
      description: 'Sauce crémeuse parmesan et poulet.',
      imageUrl: 'https://picsum.photos/seed/pasta/400/300',
    ),
    MenuItemModel(
      id: 'm3',
      name: 'Cola',
      category: MenuCategory.drink,
      price: 3.0,
      temperature: MenuTemperature.cold,
      description: 'Boisson gazeuse rafraîchissante.',
      imageUrl: 'https://picsum.photos/seed/cola/400/300',
    ),
    MenuItemModel(
      id: 'm4',
      name: 'Tiramisu',
      category: MenuCategory.dessert,
      price: 5.5,
      temperature: MenuTemperature.cold,
      description: 'Dessert italien au café et mascarpone.',
      imageUrl: 'https://picsum.photos/seed/tiramisu/400/300',
    ),
  ];

  final Map<String, OrderModel> _orders = {};

  DiningTable? findFreeTable({int people = 2}) {
    return tables.firstWhere(
      (t) => !t.isOccupied && t.capacity >= people,
      orElse: () =>
          tables.firstWhere((t) => !t.isOccupied, orElse: () => tables.first),
    );
  }

  OrderModel createOrder(String tableId) {
    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableId: tableId,
      createdAt: DateTime.now(),
    );
    _orders[order.id] = order;
    tables.firstWhere((t) => t.id == tableId).isOccupied = true;
    notifyListeners();
    return order;
  }

  void addItem(String orderId, MenuItemModel item) {
    final order = _orders[orderId]!;
    final existing = order.lines.where((l) => l.item.id == item.id).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity += 1;
    } else {
      order.lines.add(OrderLine(item: item));
    }
    notifyListeners();
  }

  void removeItem(String orderId, MenuItemModel item) {
    final order = _orders[orderId]!;
    order.lines.removeWhere((l) => l.item.id == item.id);
    notifyListeners();
  }

  void updateQuantity(String orderId, MenuItemModel item, int quantity) {
    final order = _orders[orderId]!;
    final line = order.lines.firstWhere((l) => l.item.id == item.id);
    line.quantity = quantity.clamp(1, 99);
    notifyListeners();
  }

  void submitToKitchen(String orderId) {
    final order = _orders[orderId]!;
    order.status = OrderStatus.preparing;
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      order.status = OrderStatus.ready;
      notifyListeners();
    });
  }

  void markServed(String orderId) {
    final order = _orders[orderId]!;
    order.status = OrderStatus.served;
    notifyListeners();
  }

  List<OrderModel> get orders =>
      _orders.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
