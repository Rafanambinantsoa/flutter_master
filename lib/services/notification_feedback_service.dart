import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Service pour gérer les retours sonores lors des notifications
class NotificationFeedbackService {
  static final NotificationFeedbackService _instance =
      NotificationFeedbackService._internal();
  factory NotificationFeedbackService() => _instance;
  NotificationFeedbackService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  /// Initialise le lecteur audio
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      // Configurer le mode du lecteur pour les notifications
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      _isInitialized = true;
    }
  }

  /// Joue un son de notification
  /// Utilise un fichier audio personnalisé si disponible, sinon le son système
  Future<void> playNotificationSound() async {
    try {
      await _ensureInitialized();

      // Essayer d'abord de jouer un fichier audio personnalisé
      try {
        // Chemin vers le fichier audio dans les assets
        // Format supporté: mp3, wav, ogg, etc.
        await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
        print('🔔 [NotificationFeedback] Son personnalisé joué');
      } catch (e) {
        // Si le fichier personnalisé n'existe pas, utiliser le son système
        print(
          '⚠️ [NotificationFeedback] Fichier audio personnalisé non trouvé, utilisation du son système',
        );
        await SystemSound.play(SystemSoundType.alert);
        print('🔔 [NotificationFeedback] Son système joué');
      }
    } catch (e) {
      print('❌ [NotificationFeedback] Erreur lors de la lecture du son: $e');
      // Fallback vers le son système en cas d'erreur
      try {
        await SystemSound.play(SystemSoundType.alert);
        print('🔔 [NotificationFeedback] Son système (fallback) joué');
      } catch (fallbackError) {
        print(
          '❌ [NotificationFeedback] Erreur avec le son système: $fallbackError',
        );
      }
    }
  }

  /// Arrête le son en cours de lecture
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      print('⏹️ [NotificationFeedback] Son arrêté');
    } catch (e) {
      print('❌ [NotificationFeedback] Erreur lors de l\'arrêt: $e');
    }
  }

  /// Libère les ressources du lecteur audio
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      print('🗑️ [NotificationFeedback] Lecteur audio libéré');
    } catch (e) {
      print('❌ [NotificationFeedback] Erreur lors de la libération: $e');
    }
  }
}
