import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../models/table.dart';
import '../services/mock_api_service.dart';
import '../components/table_tile_card.dart';
import '../components/custom_drawer.dart';

class AvailableTablesScreen extends StatefulWidget {
  final Reservation reservation;
  final List<DiningTable> availableTables;
  final DiningTable? selectedTable;
  final MockApiService apiService;

  const AvailableTablesScreen({
    super.key,
    required this.reservation,
    required this.availableTables,
    this.selectedTable,
    required this.apiService,
  });

  @override
  State<AvailableTablesScreen> createState() => _AvailableTablesScreenState();
}

class _AvailableTablesScreenState extends State<AvailableTablesScreen> {
  DiningTable? _selectedTable;

  @override
  void initState() {
    super.initState();
    _selectedTable = widget.selectedTable;
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
        title: const Text('Tables disponibles'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sélectionnez une table',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.availableTables.length} table(s) disponible(s) pour cette plage horaire',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Plage horaire: ${widget.reservation.heureDebut.hour}h${widget.reservation.heureDebut.minute.toString().padLeft(2, '0')} - ${widget.reservation.heureFin.hour}h${widget.reservation.heureFin.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: widget.availableTables.map((table) {
                final isSelected = _selectedTable?.id == table.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTable = table;
                    });
                  },
                  child: Stack(
                    children: [
                      TableTileCard(
                        table: table,
                        isAvailable: true,
                        onTap: () {
                          setState(() {
                            _selectedTable = table;
                          });
                        },
                      ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          if (_selectedTable != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(_selectedTable);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Sélectionner Table ${_selectedTable!.number}',
                        style: const TextStyle(
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
  }
}
