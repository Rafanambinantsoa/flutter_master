import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_master/services/notification_service.dart';
import '../widgets/session_drawer.dart';

enum NotificationKind { order, system, info }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationKind kind;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.kind,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotifFilter _selected = _NotifFilter.all;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    final allNotifications = notificationService.notifications;
    final filtered = _filterList(allNotifications, _selected);
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
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final n = filtered[index];
                      return _NotificationTile(
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

  const _NotificationTile({required this.notification, required this.onTap});

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
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
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
