# Sons de notification

Placez votre fichier audio de notification ici.

## Instructions

1. **Téléchargez ou créez un fichier audio de notification**
   - Formats supportés : `.mp3`, `.wav`, `.ogg`, `.m4a`
   - Durée recommandée : 1-3 secondes
   - Format recommandé : MP3 (meilleure compatibilité)

2. **Renommez le fichier en `notification.mp3`**
   - Le fichier doit s'appeler exactement `notification.mp3`
   - Ou modifiez le nom dans `lib/services/notification_feedback_service.dart` ligne 30

3. **Exemples de sites pour télécharger des sons de notification :**
   - [Freesound](https://freesound.org/)
   - [Zapsplat](https://www.zapsplat.com/)
   - [Notification Sounds](https://notificationsounds.com/)

4. **Si vous n'ajoutez pas de fichier :**
   - L'application utilisera automatiquement le son système par défaut

## Structure des fichiers

```
assets/
  └── sounds/
      └── notification.mp3  ← Placez votre fichier ici
```

