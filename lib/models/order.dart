import 'menu_item.dart';

enum OrderStatus { pending, preparing, ready, served }

class OrderLine {
  final MenuItemModel item;
  int quantity;

  OrderLine({required this.item, this.quantity = 1});

  double get total => item.price * quantity;
}

class OrderModel {
  final String id;
  final String tableId;
  final DateTime createdAt;
  OrderStatus status;
  final List<OrderLine> lines;

  OrderModel({
    required this.id,
    required this.tableId,
    required this.createdAt,
    this.status = OrderStatus.pending,
    List<OrderLine>? lines,
  }) : lines = lines ?? [];

  double get total => lines.fold<double>(
    0,
    (sum, line) => sum + (line.item.price * line.quantity),
  );
}
