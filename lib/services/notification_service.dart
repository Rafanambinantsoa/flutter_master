import 'package:flutter/foundation.dart';
import 'package:flutter_master/screens/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_master/models/app_notification.dart';

class NotificationService extends ChangeNotifier {
  static const String _notificationsKey = 'app_notifications';
  final List<AppNotification> _notifications = [];

  NotificationService() {
    _loadNotifications();
  }

  List<AppNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];
    _notifications.clear();
    for (var jsonString in notificationsJson) {
      try {
        _notifications.add(AppNotification.fromJson(json.decode(jsonString)));
      } catch (e) {
        print('Erreur de décodage de notification: $e');
      }
    }
    _removeExpiredNotifications(); // Supprimer les notifications expirées au chargement
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    print('DEBUG: Saving notifications to SharedPreferences.'); // Debug print
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = _notifications
        .map((n) => json.encode(n.toJson()))
        .toList();
    await prefs.setStringList(_notificationsKey, notificationsJson);
    print('DEBUG: Notifications saved.'); // Debug print
  }

  void _removeExpiredNotifications() {
    _notifications.removeWhere((n) => n.expiryTime.isBefore(DateTime.now()));
  }

  Future<void> addNotification(AppNotification notification) async {
    print(
      'DEBUG: Adding notification to _notifications list: $notification',
    ); // Debug print
    _notifications.insert(
      0,
      notification,
    ); // Ajouter les nouvelles notifications au début
    _removeExpiredNotifications(); // Nettoyer les notifications expirées
    await _saveNotifications();
    print(
      'DEBUG: Notifying listeners after adding notification.',
    ); // Debug print
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    await _saveNotifications();
    notifyListeners();
  }

  // Optionnel: Méthode pour supprimer une notification spécifique
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    notifyListeners();
  }

  // Optionnel: Méthode pour nettoyer toutes les notifications (ou toutes les lues/expirées)
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }
}
