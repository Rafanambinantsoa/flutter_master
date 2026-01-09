import 'package:flutter/material.dart';
import '../data/mock_repository.dart';
import '../models/table.dart';
import '../services/tables_service.dart';
import '../components/suggested_table_card.dart';
import '../components/table_tile_card.dart';
import '../widgets/session_drawer.dart';
import '../components/notification_badge_icon.dart'; // Added

class TablesScreen extends StatefulWidget {
  final MockRepository repo;

  const TablesScreen({super.key, required this.repo});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  final TextEditingController _peopleCtrl = TextEditingController(text: '2');
  int _people = 2;
  DiningTable? _suggested;
  bool _isLoading = false;
  List<DiningTable> _availableTables = [];
  String? _plageHoraire; // Pour afficher la plage horaire utilisée

  final TablesService _tablesService = TablesService();

  @override
  void initState() {
    super.initState();
    _loadAvailableTables();
  }

  @override
  void dispose() {
    _peopleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTables() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Utiliser le service API pour récupérer les tables disponibles
      // Le service gère automatiquement l'arrondi aux tranches de 30 minutes
      // et calcule l'heure de fin (heure actuelle + 2h30)
      final response = await _tablesService.getTablesDisponibles();

      if (!mounted) return;

      // Convertir les tables disponibles en DiningTable
      final tables = response.disponibles
          .map((table) => _tablesService.convertToDiningTable(table))
          .toList();

      // Sauvegarder la plage horaire pour l'affichage
      final plageHoraire = '${response.heureDebut} - ${response.heureFin}';

      setState(() {
        _availableTables = tables;
        _plageHoraire = plageHoraire;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Erreur lors du chargement des tables';
      if (e is TablesServiceException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Erreur: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _suggestTable() {
    if (_availableTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune table disponible pour cette plage horaire'),
        ),
      );
      return;
    }

    // Trouver une table avec la capacité suffisante
    final suitable = _availableTables
        .where((t) => t.capacity >= _people)
        .toList();
    if (suitable.isNotEmpty) {
      setState(() {
        _suggested = suitable.first;
      });
    } else {
      // Si aucune table n'a la capacité exacte, prendre la plus grande disponible
      setState(() {
        _suggested = _availableTables.reduce(
          (a, b) => a.capacity > b.capacity ? a : b,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SessionDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Tables disponibles'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAvailableTables,
            tooltip: 'Actualiser',
          ),
          NotificationBadgeIcon(), // Use the new widget here
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tables disponibles',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/client-selection');
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Nouveau client'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Section pour suggérer une table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client sans réservation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Personnes:'),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _peopleCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed != null && parsed > 0) {
                                setState(() => _people = parsed);
                              }
                            },
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _isLoading ? null : _suggestTable,
                          child: const Text('Proposer table'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_suggested != null)
              SuggestedTableCard(
                table: _suggested!,
                isAvailable: _availableTables.any(
                  (t) => t.id == _suggested!.id,
                ),
                onSelect: () {
                  Navigator.of(context).pushNamed(
                    '/client-info',
                    arguments: {'table': _suggested!},
                  );
                },
              ),
            if (_suggested != null) const SizedBox(height: 16),
            // Liste des tables disponibles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Toutes les tables',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_plageHoraire != null)
                  Text(
                    _plageHoraire!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _availableTables.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_restaurant_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune table disponible',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toutes les tables sont réservées ou occupées',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: _availableTables.map((t) {
                        return TableTileCard(
                          table: t,
                          isAvailable:
                              true, // Toutes les tables affichées sont disponibles
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed('/client-info', arguments: {'table': t}),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
