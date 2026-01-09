import 'package:flutter/material.dart';

import '../models/commande.dart';
import '../services/commande_service.dart';
import '../utils/commande_status_extensions.dart';
import '../widgets/session_drawer.dart';
import '../components/notification_badge_icon.dart'; // Added

class CommandesScreen extends StatefulWidget {
  const CommandesScreen({super.key});

  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> {
  // int _notificationCount = 3; // mock // Removed unused variable
  _Filter _selected = _Filter.all;

  List<Commande> _allOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  final CommandeService _commandeService = CommandeService();

  @override
  void initState() {
    super.initState();
    _loadCommandes();
  }

  Future<void> _loadCommandes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final commandes = await _commandeService.getCommandes();
      setState(() {
        _allOrders = commandes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e is CommandeServiceException
            ? e.message
            : 'Erreur lors du chargement des commandes';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final List<Commande> todays = _allOrders
        .where((o) => _isSameDay(o.dateCommande, today))
        .toList();
    final filtered = todays.where((o) {
      switch (_selected) {
        case _Filter.all:
          return true;
        case _Filter.pending:
          return o.status == CommandeStatus.enAttente ||
              o.status == CommandeStatus.enCours;
        case _Filter.served:
          return o.status == CommandeStatus.terminee;
        case _Filter.cancelled:
          return o.status == CommandeStatus.annulee;
      }
    }).toList();

    final int revenue = todays
        .where((o) => o.status == CommandeStatus.terminee)
        .fold<int>(0, (sum, o) => sum + o.totalPrice.toInt());

    return Scaffold(
      drawer: const SessionDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: const Text('Commandes'),
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
            onPressed: _isLoading ? null : _loadCommandes,
            tooltip: 'Actualiser',
          ),
          NotificationBadgeIcon(), // Use the new widget here
        ],
      ),
      body: Column(
        children: [
          _FiltersBar(
            selected: _selected,
            onChanged: (f) => setState(() => _selected = f),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _RevenueCard(amountLabel: _formatAr(revenue)),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadCommandes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucune commande',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final o = filtered[index];
                      return _OrderTile(
                        order: o,
                        onTap: () {
                          // Trouver la commande complète dans _allOrders
                          final commandeId = o.reference;
                          Navigator.of(context).pushNamed(
                            '/orders/$commandeId',
                            arguments: {'commandeId': commandeId},
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatAr(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - 1 - i;
      buf.write(s[s.length - 1 - i]);
      if ((i + 1) % 3 == 0 && idx != 0) buf.write(' ');
    }
    return String.fromCharCodes(buf.toString().runes.toList().reversed) + ' Ar';
  }
}

enum _Filter { all, pending, served, cancelled }

class _FiltersBar extends StatelessWidget {
  final _Filter selected;
  final ValueChanged<_Filter> onChanged;

  const _FiltersBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _chip('Tous', _Filter.all),
          _chip('En attente', _Filter.pending),
          _chip('Terminées', _Filter.served),
          _chip('Annulées', _Filter.cancelled),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter f) {
    final bool sel = selected == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => onChanged(f),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Commande order;
  final VoidCallback? onTap;

  const _OrderTile({required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = order.status.displayLabel;
    final color = order.status.displayColor;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: ListTile(
            leading: Container(
              width: 10,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    order.reference,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(order.dateCommande),
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    '${order.totalPrice.toStringAsFixed(0)} Ar',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _RevenueCard extends StatelessWidget {
  final String amountLabel;
  const _RevenueCard({required this.amountLabel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          const Text('💵', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          const Text(
            'Total généré aujourd\'hui :',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            amountLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
