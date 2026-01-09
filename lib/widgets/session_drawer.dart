import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../components/custom_drawer.dart';
import 'package:provider/provider.dart'; // Added
import 'package:flutter_master/services/notification_service.dart'; // Added

/// Widget drawer qui récupère automatiquement le nom du serveur depuis la session
class SessionDrawer extends StatefulWidget {
  const SessionDrawer({super.key});

  @override
  State<SessionDrawer> createState() => _SessionDrawerState();
}

class _SessionDrawerState extends State<SessionDrawer> {
  final SessionService _sessionService = SessionService();
  String _serverName = 'Serveur';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServerName();
  }

  Future<void> _loadServerName() async {
    final name = await _sessionService.getServerName();
    if (mounted) {
      setState(() {
        _serverName = name ?? 'Serveur';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _sessionService.clearSession();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Drawer(child: Center(child: CircularProgressIndicator()));
    }

    return CustomDrawer(
      serverName: _serverName,
      onLogout: _handleLogout,
      notificationCount: Provider.of<NotificationService>(
        context,
      ).unreadCount, // Added
    );
  }
}
