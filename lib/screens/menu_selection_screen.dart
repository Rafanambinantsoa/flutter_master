import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';

/// Modèle pour une sélection de menu avec quantité
class MenuSelection {
  final MenuItemModel menu;
  int quantity;

  MenuSelection({required this.menu, this.quantity = 1});
}

class MenuSelectionScreen extends StatefulWidget {
  final String commandeId;
  final List<Map<String, dynamic>>?
  existingItems; // Articles déjà dans la commande

  const MenuSelectionScreen({
    super.key,
    required this.commandeId,
    this.existingItems,
  });

  @override
  State<MenuSelectionScreen> createState() => _MenuSelectionScreenState();
}

class _MenuSelectionScreenState extends State<MenuSelectionScreen> {
  final MenuService _menuService = MenuService();
  List<MenuItemModel> _menuItems = const [];
  bool _isLoadingMenu = false;
  String? _menuError;
  MenuCategory? _categoryFilter;
  MenuTemperature? _tempFilter;

  // Map pour stocker les sélections: menuId -> MenuSelection
  final Map<String, MenuSelection> _selections = {};

  @override
  void initState() {
    super.initState();
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

  void _toggleSelection(MenuItemModel item) {
    setState(() {
      if (_selections.containsKey(item.id)) {
        _selections.remove(item.id);
      } else {
        _selections[item.id] = MenuSelection(menu: item, quantity: 1);
      }
    });
  }

  void _updateQuantity(String menuId, int quantity) {
    if (quantity <= 0) {
      _selections.remove(menuId);
    } else {
      _selections[menuId]?.quantity = quantity;
    }
    setState(() {});
  }

  void _confirmSelection() {
    if (_selections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un menu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Retourner les sélections
    Navigator.of(context).pop(_selections.values.toList());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _menuItems
        .where((m) => _categoryFilter == null || m.category == _categoryFilter)
        .where((m) => _tempFilter == null || m.temperature == _tempFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter des menus'),
        centerTitle: true,
        actions: [
          if (_selections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selections.values.fold<int>(0, (sum, s) => sum + s.quantity)}',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          _Filters(
            category: _categoryFilter,
            temperature: _tempFilter,
            onCategory: (c) => setState(() => _categoryFilter = c),
            onTemperature: (t) => setState(() => _tempFilter = t),
          ),
          const SizedBox(height: 8),
          // Liste des menus
          Expanded(
            child: _isLoadingMenu
                ? const Center(child: CircularProgressIndicator())
                : _menuError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: cs.error),
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
                            style: TextStyle(color: cs.onSurfaceVariant),
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
                  )
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_outlined,
                          size: 56,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        const Text('Aucun élément de menu'),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      // Version compacte sur écrans très étroits pour éviter
                      // les overflows dans la carte (surtout quand isSelected=true).
                      childAspectRatio: MediaQuery.of(context).size.width < 360
                          ? 0.62
                          : 0.7,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = _selections.containsKey(item.id);
                      final selection = _selections[item.id];
                      return _MenuSelectionCard(
                        item: item,
                        isSelected: isSelected,
                        quantity: selection?.quantity ?? 1,
                        onTap: () => _toggleSelection(item),
                        onQuantityChanged: (qty) =>
                            _updateQuantity(item.id, qty),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _selections.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total sélectionné:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${_selections.values.fold<double>(0, (sum, s) => sum + (s.menu.price * s.quantity)).toStringAsFixed(0)} Ar',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _confirmSelection,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Ajouter à la commande',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
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

class _MenuSelectionCard extends StatelessWidget {
  final MenuItemModel item;
  final bool isSelected;
  final int quantity;
  final VoidCallback onTap;
  final ValueChanged<int> onQuantityChanged;

  const _MenuSelectionCard({
    required this.item,
    required this.isSelected,
    required this.quantity,
    required this.onTap,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool compact = MediaQuery.of(context).size.width < 360;

    return Card(
      elevation: isSelected ? 4 : 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? cs.primary : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  // En compact, on rend l'image un peu plus courte.
                  aspectRatio: compact ? 16 / 9 : 16 / 10,
                  child: item.imageUrl != null
                      ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                      : Container(color: cs.surfaceVariant),
                ),
                if (isSelected)
                  Positioned(
                    top: compact ? 6 : 8,
                    right: compact ? 6 : 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: cs.onPrimary,
                        size: compact ? 14 : 16,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 10 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 13 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: compact ? 3 : 4),
                  Text(
                    '${item.price.toStringAsFixed(0)} Ar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                      fontSize: compact ? 12 : 13,
                    ),
                  ),
                  if (isSelected) ...[
                    SizedBox(height: compact ? 6 : 8),
                    // On force une seule ligne pour éviter les overflows verticaux.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => onQuantityChanged(0),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.remove_circle,
                              color: cs.error,
                              size: compact ? 18 : 20,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: quantity > 1
                              ? () => onQuantityChanged(quantity - 1)
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.remove_circle_outline,
                              size: compact ? 16 : 18,
                              color: quantity > 1 ? null : Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: compact ? 20 : 24,
                          child: Text(
                            '$quantity',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: compact ? 12 : 13,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => onQuantityChanged(quantity + 1),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.add_circle_outline,
                              size: compact ? 16 : 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
