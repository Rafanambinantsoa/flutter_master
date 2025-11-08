import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Service de gestion de session utilisateur
class SessionService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyServerName = 'server_name';
  static const String _keyTokenExpiry = 'token_expiry';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';

  /// Sauvegarde les informations de session
  ///
  /// [accessToken] : Token d'accès
  /// [serverName] : Nom du serveur
  /// [userId] : ID de l'utilisateur
  /// [userEmail] : Email de l'utilisateur
  Future<void> saveSession({
    required String accessToken,
    required String serverName,
    required int userId,
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = DateTime.now().add(ApiConfig.tokenLifetime);

    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyServerName, serverName);
    await prefs.setInt(_keyTokenExpiry, expiryTime.millisecondsSinceEpoch);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserEmail, userEmail);
  }

  /// Récupère le token d'accès
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();

    // Vérifier si le token est expiré
    if (await isTokenExpired()) {
      await clearSession();
      return null;
    }

    return prefs.getString(_keyAccessToken);
  }

  /// Récupère le nom du serveur
  Future<String?> getServerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerName);
  }

  /// Récupère l'ID de l'utilisateur
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  /// Récupère l'email de l'utilisateur
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  /// Vérifie si le token est expiré
  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTimestamp = prefs.getInt(_keyTokenExpiry);

    if (expiryTimestamp == null) {
      return true;
    }

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    return DateTime.now().isAfter(expiryTime);
  }

  /// Vérifie si l'utilisateur est connecté (token valide)
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && !await isTokenExpired();
  }

  /// Supprime toutes les données de session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyServerName);
    await prefs.remove(_keyTokenExpiry);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
  }

  /// Récupère toutes les informations de session
  Future<Map<String, dynamic>?> getSessionData() async {
    if (!await isLoggedIn()) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final expiryTimestamp = prefs.getInt(_keyTokenExpiry);

    return {
      'accessToken': prefs.getString(_keyAccessToken),
      'serverName': prefs.getString(_keyServerName),
      'userId': prefs.getInt(_keyUserId),
      'userEmail': prefs.getString(_keyUserEmail),
      'expiryTime': expiryTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(expiryTimestamp)
          : null,
    };
  }
}

