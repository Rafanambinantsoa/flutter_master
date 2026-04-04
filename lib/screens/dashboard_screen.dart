import 'package:flutter/material.dart';
import '../widgets/session_drawer.dart';
import '../components/notification_badge_icon.dart'; // Added

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const SessionDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          NotificationBadgeIcon(), // Use the new widget here
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section principale - Arrivée Client
            Card(
              elevation: 2,
              child: InkWell(
                onTap: () =>
                    Navigator.of(context).pushNamed('/client-selection'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_add,
                          size: 32,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Arrivée Client',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gérer l\'arrivée d\'un nouveau client',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section des actions rapides
            Text(
              'Actions rapides',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                // Sur petits écrans, on donne un peu plus de hauteur aux cellules
                // pour éviter les overflows dus à la combinaison padding + texte.
                final bool isNarrow = constraints.maxWidth < 380;
                final double childAspectRatio = isNarrow ? 1.35 : 1.5;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _ActionCard(
                      title: 'Commandes',
                      icon: Icons.receipt_long,
                      color: cs.primary,
                      onTap: () => Navigator.of(context).pushNamed('/orders'),
                    ),
                    _ActionCard(
                      title: 'Tables',
                      icon: Icons.table_restaurant,
                      color: cs.primary,
                      onTap: () => Navigator.of(context).pushNamed('/tables'),
                    ),
                    _ActionCard(
                      title: 'Notifications',
                      icon: Icons.notifications,
                      color: cs.primary,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/notifications'),
                    ),
                    _ActionCard(
                      title: 'Réservations',
                      icon: Icons.event,
                      color: cs.primary,
                      onTap: () {
                        // Navigation vers la recherche de réservation
                        Navigator.of(context).pushNamed(
                          '/reservation-lookup',
                          arguments: {'type': null},
                        );
                      },
                    ),
                    _ActionCard(
                      title: 'QR code',
                      icon: Icons.qr_code_2,
                      color: cs.primary,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/cart-menu-qr'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          // Un peu moins de padding => plus de place verticale => pas d'overflow.
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
