import 'package:flutter/material.dart';
import '../components/custom_drawer.dart';

class OrderDetailScreen extends StatelessWidget {
  final String id;
  final DateTime? createdAt;
  final dynamic status; // matches CommandeStatus or similar
  final double? total;
  final List<Map<String, dynamic>>? lines;

  const OrderDetailScreen({
    super.key,
    required this.id,
    this.createdAt,
    this.status,
    this.total,
    this.lines,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Calculer le total réel à partir des lignes
    double calculatedTotal = 0.0;
    if (lines != null) {
      for (final line in lines!) {
        final int qty = (line['qty'] as int?) ?? 1;
        final double price = (line['price'] as num?)?.toDouble() ?? 0;
        calculatedTotal += price * qty;
      }
    }

    return Scaffold(
      drawer: const CustomDrawer(serverName: 'John Doe'),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('Commande $id'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderInfo(
              id: id,
              createdAt: createdAt,
              status: status,
              total: calculatedTotal,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: lines?.length ?? 0,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final line = lines![index];
                    final String name = line['name']?.toString() ?? 'Item';
                    final int qty = (line['qty'] as int?) ?? 1;
                    final double price =
                        (line['price'] as num?)?.toDouble() ?? 0;
                    return ListTile(
                      title: Text(name),
                      subtitle: Text('Quantité: $qty'),
                      trailing: Text(
                        '${(price * qty).toStringAsFixed(0)} Ar',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: calculatedTotal == 0.0
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.secondary,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${calculatedTotal.toStringAsFixed(0)} Ar',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final String id;
  final DateTime? createdAt;
  final dynamic status;
  final double? total;

  const _HeaderInfo({
    required this.id,
    this.createdAt,
    this.status,
    this.total,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Commande $id',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (status != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cs.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$status',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (createdAt != null) ...[
                const Icon(Icons.access_time, size: 14),
                const SizedBox(width: 4),
                Text(_formatDate(createdAt!)),
                const SizedBox(width: 12),
              ],
              if (total != null) ...[
                const Icon(Icons.payments_outlined, size: 14),
                const SizedBox(width: 4),
                Text('${total!.toStringAsFixed(0)} Ar'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} $h:$m';
  }
}
