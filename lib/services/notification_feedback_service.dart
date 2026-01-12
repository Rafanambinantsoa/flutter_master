import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'dart:async';

/// Service pour gérer les retours sonores et haptiques lors des notifications
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

  /// Active la vibration haptique pour une notification avec pattern personnalisé
  /// Pattern : 3 secondes vibration → 1 seconde pause → 3 secondes vibration
  /// Utilise plusieurs appels HapticsType.heavy pour simuler une vibration continue
  /// Intensité maximale avec HapticsType.heavy
  Future<void> playNotificationVibration() async {
    try {
      // Vérifier si l'appareil peut vibrer
      final canVibrate = await Haptics.canVibrate();
      if (!canVibrate) {
        print('⚠️ [NotificationFeedback] Appareil ne supporte pas la vibration');
        return;
      }

      print('📳 [NotificationFeedback] Début du pattern de vibration (3s → 1s pause → 3s)');

      // Première vibration de 3 secondes
      // Répéter HapticsType.heavy toutes les 200ms pour maintenir une vibration continue
      await _vibrateForDuration(
        duration: const Duration(seconds: 3),
        hapticsType: HapticsType.heavy,
      );

      // Pause de 1 seconde
      await Future.delayed(const Duration(seconds: 1));
      print('📳 [NotificationFeedback] Pause de 1 seconde');

      // Deuxième vibration de 3 secondes
      await _vibrateForDuration(
        duration: const Duration(seconds: 3),
        hapticsType: HapticsType.heavy,
      );

      print('📳 [NotificationFeedback] Pattern de vibration terminé');
    } catch (e) {
      print('❌ [NotificationFeedback] Erreur lors de la vibration: $e');
    }
  }

  /// Fait vibrer pendant une durée spécifiée en répétant des vibrations haptiques
  /// Utilise HapticsType.heavy pour une intensité maximale
  /// Répète toutes les 200ms pour maintenir une vibration continue
  Future<void> _vibrateForDuration({
    required Duration duration,
    required HapticsType hapticsType,
  }) async {
    final startTime = DateTime.now();
    const vibrationInterval = Duration(milliseconds: 200); // Répéter toutes les 200ms

    while (DateTime.now().difference(startTime) < duration) {
      try {
        await Haptics.vibrate(
          hapticsType,
          useAndroidHapticConstants: false,
          usage: HapticsUsage.notification,
        );
      } catch (e) {
        print('⚠️ [NotificationFeedback] Erreur lors d\'une vibration: $e');
      }

      // Attendre avant la prochaine vibration
      await Future.delayed(vibrationInterval);
    }
  }

  /// Joue le son ET la vibration pour une notification complète
  Future<void> playNotificationFeedback({
    bool playSound = true,
    bool vibrate = true,
  }) async {
    // Jouer la vibration et le son en parallèle
    final futures = <Future>[];

    if (vibrate) {
      futures.add(playNotificationVibration());
    }

    if (playSound) {
      futures.add(playNotificationSound());
    }

    await Future.wait(futures);
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
