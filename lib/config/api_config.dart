/// Configuration de l'API
class ApiConfig {
  /// Base URL de l'API backend
  static const String baseUrl = 'http://10.56.103.141:3000';

  /// Timeout pour les requêtes HTTP (en secondes)
  static const int requestTimeout = 30;

  /// Durée de vie du token (1 heure)
  static const Duration tokenLifetime = Duration(hours: 1);
}
