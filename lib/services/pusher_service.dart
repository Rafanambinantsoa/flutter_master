import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter_master/config/api_config.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_master/models/app_notification.dart';

/// Callback type pour la gestion des notifications
typedef OnPusherNotification =
    void Function(AppNotification notification, String? snackBarMessage);

/// Service singleton pour gérer Pusher de manière globale et unique
/// Garantit une seule écoute active, même lors des navigations et rebuilds
class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  final Set<String> _activeChannels = {};
  bool _isPusherClientInitialized = false;
  bool _isNotificationHandlerRegistered = false;

  // Gestionnaire unique pour les notifications (défini une seule fois)
  OnPusherNotification? _notificationHandler;

  // Cache pour la déduplication d'événements: stores { 'commandId': timestamp }
  final Map<String, DateTime> _eventCache = {};
  static const Duration _deduplicationDuration = Duration(seconds: 1);

  // Compteur unique pour tracer chaque événement traité
  int _eventProcessedCount = 0;
  final Map<String, int> _eventIdToProcessCount = {};

  /// Enregistre le gestionnaire de notifications (appelé une seule fois au démarrage)
  /// Cette méthode garantit qu'un seul gestionnaire est actif
  void registerNotificationHandler(OnPusherNotification handler) {
    if (_isNotificationHandlerRegistered) {
      print(
        '⚠️ [PusherService] Tentative de ré-enregistrement du gestionnaire - IGNORÉ',
      );
      return;
    }
    _notificationHandler = handler;
    _isNotificationHandlerRegistered = true;
    print(
      '✅ [PusherService] Gestionnaire de notifications enregistré (unique)',
    );
  }

  /// Initialise Pusher une seule fois
  Future<void> initPusher() async {
    if (_isPusherClientInitialized) {
      print('⚠️ [PusherService] initPusher() appelé plusieurs fois - IGNORÉ');
      return;
    }

    print('🚀 [PusherService] Initialisation de Pusher...');
    _activeChannels.clear();

    await pusher.init(
      apiKey: ApiConfig.pusherApiKey,
      cluster: ApiConfig.pusherCluster,
      onConnectionStateChange: (currentState, previousState) {
        print('📡 [PusherService] État: $previousState -> $currentState');
      },
      onError: (message, code, error) {
        print('❌ [PusherService] Erreur: $message ($code)');
      },
      onEvent: (event) {
        _handlePusherEvent(event);
      },
    );

    _isPusherClientInitialized = true;
    print('✅ [PusherService] Client Pusher initialisé');

    await pusher.connect();
    await _subscribe('commandes');
    print('✅ [PusherService] Abonnement au canal "commandes" effectué');
  }

  /// Gère les événements Pusher de manière unique et centralisée
  /// Cette méthode est appelée UNE SEULE FOIS par événement reçu
  void _handlePusherEvent(PusherEvent event) {
    // Log de réception brute
    print(
      '📨 [PusherService] Événement reçu: ${event.eventName} sur ${event.channelName}',
    );

    // Déduplication
    if (_isDuplicateEvent(event)) {
      print(
        '⏭️  [PusherService] Événement dupliqué ignoré: ${event.eventName}',
      );
      return;
    }

    // Traitement unique de l'événement
    _eventProcessedCount++;
    final eventId =
        '${event.channelName}_${event.eventName}_${DateTime.now().millisecondsSinceEpoch}';
    _eventIdToProcessCount[eventId] = _eventProcessedCount;

    print(
      '✅ [PusherService] Événement traité #$_eventProcessedCount: ${event.eventName} (ID: $eventId)',
    );

    // Si un gestionnaire est enregistré, l'appeler UNE SEULE FOIS
    if (_notificationHandler != null) {
      try {
        final notificationData = _parseEventToNotification(event);
        if (notificationData != null) {
          print(
            '📬 [PusherService] Création de notification pour: ${event.eventName}',
          );
          _notificationHandler!(
            notificationData['notification'] as AppNotification,
            notificationData['snackBarMessage'] as String?,
          );
          print(
            '✅ [PusherService] Notification créée et envoyée au gestionnaire (traitement unique)',
          );
        }
      } catch (e) {
        print(
          '❌ [PusherService] Erreur lors du traitement de l\'événement: $e',
        );
      }
    } else {
      print(
        '⚠️ [PusherService] Aucun gestionnaire de notifications enregistré',
      );
    }
  }

  /// Parse un événement Pusher en notification
  Map<String, dynamic>? _parseEventToNotification(PusherEvent event) {
    String notificationTitle = 'Nouvel événement Pusher';
    String notificationBody = '${event.eventName} sur ${event.channelName}';
    String? snackBarMessage;

    if (event.data != null && event.data!.isNotEmpty) {
      try {
        final Map<String, dynamic> data = json.decode(event.data!);
        if (event.eventName == 'commande-terminer') {
          notificationTitle = 'Commande terminée';
          notificationBody = data['message'] ?? notificationBody;
          snackBarMessage = data['message'] ?? 'Commande terminée';
        }
      } catch (e) {
        print('⚠️ [PusherService] Erreur de décodage JSON: $e');
        notificationBody =
            'Événement ${event.eventName} avec données non parsables';
      }
    }

    final notification = AppNotification(
      id: 'pusher_${event.eventName}_${DateTime.now().millisecondsSinceEpoch}',
      title: notificationTitle,
      body: notificationBody,
      timestamp: DateTime.now(),
      expiryTime: DateTime.now().add(const Duration(hours: 2)),
      kind: event.eventName == 'commande-terminer'
          ? NotificationKind.order
          : NotificationKind.info,
    );

    return {'notification': notification, 'snackBarMessage': snackBarMessage};
  }

  /// Vérifie si un événement est un doublon
  bool _isDuplicateEvent(PusherEvent event) {
    if (event.channelName == 'commandes' &&
        event.eventName == 'commande-terminer' &&
        event.data != null) {
      try {
        final Map<String, dynamic> data = json.decode(event.data!);
        final String? commandeId = data['commandeId']?.toString();

        if (commandeId != null) {
          final now = DateTime.now();
          if (_eventCache.containsKey(commandeId)) {
            final lastEventTime = _eventCache[commandeId]!;
            if (now.difference(lastEventTime) < _deduplicationDuration) {
              return true;
            }
          }
          _eventCache[commandeId] = now;
        }
      } catch (e) {
        print('⚠️ [PusherService] Erreur lors de la déduplication: $e');
      }
    }
    return false;
  }

  /// S'abonne à un canal (protection contre les doubles abonnements)
  Future<void> _subscribe(String channelName) async {
    if (_activeChannels.contains(channelName)) {
      print('⚠️ [PusherService] Déjà abonné au canal: $channelName');
      return;
    }
    await pusher.subscribe(channelName: channelName);
    _activeChannels.add(channelName);
    print('✅ [PusherService] Abonné au canal: $channelName');
  }

  /// Déconnecte Pusher
  Future<void> disconnect() async {
    await pusher.disconnect();
    _isPusherClientInitialized = false;
    _isNotificationHandlerRegistered = false;
    _notificationHandler = null;
    _activeChannels.clear();
    _eventCache.clear();
    print('🔌 [PusherService] Déconnecté');
  }

  /// Obtient le nombre d'événements traités (pour debugging)
  int get processedEventCount => _eventProcessedCount;

  /// Obtient les statistiques de traitement (pour debugging)
  Map<String, dynamic> getStats() {
    return {
      'processedCount': _eventProcessedCount,
      'activeChannels': _activeChannels.toList(),
      'isInitialized': _isPusherClientInitialized,
      'isHandlerRegistered': _isNotificationHandlerRegistered,
    };
  }
}
