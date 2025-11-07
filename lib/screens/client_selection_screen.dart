import 'package:flutter/material.dart';
import '../data/mock_repository.dart';
import '../services/mock_api_service.dart';

/// Type de client sélectionné
enum ClientType {
  noReservation, // Client sans réservation
  standardReservation, // Client avec réservation standard
  prepaidReservation, // Client avec réservation incluant menu prépayé
}

class ClientSelectionScreen extends StatefulWidget {
  final MockRepository repo;
  final MockApiService apiService;

  const ClientSelectionScreen({
    super.key,
    required this.repo,
    required this.apiService,
  });

  @override
  State<ClientSelectionScreen> createState() => _ClientSelectionScreenState();
}

class _ClientSelectionScreenState extends State<ClientSelectionScreen> {
  ClientType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arrivée client'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Le client a-t-il une réservation ?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Column(
                children: [
                  _ClientTypeCard(
                    type: ClientType.noReservation,
                    title: 'Sans réservation',
                    description:
                        'Client sans réservation. Proposer une table disponible.',
                    icon: Icons.person_outline,
                    isSelected: _selectedType == ClientType.noReservation,
                    onTap: () {
                      setState(() {
                        _selectedType = ClientType.noReservation;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _ClientTypeCard(
                    type: ClientType.standardReservation,
                    title: 'Réservation standard',
                    description:
                        'Client avec réservation de table. Vérifier et assigner la table réservée.',
                    icon: Icons.event_outlined,
                    isSelected: _selectedType == ClientType.standardReservation,
                    onTap: () {
                      setState(() {
                        _selectedType = ClientType.standardReservation;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _ClientTypeCard(
                    type: ClientType.prepaidReservation,
                    title: 'Réservation avec menu prépayé',
                    description:
                        'Client avec réservation incluant menu prépayé. Afficher la commande pré-remplie.',
                    icon: Icons.restaurant_menu,
                    isSelected: _selectedType == ClientType.prepaidReservation,
                    onTap: () {
                      setState(() {
                        _selectedType = ClientType.prepaidReservation;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _selectedType == null
                  ? null
                  : () => _navigateToNextScreen(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Continuer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToNextScreen(BuildContext context) {
    if (_selectedType == null) return;

    switch (_selectedType!) {
      case ClientType.noReservation:
        Navigator.of(
          context,
        ).pushNamed('/accueil', arguments: {'type': ClientType.noReservation});
        break;
      case ClientType.standardReservation:
        Navigator.of(context).pushNamed(
          '/reservation-lookup',
          arguments: {'type': ClientType.standardReservation},
        );
        break;
      case ClientType.prepaidReservation:
        Navigator.of(context).pushNamed(
          '/reservation-lookup',
          arguments: {'type': ClientType.prepaidReservation},
        );
        break;
    }
  }
}

class _ClientTypeCard extends StatelessWidget {
  final ClientType type;
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClientTypeCard({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surface,
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withOpacity(0.1)
                    : cs.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? cs.primary : cs.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}
