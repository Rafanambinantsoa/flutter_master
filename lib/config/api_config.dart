/// Configuration de l'API
class ApiConfig {
  /// Base URL de l'API backend
  // static const String baseUrl = 'http://172.24.130.141:3000';

  //BOX
  // static const String baseUrl = 'http://192.168.0.199:3000';
  static const String baseUrl = 'https://back-master-ztyd.onrender.com';
  // static const String baseUrl = 'https://test-nest.unityfianar.site';

  /// Timeout pour les requêtes HTTP (en secondes)s
  static const int requestTimeout = 30;

  /// Durée de vie du token (1 heure)
  static const Duration tokenLifetime = Duration(hours: 1);
  static const String pusherApiKey = '64847502664fa3c1a5d6';
  static const String pusherCluster = 'mt1';
}
