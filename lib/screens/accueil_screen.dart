import 'package:flutter/material.dart';
import '../data/mock_repository.dart';
import '../models/table.dart';
import '../components/suggested_table_card.dart';
import '../components/table_tile_card.dart';
import '../components/custom_drawer.dart';

class AccueilScreen extends StatefulWidget {
  final MockRepository repo;
  const AccueilScreen({super.key, required this.repo});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  final TextEditingController _reservationCtrl = TextEditingController();
  int _people = 2;
  DiningTable? _suggested;
  int _notificationCount = 3; // mock dynamic count

  void _checkReservation() {
    // Mock: if reservation code present, route to fixed table id 't1'
    if (_reservationCtrl.text.trim().isNotEmpty) {
      final reserved = widget.repo.tables.first;
      setState(() => _suggested = reserved);
    } else {
      setState(() => _suggested = widget.repo.findFreeTable(people: _people));
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
            tooltip: 'Menu',
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
            Text(
              'Arrivée client',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reservationCtrl,
              decoration: const InputDecoration(
                labelText: 'Code de réservation (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Personnes:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _people,
                  items: const [1, 2, 3, 4]
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (v) => setState(() => _people = v ?? 2),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _checkReservation,
                  child: const Text('Proposer table'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_suggested != null)
              SuggestedTableCard(
                table: _suggested!,
                onSelect: () {
                  Navigator.of(
                    context,
                  ).pushNamed('/order', arguments: _suggested);
                },
              ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: widget.repo.tables.map((t) {
                  return TableTileCard(
                    table: t,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/order', arguments: t),
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
