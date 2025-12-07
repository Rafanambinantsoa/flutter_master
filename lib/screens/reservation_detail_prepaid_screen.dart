import 'package:flutter/material.dart';
import '../models/reservation_detail.dart';
import '../services/commande_service.dart';
import '../models/commande.dart';

class ReservationDetailPrepaidScreen extends StatefulWidget {
  final ReservationDetail reservation;

  const ReservationDetailPrepaidScreen({super.key, required this.reservation});

  @override
  State<ReservationDetailPrepaidScreen> createState() =>
      _ReservationDetailPrepaidScreenState();
}

class _ReservationDetailPrepaidScreenState
    extends State<ReservationDetailPrepaidScreen> {
  final CommandeService _commandeService = CommandeService();
  bool _isCreatingOrder = false;

  Future<void> _createOrder() async {
    setState(() {
      _isCreatingOrder = true;
    });

    try {
      // Préparer les données pour créer la commande
      final reservation = widget.reservation;
      final client = reservation.client;

      if (client == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informations client manquantes'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isCreatingOrder = false;
        });
        return;
      }

      // Extraire les IDs des menus et leurs quantités
      final menuIds = <int>[];
      final quantities = <int>[];

      for (final rm in reservation.reservationMenus) {
        menuIds.add(rm.menu.id);
        quantities.add(rm.quantity);
      }

      // Créer la requête de commande à partir de la réservation
      final request = CreateCommandeFromReservationRequest(
        reservationId: reservation.id,
        clientId: client.id,
        menuIds: menuIds,
        quantities: quantities,
        dateCommande: DateTime.now(),
      );

      final response = await _commandeService.createCommandeFromReservation(
        request,
      );

      if (!mounted) return;

      // Afficher le message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green,
        ),
      );

      // Naviguer vers l'écran d'accueil
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/accueil', (route) => false);
    } on CommandeServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
      setState(() {
        _isCreatingOrder = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création de la commande: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isCreatingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;

    return Scaffold(
      appBar: AppBar(
        title: Text('Réservation ${reservation.code}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations de réservation
            _buildSection(
              title: 'Informations de réservation',
              icon: Icons.info_outline,
              children: [
                _InfoRow(
                  label: 'Code',
                  value: reservation.code,
                  icon: Icons.confirmation_number,
                ),
                _InfoRow(
                  label: 'Date',
                  value:
                      '${reservation.date.day}/${reservation.date.month}/${reservation.date.year}',
                  icon: Icons.calendar_today,
                ),
                _InfoRow(
                  label: 'Heure',
                  value: '${reservation.heureDebut} - ${reservation.heureFin}',
                  icon: Icons.access_time,
                ),
                _InfoRow(
                  label: 'Statut',
                  value: reservation.status,
                  icon: Icons.info,
                ),
                _InfoRow(
                  label: 'Type',
                  value: reservation.typeReservation,
                  icon: Icons.category,
                ),
                _InfoRow(
                  label: 'Date de création',
                  value:
                      '${reservation.createdAt.day}/${reservation.createdAt.month}/${reservation.createdAt.year} ${reservation.createdAt.hour}:${reservation.createdAt.minute.toString().padLeft(2, '0')}',
                  icon: Icons.schedule,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Informations du client
            if (reservation.client != null)
              _buildSection(
                title: 'Informations du client',
                icon: Icons.person,
                children: [
                  _InfoRow(
                    label: 'Nom',
                    value: reservation.client!.nom,
                    icon: Icons.person_outline,
                  ),
                  _InfoRow(
                    label: 'Email',
                    value: reservation.client!.email,
                    icon: Icons.email,
                  ),
                  if (reservation.client!.telephone != null)
                    _InfoRow(
                      label: 'Téléphone',
                      value: reservation.client!.telephone!,
                      icon: Icons.phone,
                    ),
                  if (reservation.client!.adresse != null)
                    _InfoRow(
                      label: 'Adresse',
                      value: reservation.client!.adresse!,
                      icon: Icons.location_on,
                    ),
                ],
              ),

            if (reservation.client != null) const SizedBox(height: 16),

            // Tables réservées
            if (reservation.reservationTables.isNotEmpty)
              _buildSection(
                title: 'Tables réservées',
                icon: Icons.table_restaurant,
                children: [
                  ...reservation.reservationTables.map(
                    (rt) => _InfoRow(
                      label: 'Table',
                      value: rt.table.numeroTable,
                      icon: Icons.table_restaurant,
                    ),
                  ),
                ],
              ),

            if (reservation.reservationTables.isNotEmpty)
              const SizedBox(height: 16),

            // Menus réservés
            if (reservation.reservationMenus.isNotEmpty)
              _buildSection(
                title: 'Menus réservés',
                icon: Icons.restaurant_menu,
                children: [
                  ...reservation.reservationMenus.map(
                    (rm) => _MenuCard(menuDetail: rm),
                  ),
                ],
              ),

            if (reservation.reservationMenus.isNotEmpty)
              const SizedBox(height: 16),

            // Informations de paiement
            if (reservation.paymentReservationTable != null)
              _buildSection(
                title: 'Informations de paiement',
                icon: Icons.payment,
                children: [
                  _InfoRow(
                    label: 'Type de paiement',
                    value: reservation.paymentReservationTable!.typePaiment,
                    icon: Icons.payment,
                  ),
                  _InfoRow(
                    label: 'Montant',
                    value: '${reservation.paymentReservationTable!.montant} €',
                    icon: Icons.euro,
                  ),
                  if (reservation.paymentReservationTable!.reference != null)
                    _InfoRow(
                      label: 'Référence',
                      value: reservation.paymentReservationTable!.reference!,
                      icon: Icons.receipt,
                    ),
                  if (reservation
                          .paymentReservationTable!
                          .stripePaymentIntentId !=
                      null)
                    _InfoRow(
                      label: 'Stripe Payment Intent',
                      value: reservation
                          .paymentReservationTable!
                          .stripePaymentIntentId!,
                      icon: Icons.credit_card,
                    ),
                ],
              ),

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isCreatingOrder
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isCreatingOrder ? null : _createOrder,
                    icon: _isCreatingOrder
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart),
                    label: const Text('Créer commande'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: cs.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final ReservationMenuDetail menuDetail;

  const _MenuCard({required this.menuDetail});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final menu = menuDetail.menu;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (menu.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      menu.image!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(width: 60, height: 60),
                    ),
                  ),
                if (menu.image != null) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (menu.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          menu.description!,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${menu.prix} €',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.shopping_cart, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Quantité réservée: ${menuDetail.quantity}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            if (menuDetail.menu.commandeMenus.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...menuDetail.menu.commandeMenus.map(
                (cm) => Padding(
                  padding: const EdgeInsets.only(left: 20, top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.receipt, size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Commande #${cm.commandeId} - Quantité: ${cm.quantity} - Statut: ${cm.status}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
