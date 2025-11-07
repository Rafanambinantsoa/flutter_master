import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../models/table.dart';
import '../services/mock_api_service.dart';
import '../components/suggested_table_card.dart';
import '../components/custom_drawer.dart';

class ReservationDetailScreen extends StatefulWidget {
  final Reservation reservation;
  final MockApiService apiService;

  const ReservationDetailScreen({
    super.key,
    required this.reservation,
    required this.apiService,
  });

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  bool _isLoadingTables = false;
  List<DiningTable>? _availableTables;
  DiningTable? _selectedTable;

  @override
  void initState() {
    super.initState();
    _selectedTable = widget.apiService.getAllTables().firstWhere(
      (t) => t.id == widget.reservation.tableId,
      orElse: () => widget.apiService.getAllTables().first,
    );
    _loadAvailableTables();
  }

  Future<void> _loadAvailableTables() async {
    setState(() {
      _isLoadingTables = true;
    });

    try {
      final tables = await widget.apiService.findTablesDisponibles(
        date: widget.reservation.date,
        heureDebut: widget.reservation.heureDebut,
        heureFin: widget.reservation.heureFin,
      );

      if (!mounted) return;

      setState(() {
        _availableTables = tables;

        // Si la table réservée est disponible, la sélectionner par défaut
        if (widget.reservation.tableId != null) {
          final reservedTable = tables.firstWhere(
            (t) => t.id == widget.reservation.tableId,
            orElse: () => tables.isNotEmpty
                ? tables.first
                : widget.apiService.getAllTables().first,
          );
          _selectedTable = reservedTable;
        } else if (tables.isNotEmpty) {
          _selectedTable = tables.first;
        }
        _isLoadingTables = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTables = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des tables: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _assignTable() async {
    if (_selectedTable == null) return;

    try {
      await widget.apiService.assignTableToReservation(
        reservationId: widget.reservation.id,
        tableId: _selectedTable!.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Table assignée avec succès'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Naviguer vers l'écran de commande
      _navigateToOrder();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'assignation: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _navigateToOrder() {
    if (_selectedTable == null) return;

    Navigator.of(context).pushNamed(
      '/order',
      arguments: {'table': _selectedTable!, 'reservation': widget.reservation},
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reservation = widget.reservation;

    return Scaffold(
      drawer: const CustomDrawer(serverName: 'John Doe'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('Réservation ${reservation.code}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations de réservation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations de réservation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      label: 'Code',
                      value: reservation.code,
                      icon: Icons.confirmation_number,
                    ),
                    if (reservation.clientName != null)
                      _InfoRow(
                        label: 'Client',
                        value: reservation.clientName!,
                        icon: Icons.person,
                      ),
                    if (reservation.clientPhone != null)
                      _InfoRow(
                        label: 'Téléphone',
                        value: reservation.clientPhone!,
                        icon: Icons.phone,
                      ),
                    _InfoRow(
                      label: 'Date',
                      value:
                          '${reservation.date.day}/${reservation.date.month}/${reservation.date.year}',
                      icon: Icons.calendar_today,
                    ),
                    _InfoRow(
                      label: 'Heure',
                      value:
                          '${reservation.heureDebut.hour}h${reservation.heureDebut.minute.toString().padLeft(2, '0')} - ${reservation.heureFin.hour}h${reservation.heureFin.minute.toString().padLeft(2, '0')}',
                      icon: Icons.access_time,
                    ),
                    _InfoRow(
                      label: 'Personnes',
                      value: '${reservation.nombrePersonnes}',
                      icon: Icons.people,
                    ),
                    if (reservation.type == ReservationType.prepaidMenu) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              color: cs.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Menu prépayé inclus',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Table assignée ou sélection
            Text(
              reservation.type == ReservationType.prepaidMenu
                  ? 'Table réservée'
                  : 'Sélection de table',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            if (_isLoadingTables)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_availableTables == null || _availableTables!.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: cs.error),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune table disponible',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune table disponible pour cette plage horaire.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else if (_selectedTable != null) ...[
              SuggestedTableCard(
                table: _selectedTable!,
                isAvailable: _availableTables!.any(
                  (t) => t.id == _selectedTable!.id,
                ),
                onSelect: () async {
                  final result = await Navigator.of(context).pushNamed(
                    '/available-tables',
                    arguments: {
                      'reservation': reservation,
                      'availableTables': _availableTables!,
                      'selectedTable': _selectedTable,
                    },
                  );

                  if (result != null && result is DiningTable) {
                    setState(() {
                      _selectedTable = result;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // Boutons d'action
            if (reservation.type == ReservationType.prepaidMenu)
              FilledButton.icon(
                onPressed: _selectedTable != null ? _navigateToOrder : null,
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Voir la commande prépayée'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else
              FilledButton.icon(
                onPressed: _selectedTable != null && !_isLoadingTables
                    ? _assignTable
                    : null,
                icon: const Icon(Icons.check),
                label: const Text('Assigner la table et créer la commande'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: cs.onSurface)),
          ),
        ],
      ),
    );
  }
}
