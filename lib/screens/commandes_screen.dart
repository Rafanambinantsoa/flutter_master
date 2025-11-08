import 'package:flutter/material.dart';
import '../widgets/session_drawer.dart';

enum CommandeStatus { pending, served, cancelled }

class CommandeModel {
  final String id;
  final DateTime createdAt;
  final CommandeStatus status;
  final double total;

  const CommandeModel({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.total,
  });
}

class CommandesScreen extends StatefulWidget {
  const CommandesScreen({super.key});

  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen> {
  int _notificationCount = 3; // mock
  _Filter _selected = _Filter.all;

  late final List<CommandeModel> _allOrders;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _allOrders = [
      CommandeModel(
        id: 'CMD-1021',
        createdAt: now.subtract(const Duration(minutes: 15)),
        status: CommandeStatus.pending,
        total: 18_000,
      ),
      CommandeModel(
        id: 'CMD-1020',
        createdAt: now.subtract(const Duration(minutes: 45)),
        status: CommandeStatus.served,
        total: 25_000,
      ),
      CommandeModel(
        id: 'CMD-1019',
        createdAt: now.subtract(const Duration(hours: 2)),
        status: CommandeStatus.cancelled,
        total: 12_000,
      ),
      CommandeModel(
        id: 'CMD-1018',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 20)),
        status: CommandeStatus.served,
        total: 8_000,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final List<CommandeModel> todays = _allOrders
        .where((o) => _isSameDay(o.createdAt, today))
        .toList();
    final filtered = todays.where((o) {
      switch (_selected) {
        case _Filter.all:
          return true;
        case _Filter.pending:
          return o.status == CommandeStatus.pending;
        case _Filter.served:
          return o.status == CommandeStatus.served;
        case _Filter.cancelled:
          return o.status == CommandeStatus.cancelled;
      }
    }).toList();

    final int revenue = todays
        .where((o) => o.status == CommandeStatus.served)
        .fold<int>(0, (sum, o) => sum + o.total.toInt());

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
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final o = filtered[index];
                return _OrderTile(
                  order: o,
                  onTap: () {
                    final lines = _mockLinesFor(o.id);
                    Navigator.of(context).pushNamed(
                      '/orders/${o.id}',
                      arguments: {
                        'id': o.id,
                        'createdAt': o.createdAt,
                        'status': o.status,
                        'total': o.total,
                        'lines': lines,
                      },
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

  List<Map<String, dynamic>> _mockLinesFor(String id) {
    // simple deterministic mock by id hash
    final base = id.hashCode.abs();
    final items = [
      {'name': 'Burger Classique', 'qty': (base % 3) + 1, 'price': 9500.0},
      {'name': 'Pâtes Alfredo', 'qty': (base % 2) + 1, 'price': 11000.0},
      {'name': 'Cola', 'qty': (base % 4) + 1, 'price': 3000.0},
    ];
    return items;
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
          _chip('Servies', _Filter.served),
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
  final CommandeModel order;
  final VoidCallback? onTap;

  const _OrderTile({required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = _statusLabel(order.status);
    final color = _statusColor(cs, order.status);
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
                    order.id,
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
                    _formatTime(order.createdAt),
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    '${order.total.toStringAsFixed(0)} Ar',
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

  String _statusLabel(CommandeStatus s) {
    switch (s) {
      case CommandeStatus.pending:
        return 'En attente';
      case CommandeStatus.served:
        return 'Servie';
      case CommandeStatus.cancelled:
        return 'Annulée';
    }
  }

  Color _statusColor(ColorScheme cs, CommandeStatus s) {
    switch (s) {
      case CommandeStatus.pending:
        return Colors.orange;
      case CommandeStatus.served:
        return Colors.green;
      case CommandeStatus.cancelled:
        return Colors.red;
    }
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
