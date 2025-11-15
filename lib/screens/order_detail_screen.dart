import 'package:flutter/material.dart';
import '../widgets/session_drawer.dart';
import 'menu_selection_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String id;
  final DateTime? createdAt;
  final dynamic status; // matches CommandeStatus or similar
  final double? total;
  final List<Map<String, dynamic>>? lines;
  final Map<String, dynamic>? clientInfo; // Informations du client
  final int? tableNumber; // Numéro de table

  const OrderDetailScreen({
    super.key,
    required this.id,
    this.createdAt,
    this.status,
    this.total,
    this.lines,
    this.clientInfo,
    this.tableNumber,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<Map<String, dynamic>>? _currentLines;

  @override
  void initState() {
    super.initState();
    _currentLines = widget.lines;
  }

  bool get _hasUnsavedChanges {
    if (_currentLines == null && widget.lines == null) return false;
    if (_currentLines == null || widget.lines == null) return true;
    if (_currentLines!.length != widget.lines!.length) return true;

    // Comparer les lignes
    for (int i = 0; i < _currentLines!.length; i++) {
      final current = _currentLines![i];
      final original = widget.lines!.firstWhere(
        (l) => l['name'] == current['name'],
        orElse: () => {},
      );
      if (original.isEmpty ||
          (current['qty'] as int? ?? 0) != (original['qty'] as int? ?? 0)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _addMenuItems(BuildContext context) async {
    final result = await Navigator.of(context).push<List<MenuSelection>>(
      MaterialPageRoute(
        builder: (_) => MenuSelectionScreen(
          commandeId: widget.id,
          existingItems: _currentLines,
        ),
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      // Ajouter les nouveaux items aux lignes existantes
      setState(() {
        final newLines = <Map<String, dynamic>>[];

        // Garder les lignes existantes
        if (_currentLines != null) {
          newLines.addAll(_currentLines!);
        }

        // Ajouter les nouveaux items sélectionnés
        for (final selection in result) {
          // Vérifier si l'item existe déjà
          final existingIndex = newLines.indexWhere(
            (line) => line['name'] == selection.menu.name,
          );

          if (existingIndex >= 0) {
            // Incrémenter la quantité si l'item existe déjà
            final currentQty = (newLines[existingIndex]['qty'] as int? ?? 1);
            newLines[existingIndex]['qty'] = currentQty + selection.quantity;
          } else {
            // Ajouter un nouvel item
            newLines.add({
              'name': selection.menu.name,
              'qty': selection.quantity,
              'price': selection.menu.price,
              'status': 'en_attente', // Nouvel item en attente par défaut
            });
          }
        }

        _currentLines = newLines;
      });

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.length} menu(s) ajouté(s) à la commande'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeItem(int index) {
    setState(() {
      if (_currentLines != null && index < _currentLines!.length) {
        _currentLines!.removeAt(index);
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasUnsavedChanges) return;

    // TODO: Appeler l'API pour mettre à jour la commande avec les nouveaux articles
    // Pour l'instant, on affiche juste un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modifications sauvegardées'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    // Recharger les données ou mettre à jour l'état
    setState(() {
      // Les modifications sont sauvegardées, on pourrait recharger depuis l'API
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Calculer le total réel à partir des lignes (utiliser _currentLines si disponible)
    final linesToUse = _currentLines ?? widget.lines;
    double calculatedTotal = 0.0;
    if (linesToUse != null) {
      for (final line in linesToUse) {
        final int qty = (line['qty'] as int?) ?? 1;
        final double price = (line['price'] as num?)?.toDouble() ?? 0;
        calculatedTotal += price * qty;
      }
    }

    return Scaffold(
      drawer: const SessionDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('Commande ${widget.id}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Ajouter des menus',
            onPressed: () => _addMenuItems(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderInfo(
              id: widget.id,
              createdAt: widget.createdAt,
              status: widget.status,
              total: calculatedTotal,
            ),
            const SizedBox(height: 12),
            // Informations client et table
            if (widget.clientInfo != null || widget.tableNumber != null)
              _ClientTableInfo(
                clientInfo: widget.clientInfo,
                tableNumber: widget.tableNumber,
              ),
            if (widget.clientInfo != null || widget.tableNumber != null)
              const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: linesToUse?.length ?? 0,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final line = linesToUse![index];
                    final String name = line['name']?.toString() ?? 'Item';
                    final int qty = (line['qty'] as int?) ?? 1;
                    final double price =
                        (line['price'] as num?)?.toDouble() ?? 0;
                    final String? status = line['status']?.toString();
                    return ListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(name)),
                          if (status != null) ...[
                            const SizedBox(width: 8),
                            _StatusBadge(status: status),
                          ],
                        ],
                      ),
                      subtitle: Text('Quantité: $qty'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(price * qty).toStringAsFixed(0)} Ar',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (_hasUnsavedChanges) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              tooltip: 'Retirer',
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: calculatedTotal == 0.0 && !_hasUnsavedChanges
          ? null
          : Container(
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
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${calculatedTotal.toStringAsFixed(0)} Ar',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_hasUnsavedChanges) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save),
                        label: const Text('Sauvegarder les modifications'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ],
                ),
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

class _ClientTableInfo extends StatelessWidget {
  final Map<String, dynamic>? clientInfo;
  final int? tableNumber;

  const _ClientTableInfo({this.clientInfo, this.tableNumber});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(Icons.person, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Informations client',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Informations client
          if (clientInfo != null) ...[
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Nom',
              value: clientInfo!['nom']?.toString() ?? 'N/A',
            ),
            if (clientInfo!['email'] != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: clientInfo!['email'].toString(),
              ),
            ],
            if (clientInfo!['telephone'] != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                value: clientInfo!['telephone'].toString(),
              ),
            ],
            if (clientInfo!['adresse'] != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Adresse',
                value: clientInfo!['adresse'].toString(),
              ),
            ],
          ] else ...[
            Text(
              'Informations client non disponibles',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          // Numéro de table
          if (tableNumber != null) ...[
            if (clientInfo != null) const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.table_restaurant,
                    size: 20,
                    color: cs.onSecondaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Table',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$tableNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Badge pour afficher le statut d'un article
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'en_cours':
      case 'en cours':
        return 'En cours';
      case 'terminee':
      case 'terminée':
      case 'termine':
        return 'Terminé';
      case 'en_attente':
      case 'en attente':
        return 'En attente';
      case 'annulee':
      case 'annulée':
      case 'annule':
        return 'Annulé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status, ColorScheme cs) {
    switch (status.toLowerCase()) {
      case 'en_cours':
      case 'en cours':
        return Colors.orange;
      case 'terminee':
      case 'terminée':
      case 'termine':
        return Colors.green;
      case 'en_attente':
      case 'en attente':
        return Colors.blue;
      case 'annulee':
      case 'annulée':
      case 'annule':
        return Colors.red;
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(status, cs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
