import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_master/services/notification_service.dart';
import '../widgets/session_drawer.dart';
import 'package:flutter_master/models/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotifFilter _selected = _NotifFilter.all;
  final ScrollController _scrollController = ScrollController();
  int _previousNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    // Marquer toutes les notifications comme lues quand l'écran s'ouvre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      // Vérifier s'il y a des notifications non lues avant de marquer
      if (notificationService.unreadCount > 0) {
        notificationService.markAllAsRead();
        print(
          '✅ [NotificationsScreen] Toutes les notifications marquées comme lues',
        );
      }
      _previousNotificationCount = notificationService.notifications.length;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    final allNotifications = notificationService.notifications;
    final filtered = _filterList(allNotifications, _selected);

    // Détecter une nouvelle notification et scroller vers le haut
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentCount = allNotifications.length;
      if (currentCount > _previousNotificationCount &&
          _selected == _NotifFilter.all &&
          _scrollController.hasClients) {
        // Une nouvelle notification a été ajoutée, scroller vers le haut
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      _previousNotificationCount = currentCount;
    });

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
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (notificationService.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  _showDeleteAllDialog(context, notificationService),
              tooltip: 'Supprimer toutes les notifications',
            ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              if (notificationService.unreadCount > 0)
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
                      '${notificationService.unreadCount}',
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
          _NotifFilters(
            selected: _selected,
            onChanged: (f) => setState(() => _selected = f),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    controller: _scrollController,
                    key: ValueKey('notifications_${filtered.length}'),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final n = filtered[index];
                      return _NotificationTile(
                        key: ValueKey(n.id),
                        notification: n,
                        onTap: () {
                          notificationService.markAsRead(n.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<AppNotification> _filterList(
    List<AppNotification> list,
    _NotifFilter f,
  ) {
    switch (f) {
      case _NotifFilter.all:
        return list;
      case _NotifFilter.unread:
        return list.where((n) => !n.isRead).toList();
      case _NotifFilter.system:
        return list.where((n) => n.kind == NotificationKind.system).toList();
      case _NotifFilter.orders:
        return list.where((n) => n.kind == NotificationKind.order).toList();
    }
  }

  Future<void> _showDeleteAllDialog(
    BuildContext context,
    NotificationService notificationService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les notifications'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes les notifications ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notificationService.clearAllNotifications();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications ont été supprimées'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

enum _NotifFilter { all, unread, orders, system }

class _NotifFilters extends StatelessWidget {
  final _NotifFilter selected;
  final ValueChanged<_NotifFilter> onChanged;

  const _NotifFilters({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _chip('Toutes', _NotifFilter.all),
          _chip('Non lues', _NotifFilter.unread),
          _chip('Commandes', _NotifFilter.orders),
          _chip('Système', _NotifFilter.system),
        ],
      ),
    );
  }

  Widget _chip(String label, _NotifFilter f) {
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

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color statusColor = notification.isRead
        ? cs.onSurfaceVariant
        : cs.primary;
    final IconData icon = _iconFor(notification.kind);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Icon(icon, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(notification.timestamp),
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
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

  IconData _iconFor(NotificationKind k) {
    switch (k) {
      case NotificationKind.order:
        return Icons.table_bar_rounded;
      case NotificationKind.system:
        return Icons.settings_outlined;
      case NotificationKind.info:
        return Icons.info_outline;
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'Aucune notification',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
