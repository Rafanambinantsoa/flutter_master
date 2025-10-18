import 'package:flutter/material.dart';
import '../data/mock_repository.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/table.dart';

class CartModel extends ChangeNotifier {
  final MockRepository repo;
  final String tableId;
  late final String orderId;

  CartModel({required this.repo, required this.tableId}) {
    orderId = repo.createOrder(tableId).id;
  }

  void add(MenuItemModel item) {
    repo.addItem(orderId, item);
    notifyListeners();
  }

  void inc(MenuItemModel item) {
    final order = repo.orders.firstWhere((o) => o.id == orderId);
    final line = order.lines.firstWhere(
      (l) => l.item.id == item.id,
      orElse: () => OrderLine(item: item),
    );
    if (!order.lines.contains(line)) order.lines.add(line);
    repo.updateQuantity(orderId, item, line.quantity + 1);
    notifyListeners();
  }

  void dec(MenuItemModel item) {
    final order = repo.orders.firstWhere((o) => o.id == orderId);
    final line = order.lines.firstWhere(
      (l) => l.item.id == item.id,
      orElse: () => OrderLine(item: item, quantity: 1),
    );
    if (!order.lines.contains(line)) return;
    final next = line.quantity - 1;
    if (next <= 0) {
      repo.removeItem(orderId, item);
    } else {
      repo.updateQuantity(orderId, item, next);
    }
    notifyListeners();
  }

  OrderModel get order => repo.orders.firstWhere((o) => o.id == orderId);
  double get total => order.total;
  int get itemCount => order.lines.fold<int>(0, (sum, l) => sum + l.quantity);
}

class OrderScreen extends StatefulWidget {
  final MockRepository repo;
  final DiningTable table;
  const OrderScreen({super.key, required this.repo, required this.table});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  MenuCategory? _categoryFilter;
  MenuTemperature? _tempFilter;
  late CartModel _cart;

  @override
  void initState() {
    super.initState();
    _cart = CartModel(repo: widget.repo, tableId: widget.table.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commande - Table ${widget.table.number}'),
        actions: [
          AnimatedBuilder(
            animation: _cart,
            builder: (context, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CartScreen(repo: widget.repo, cart: _cart),
                      ),
                    );
                          setState(() {});
                        },
                ),
                if (_cart.itemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _Filters(
            category: _categoryFilter,
            temperature: _tempFilter,
            onCategory: (c) => setState(() => _categoryFilter = c),
            onTemperature: (t) => setState(() => _tempFilter = t),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 700 ? 2 : 3;
                final childAspect = crossAxisCount == 2 ? 0.7 : 0.65;
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspect,
                  ),
                  itemCount: widget.repo.menu
                      .where(
                        (m) =>
                            _categoryFilter == null ||
                            m.category == _categoryFilter,
                      )
                      .where(
                        (m) =>
                            _tempFilter == null || m.temperature == _tempFilter,
                      )
                      .length,
                  itemBuilder: (context, index) {
                    final items = widget.repo.menu
                        .where(
                          (m) =>
                              _categoryFilter == null ||
                              m.category == _categoryFilter,
                        )
                        .where(
                          (m) =>
                              _tempFilter == null ||
                              m.temperature == _tempFilter,
                        )
                        .toList();
                    final item = items[index];
                    return _MenuCard(item: item, cart: _cart);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final MenuCategory? category;
  final MenuTemperature? temperature;
  final ValueChanged<MenuCategory?> onCategory;
  final ValueChanged<MenuTemperature?> onTemperature;

  const _Filters({
    required this.category,
    required this.temperature,
    required this.onCategory,
    required this.onTemperature,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children:
            [
                  FilterChip(
                    label: const Text('Tous'),
                    selected: category == null && temperature == null,
                    onSelected: (_) {
                      onCategory(null);
                      onTemperature(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    'Plats',
                    category == MenuCategory.dish,
                    () => onCategory(MenuCategory.dish),
                  ),
                  _chip(
                    'Boissons',
                    category == MenuCategory.drink,
                    () => onCategory(MenuCategory.drink),
                  ),
                  _chip(
                    'Desserts',
                    category == MenuCategory.dessert,
                    () => onCategory(MenuCategory.dessert),
                  ),
                  const SizedBox(width: 12),
                  _chip(
                    'Chaud',
                    temperature == MenuTemperature.hot,
                    () => onTemperature(MenuTemperature.hot),
                  ),
                  _chip(
                    'Froid',
                    temperature == MenuTemperature.cold,
                    () => onTemperature(MenuTemperature.cold),
                  ),
                ]
                .map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: w,
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItemModel item;
  final CartModel cart;
  const _MenuCard({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 240;
        return Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              cart.add(item);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} ajouté au panier'),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: isCompact ? 16 / 9 : 16 / 10,
                  child: item.imageUrl != null
                      ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                      : Container(color: cs.surfaceVariant),
                ),
                Padding(
                  padding: EdgeInsets.all(isCompact ? 8 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isCompact ? 2 : 6),
                      Text(
                        item.description ?? 'Délicieux et préparé à la minute.',
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      SizedBox(height: isCompact ? 6 : 10),
                      Wrap(
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _tag(item.category.name),
                          _tag(
                            item.temperature == MenuTemperature.hot
                                ? 'chaud'
                                : 'froid',
                          ),
                          SizedBox(
                            width: isCompact ? double.infinity : null,
                            child: FilledButton(
                              onPressed: () {
                                cart.add(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${item.name} ajouté au panier',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.only(
                                      bottom: 24,
                                      left: 24,
                                      right: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Text('Ajouter'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label),
    );
  }
}

class CartScreen extends StatelessWidget {
  final MockRepository repo;
  final CartModel cart;
  const CartScreen({super.key, required this.repo, required this.cart});

  @override
  Widget build(BuildContext context) {
    final tableNumber = repo.tables
        .firstWhere((t) => t.id == cart.tableId)
        .number;
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        final order = cart.order;
        return Scaffold(
          appBar: AppBar(title: Text('Panier - Table $tableNumber')),
          body: Column(
            children: [
                Expanded(
                child: order.lines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 56,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Votre panier est vide',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                    padding: const EdgeInsets.all(12),
                        itemCount: order.lines.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final line = order.lines[index];
                          return Card(
                            child: ListTile(
                              title: Text(line.item.name),
                              subtitle: Text(
                                '${line.item.price.toStringAsFixed(2)} €',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => cart.dec(line.item),
                                  ),
                                  Text('${line.quantity}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => cart.inc(line.item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                      'Total: ${cart.total.toStringAsFixed(2)} €',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                        FilledButton(
                      onPressed: () => repo.submitToKitchen(cart.orderId),
                      child: const Text('Valider la commande'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        );
      },
    );
  }
}
