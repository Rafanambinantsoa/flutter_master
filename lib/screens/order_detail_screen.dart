import 'package:flutter/material.dart';

import '../models/commande.dart';
import '../services/commande_service.dart';
import '../utils/commande_status_extensions.dart';
import '../widgets/session_drawer.dart';
import 'menu_selection_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String commandeId; // Référence de la commande (ex: "COM-5")

  const OrderDetailScreen({super.key, required this.commandeId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<Map<String, dynamic>>? _currentLines;
  final CommandeService _commandeService = CommandeService();
  bool _isCancelling = false;
  Commande? _commande;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCommandeDetails();
  }

  Future<void> _loadCommandeDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Extraire l'ID numérique de la référence (ex: "COM-5" -> "5")
      final idMatch = RegExp(r'(\d+)$').firstMatch(widget.commandeId);
      final numericId = idMatch?.group(1) ?? widget.commandeId;

      final commande = await _commandeService.getCommandeById(numericId);
      setState(() {
        _commande = commande;
        // Convertir les CommandeMenu en format Map pour _currentLines
        _currentLines = commande.commandeMenu.map((cm) {
          final prix = double.tryParse(cm.menu.prix) ?? 0.0;
          return {
            'name': cm.menu.nom,
            'qty': cm.quantity,
            'price': prix,
            'status': cm.status,
            'menuId': cm.menuId, // Garder l'ID du menu pour la mise à jour
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e is CommandeServiceException
            ? e.message
            : 'Erreur lors du chargement de la commande';
        _isLoading = false;
      });
    }
  }

  bool get _hasUnsavedChanges {
    if (_commande == null || _currentLines == null) return false;

    // Comparer les lignes actuelles avec les lignes originales de la commande
    if (_currentLines!.length != _commande!.commandeMenu.length) return true;

    // Créer une map des lignes originales pour faciliter la comparaison
    final originalLinesMap = <String, Map<String, dynamic>>{};
    for (final cm in _commande!.commandeMenu) {
      originalLinesMap[cm.menu.nom] = {
        'qty': cm.quantity,
        'price': double.tryParse(cm.menu.prix) ?? 0.0,
        'status': cm.status,
      };
    }

    // Comparer les lignes
    for (final current in _currentLines!) {
      final name = current['name'] as String?;
      if (name == null || !originalLinesMap.containsKey(name)) {
        return true; // Nouvelle ligne ajoutée
      }
      final original = originalLinesMap[name]!;
      if ((current['qty'] as int? ?? 0) != (original['qty'] as int? ?? 0)) {
        return true; // Quantité modifiée
      }
    }
    return false;
  }

  Future<void> _addMenuItems(BuildContext context) async {
    final result = await Navigator.of(context).push<List<MenuSelection>>(
      MaterialPageRoute(
        builder: (_) => MenuSelectionScreen(
          commandeId: widget.commandeId,
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
              'menuId': int.tryParse(selection.menu.id), // Inclure l'ID du menu
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
    if (!_hasUnsavedChanges || _commande == null || _currentLines == null) {
      return;
    }

    // Extraire l'ID numérique de la référence
    final idMatch = RegExp(r'(\d+)$').firstMatch(widget.commandeId);
    final numericId = idMatch?.group(1) ?? widget.commandeId;

    // Construire une map pour trouver les IDs des menus par nom
    final menuIdMap = <String, int>{};
    for (final cm in _commande!.commandeMenu) {
      menuIdMap[cm.menu.nom] = cm.menuId;
    }

    // Extraire les menuIds et quantities depuis _currentLines
    final menuIds = <int>[];
    final quantities = <int>[];

    for (final line in _currentLines!) {
      final name = line['name'] as String?;
      final qty = (line['qty'] as int?) ?? 1;

      // Chercher l'ID du menu
      int? menuId;
      if (line['menuId'] != null) {
        // Si l'ID est déjà présent dans la ligne
        menuId = (line['menuId'] as num?)?.toInt();
      } else if (name != null && menuIdMap.containsKey(name)) {
        // Sinon, chercher par nom
        menuId = menuIdMap[name];
      }

      if (menuId != null) {
        menuIds.add(menuId);
        quantities.add(qty);
      }
    }

    if (menuIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun menu à mettre à jour'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final request = UpdateCommandeMenusRequest(
        menuIds: menuIds,
        quantities: quantities,
      );

      final response = await _commandeService.updateCommandeMenus(
        numericId,
        request,
      );

      if (!mounted) return;

      // Mettre à jour l'état avec la réponse
      setState(() {
        _commande = response.commande;
        // Convertir les CommandeMenu en format Map pour _currentLines
        _currentLines = response.commande.commandeMenu.map((cm) {
          final prix = double.tryParse(cm.menu.prix) ?? 0.0;
          return {
            'name': cm.menu.nom,
            'qty': cm.quantity,
            'price': prix,
            'status': cm.status,
            'menuId': cm.menuId,
          };
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is CommandeServiceException
                ? e.message
                : 'Erreur lors de la sauvegarde: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _cancelCommande() async {
    // Demander confirmation avant d'annuler
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette commande ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      // Extraire l'ID numérique de la référence
      final idMatch = RegExp(r'(\d+)$').firstMatch(widget.commandeId);
      final numericId = idMatch?.group(1) ?? widget.commandeId;
      await _commandeService.cancelCommande(numericId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande annulée avec succès'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Retourner à l'écran précédent ou à l'accueil
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is CommandeServiceException
                ? e.message
                : 'Erreur lors de l\'annulation: ${e.toString()}',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        drawer: const SessionDrawer(),
        appBar: AppBar(
          title: Text('Commande ${widget.commandeId}'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        drawer: const SessionDrawer(),
        appBar: AppBar(
          title: Text('Commande ${widget.commandeId}'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: TextStyle(color: cs.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadCommandeDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_commande == null || _currentLines == null) {
      return Scaffold(
        drawer: const SessionDrawer(),
        appBar: AppBar(
          title: Text('Commande ${widget.commandeId}'),
          centerTitle: true,
        ),
        body: const Center(child: Text('Commande introuvable')),
      );
    }

    // Calculer le total réel à partir des lignes
    double calculatedTotal = 0.0;
    for (final line in _currentLines!) {
      final int qty = (line['qty'] as int?) ?? 1;
      final double price = (line['price'] as num?)?.toDouble() ?? 0;
      calculatedTotal += price * qty;
    }

    // Extraire les informations client et table depuis la réservation
    Map<String, dynamic>? clientInfo;
    int? tableNumber;
    if (_commande!.reservation != null) {
      final reservation = _commande!.reservation!;
      if (reservation.client != null) {
        clientInfo = {
          'nom': reservation.client!.nom,
          'email': reservation.client!.email,
          'telephone': reservation.client!.telephone,
          'adresse': reservation.client!.adresse,
        };
      }
      // Extraire le numéro de table depuis reservationTables
      if (reservation.reservationTables.isNotEmpty) {
        final tableData = reservation.reservationTables.first['table'];
        if (tableData != null && tableData['numero_table'] != null) {
          final numeroTable = tableData['numero_table'].toString();
          // Extraire le numéro (ex: "Table 1" -> 1)
          final match = RegExp(r'(\d+)$').firstMatch(numeroTable);
          tableNumber = match != null ? int.tryParse(match.group(1)!) : null;
        }
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
        title: Text('Commande ${_commande!.reference}'),
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
              id: _commande!.reference,
              createdAt: _commande!.dateCommande,
              status: _commande!.status,
              total: calculatedTotal,
            ),
            const SizedBox(height: 12),
            // Informations client et table
            if (clientInfo != null || tableNumber != null)
              _ClientTableInfo(
                clientInfo: clientInfo,
                tableNumber: tableNumber,
              ),
            if (clientInfo != null || tableNumber != null)
              const SizedBox(height: 12),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _currentLines!.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final line = _currentLines![index];
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
                          // Afficher le bouton de retrait uniquement si le statut est "en_attente"
                          if (status != null &&
                              (status.toLowerCase() == 'en_attente' ||
                                  status.toLowerCase() == 'en attente')) ...[
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isCancelling ? null : _cancelCommande,
                            icon: _isCancelling
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cancel_outlined),
                            label: const Text('Annuler'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: cs.error,
                              side: BorderSide(color: cs.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _hasUnsavedChanges ? _saveChanges : null,
                            icon: const Icon(Icons.save),
                            label: const Text('Sauvegarder'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
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
  final CommandeStatus? status;
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
                    color: status!.displayColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: status!.displayColor.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    status!.displayLabel,
                    style: TextStyle(
                      color: status!.displayColor,
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

  String _normalize(String value) {
    final lower = value.toLowerCase().trim();
    final withoutAccents = lower
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i');
    return withoutAccents.replaceAll(' ', '_').replaceAll('-', '_');
  }

  String _getStatusLabel(String status) {
    switch (_normalize(status)) {
      case 'en_cours':
      case 'encours':
        return 'En cours';
      case 'terminee':
      case 'termine':
      case 'terminer':
        return 'Terminé';
      case 'en_attente':
      case 'enattente':
        return 'En attente';
      case 'annulee':
      case 'annule':
      case 'annuler':
        return 'Annulé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status, ColorScheme cs) {
    switch (_normalize(status)) {
      case 'en_cours':
      case 'encours':
        return Colors.orange;
      case 'terminee':
      case 'termine':
      case 'terminer':
        return Colors.green;
      case 'en_attente':
      case 'enattente':
        return Colors.blue;
      case 'annulee':
      case 'annule':
      case 'annuler':
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
