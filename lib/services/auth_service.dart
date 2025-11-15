import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';

/// Service d'authentification pour gérer le login
class AuthService {
  /// Effectue une requête de login
  ///
  /// [email] : Email de l'utilisateur
  /// [password] : Mot de passe de l'utilisateur
  ///
  /// Retourne [LoginResponse] en cas de succès
  /// Lance une [AuthException] en cas d'échec
  Future<LoginResponse> login(String email, String password) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Succès
        return LoginResponse.fromJson(responseData);
      } else {
        // Erreur - gérer les messages qui peuvent être une liste ou une chaîne
        String errorMessage = 'Erreur lors de la connexion';

        if (responseData.containsKey('message')) {
          final messageData = responseData['message'];
          if (messageData is List) {
            // Si c'est une liste, prendre le premier message
            errorMessage = messageData.isNotEmpty
                ? messageData[0].toString()
                : errorMessage;
          } else if (messageData is String) {
            errorMessage = messageData;
          }
        }

        final statusCode =
            responseData['statusCode'] as int? ?? response.statusCode;
        throw AuthException(message: errorMessage, statusCode: statusCode);
      }
    } on http.ClientException catch (e) {
      throw AuthException(
        message: 'Erreur de connexion: ${e.message}',
        statusCode: 0,
      );
    } on FormatException {
      throw AuthException(
        message: 'Réponse invalide du serveur',
        statusCode: 0,
      );
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        message: 'Une erreur inattendue est survenue: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}

/// Exception personnalisée pour les erreurs d'authentification
class AuthException implements Exception {
  final String message;
  final int statusCode;

  AuthException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}
