import 'package:flutter/material.dart';
import '../data/mock_repository.dart';
import '../models/table.dart';
import '../services/mock_api_service.dart';
import '../components/suggested_table_card.dart';
import '../components/table_tile_card.dart';
import '../components/custom_drawer.dart';

class AccueilScreen extends StatefulWidget {
  final MockRepository repo;
  final MockApiService? apiService;

  const AccueilScreen({super.key, required this.repo, this.apiService});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  final TextEditingController _peopleCtrl = TextEditingController(text: '2');
  int _people = 2;
  DiningTable? _suggested;
  bool _isLoading = false;
  List<DiningTable> _availableTables = [];
  int _notificationCount = 3;

  late final MockApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? MockApiService();
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
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final heureDebut = DateTime(today.year, today.month, today.day, now.hour);
      final heureFin = heureDebut.add(const Duration(hours: 2));

      final tables = await _apiService.findTablesDisponibles(
        date: today,
        heureDebut: heureDebut,
        heureFin: heureFin,
      );

      if (!mounted) return;

      setState(() {
        _availableTables = tables;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des tables: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
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
      drawer: const CustomDrawer(serverName: 'John Doe'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Accueil'),
        centerTitle: true,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/notifications'),
                tooltip: 'Notifications',
              ),
              if (_notificationCount > 0)
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
                      '$_notificationCount',
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
                    Navigator.of(
                      context,
                    ).pushReplacementNamed('/client-selection');
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
                  Navigator.of(
                    context,
                  ).pushNamed('/order', arguments: _suggested);
                },
              ),
            if (_suggested != null) const SizedBox(height: 16),
            // Liste des tables disponibles
            Text(
              'Toutes les tables',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                      children: _apiService.getAllTables().map((t) {
                        final isAvailable = _availableTables.any(
                          (available) => available.id == t.id,
                        );
                        return TableTileCard(
                          table: t,
                          isAvailable: isAvailable,
                          onTap: isAvailable
                              ? () => Navigator.of(
                                  context,
                                ).pushNamed('/order', arguments: t)
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Cette table n\'est pas disponible',
                                      ),
                                    ),
                                  );
                                },
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
