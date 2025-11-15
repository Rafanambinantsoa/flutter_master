import 'package:flutter/material.dart';
import '../data/mock_repository.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/table.dart';
import '../models/reservation.dart';
import '../models/client_info.dart';
import '../services/menu_service.dart';
import '../services/commande_service.dart';
import '../models/commande.dart';

class CartModel extends ChangeNotifier {
  final MockRepository repo;
  final String tableId;
  late final String orderId;
  final List<OrderLine>? prepaidItems;

  CartModel({required this.repo, required this.tableId, this.prepaidItems}) {
    final order = repo.createOrder(tableId);
    orderId = order.id;

    // Si des items prépayés sont fournis, les ajouter à la commande
    if (prepaidItems != null) {
      for (final line in prepaidItems!) {
        for (int i = 0; i < line.quantity; i++) {
          repo.addItem(orderId, line.item);
        }
      }
    }
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
  final Reservation? reservation; // Réservation optionnelle (pour menu prépayé)
  final ClientInfo?
  clientInfo; // Informations client (pour clients sans réservation)

  const OrderScreen({
    super.key,
    required this.repo,
    required this.table,
    this.reservation,
    this.clientInfo,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  MenuCategory? _categoryFilter;
  MenuTemperature? _tempFilter;
  late CartModel _cart;
  final MenuService _menuService = MenuService();
  List<MenuItemModel> _menuItems = const [];
  bool _isLoadingMenu = false;
  String? _menuError;

  @override
  void initState() {
    super.initState();
    _cart = CartModel(
      repo: widget.repo,
      tableId: widget.table.id,
      prepaidItems: widget.reservation?.prepaidMenuItems,
    );
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoadingMenu = true;
      _menuError = null;
    });
    try {
      final items = await _menuService.getMenus();
      if (!mounted) return;
      setState(() {
        _menuItems = items;
        _isLoadingMenu = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _menuError = e.toString();
        _isLoadingMenu = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrepaid = widget.reservation?.type == ReservationType.prepaidMenu;
    final hasClientInfo = widget.clientInfo != null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Commande - Table ${widget.table.number}'),
            if (isPrepaid)
              Text(
                'Menu prépayé',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            if (hasClientInfo && !isPrepaid)
              Text(
                widget.clientInfo!.nom,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
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
                        builder: (_) => CartScreen(
                          repo: widget.repo,
                          cart: _cart,
                          table: widget.table,
                          reservation: widget.reservation,
                          clientInfo: widget.clientInfo,
                        ),
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
          if (isPrepaid)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menu prépayé',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Vous pouvez ajouter des extras si nécessaire',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (hasClientInfo && !isPrepaid)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.clientInfo!.nom,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        if (widget.clientInfo!.telephone != null)
                          Text(
                            widget.clientInfo!.telephone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer
                                  .withOpacity(0.7),
                            ),
                          ),
                        Text(
                          widget.clientInfo!.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                if (_isLoadingMenu) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_menuError != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Erreur lors du chargement du menu',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _menuError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _loadMenu,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final filtered = _menuItems
                    .where(
                      (m) =>
                          _categoryFilter == null ||
                          m.category == _categoryFilter,
                    )
                    .where(
                      (m) =>
                          _tempFilter == null || m.temperature == _tempFilter,
                    )
                    .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.restaurant_outlined,
                          size: 56,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        const Text('Aucun élément de menu'),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _loadMenu,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Recharger'),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspect,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${item.price.toStringAsFixed(0)} Ar',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: isCompact ? 14 : 16,
                            ),
                          ),
                        ],
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

class CartScreen extends StatefulWidget {
  final MockRepository repo;
  final CartModel cart;
  final DiningTable table;
  final Reservation? reservation;
  final ClientInfo? clientInfo;

  const CartScreen({
    super.key,
    required this.repo,
    required this.cart,
    required this.table,
    this.reservation,
    this.clientInfo,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CommandeService _commandeService = CommandeService();
  bool _isSubmitting = false;

  DateTime _roundToNextHalfHour(DateTime dateTime) {
    final minutes = dateTime.minute;

    if (minutes == 0 || minutes == 30) {
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        minutes,
      );
    } else if (minutes < 30) {
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        30,
      );
    } else {
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour + 1,
        0,
      );
    }
  }

  Future<void> _submitCommande() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final order = widget.cart.order;

      // Extraire les IDs des menus et les quantités
      final menuIds = <int>[];
      final quantities = <int>[];

      for (final line in order.lines) {
        final menuId = int.tryParse(line.item.id);
        if (menuId != null) {
          menuIds.add(menuId);
          quantities.add(line.quantity);
        }
      }

      if (menuIds.isEmpty) {
        throw Exception('Aucun menu dans la commande');
      }

      // Extraire l'ID de la table (supprimer le préfixe 't' si présent)
      final tableIdStr = widget.table.id.replaceAll('t', '');
      final tableId = int.tryParse(tableIdStr) ?? widget.table.number;
      final tablesIds = [tableId];

      // Gérer la date et l'heure pour la réservation
      final now = DateTime.now();
      final startTime = _roundToNextHalfHour(now);
      final endTime = startTime.add(const Duration(hours: 2, minutes: 30));
      final dateCommande = startTime;

      final dateReservation =
          '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';
      final heureDebut =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final heureFin =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      // Gérer les informations client
      String nom;
      String email;
      String? telephone;
      String? adresse;

      if (widget.reservation != null) {
        // Utiliser les données de la réservation
        nom = widget.reservation!.clientName ?? 'Client';
        email =
            'client@example.com'; // L'API de réservation n'a peut-être pas d'email
        telephone = widget.reservation!.clientPhone;
        adresse = null;
      } else if (widget.clientInfo != null) {
        // Utiliser les données du client info
        nom = widget.clientInfo!.nom;
        email = widget.clientInfo!.email;
        telephone = widget.clientInfo!.telephone;
        adresse = widget.clientInfo!.adresse;
      } else {
        throw Exception('Informations client manquantes');
      }

      // Récupérer le reservation_id (0 ou null si pas de réservation existante)
      final reservationId = widget.reservation != null
          ? int.tryParse(widget.reservation!.id) ?? 0
          : 0;

      // Créer la requête
      final request = CreateCommandeRequest(
        reservationId: reservationId,
        dateCommande: dateCommande,
        nom: nom,
        email: email,
        telephone: telephone,
        adresse: adresse,
        dateReservation: dateReservation,
        heureDebut: heureDebut,
        heureFin: heureFin,
        tablesIds: tablesIds,
        menuIds: menuIds,
        quantities: quantities,
      );

      // Appeler l'API
      final response = await _commandeService.createCommande(request);

      if (!mounted) return;

      // Succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // Soumettre au kitchen (local)
      widget.repo.submitToKitchen(widget.cart.orderId);

      // Retourner à l'accueil après un court délai
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      // Fermer tous les écrans jusqu'à l'accueil (ou naviguer vers l'accueil)
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/accueil', (route) => false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la création de la commande: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tableNumber = widget.repo.tables
        .firstWhere((t) => t.id == widget.cart.tableId)
        .number;
    return AnimatedBuilder(
      animation: widget.cart,
      builder: (context, _) {
        final order = widget.cart.order;
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
                          final lineTotal = line.total;
                          return Card(
                            child: ListTile(
                              title: Text(line.item.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${line.item.price.toStringAsFixed(0)} Ar × ${line.quantity}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    'Sous-total: ${lineTotal.toStringAsFixed(0)} Ar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => widget.cart.dec(line.item),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${line.quantity}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => widget.cart.inc(line.item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nombre d\'articles:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${widget.cart.itemCount}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${widget.cart.total.toStringAsFixed(0)} Ar',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submitCommande,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Valider la commande',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
