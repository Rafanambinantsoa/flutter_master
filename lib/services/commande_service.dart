import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/commande.dart';
import '../services/session_service.dart';

/// Service pour gérer les commandes
class CommandeService {
  final SessionService _sessionService = SessionService();

  /// Récupère la liste des commandes
  Future<List<Commande>> getCommandes() async {
    final token = await _sessionService.getAccessToken();
    if (token == null) {
      throw CommandeServiceException(
        message: 'Token d\'authentification manquant',
        statusCode: 401,
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/commande');
    try {
      final response = await http
          .get(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (response.statusCode != 200) {
        throw CommandeServiceException(
          message: 'Erreur lors de la récupération des commandes',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Commande.fromJson(e as Map<String, dynamic>))
          .toList();
    } on http.ClientException catch (e) {
      throw CommandeServiceException(
        message: 'Erreur de connexion: ${e.message}',
        statusCode: 0,
      );
    } on FormatException {
      throw CommandeServiceException(
        message: 'Réponse invalide du serveur',
        statusCode: 0,
      );
    } catch (e) {
      if (e is CommandeServiceException) rethrow;
      throw CommandeServiceException(
        message: 'Une erreur inattendue est survenue: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Crée une nouvelle commande
  Future<CreateCommandeResponse> createCommande(
    CreateCommandeRequest request,
  ) async {
    final token = await _sessionService.getAccessToken();
    if (token == null) {
      throw CommandeServiceException(
        message: 'Token d\'authentification manquant',
        statusCode: 401,
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/commande');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 && response.statusCode != 201) {
        final message =
            responseData['message'] as String? ??
            'Erreur lors de la création de la commande';
        throw CommandeServiceException(
          message: message,
          statusCode: response.statusCode,
        );
      }

      return CreateCommandeResponse.fromJson(responseData);
    } on http.ClientException catch (e) {
      throw CommandeServiceException(
        message: 'Erreur de connexion: ${e.message}',
        statusCode: 0,
      );
    } on FormatException {
      throw CommandeServiceException(
        message: 'Réponse invalide du serveur',
        statusCode: 0,
      );
    } catch (e) {
      if (e is CommandeServiceException) rethrow;
      throw CommandeServiceException(
        message: 'Une erreur inattendue est survenue: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Annule une commande
  Future<void> cancelCommande(String commandeId) async {
    final token = await _sessionService.getAccessToken();
    if (token == null) {
      throw CommandeServiceException(
        message: 'Token d\'authentification manquant',
        statusCode: 401,
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/commande/$commandeId');
    try {
      final response = await http
          .delete(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (response.statusCode != 200 && response.statusCode != 204) {
        final responseData = response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>
            : <String, dynamic>{};
        final message =
            responseData['message'] as String? ??
            'Erreur lors de l\'annulation de la commande';
        throw CommandeServiceException(
          message: message,
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw CommandeServiceException(
        message: 'Erreur de connexion: ${e.message}',
        statusCode: 0,
      );
    } on FormatException {
      throw CommandeServiceException(
        message: 'Réponse invalide du serveur',
        statusCode: 0,
      );
    } catch (e) {
      if (e is CommandeServiceException) rethrow;
      throw CommandeServiceException(
        message: 'Une erreur inattendue est survenue: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Récupère les détails d'une commande par son ID
  Future<Commande> getCommandeById(String commandeId) async {
    final token = await _sessionService.getAccessToken();
    if (token == null) {
      throw CommandeServiceException(
        message: 'Token d\'authentification manquant',
        statusCode: 401,
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/commande/$commandeId');
    try {
      final response = await http
          .get(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (response.statusCode != 200) {
        throw CommandeServiceException(
          message: 'Erreur lors de la récupération de la commande',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return Commande.fromJson(data);
    } on http.ClientException catch (e) {
      throw CommandeServiceException(
        message: 'Erreur de connexion: ${e.message}',
        statusCode: 0,
      );
    } on FormatException {
      throw CommandeServiceException(
        message: 'Réponse invalide du serveur',
        statusCode: 0,
      );
    } catch (e) {
      if (e is CommandeServiceException) rethrow;
      throw CommandeServiceException(
        message: 'Une erreur inattendue est survenue: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Met à jour les menus d'une commande
  Future<UpdateCommandeMenusResponse> updateCommandeMenus(
    String commandeId,
    UpdateCommandeMenusRequest request,
  ) async {
    final token = await _sessionService.getAccessToken();
    if (token == null) {
      throw CommandeServiceException(
        message: 'Token d\'authentification manquant',
        statusCode: 401,
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/commande/$commandeId/menus');
    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 && response.statusCode != 201) {
        final message =
            responseData['message'] as String? ??
            'Erreur lors de la mise à jour des menus de la commande';
        throw CommandeServiceException(
          message: message,
          statusCode: response.statusCode,
        );
      }

      return UpdateCommandeMenusResponse.fromJson(responseData);
    } on http.ClientException catch (e) {
      throw CommandeServiceException(
        message: 'Erreur de connexion: ${e.message}',
        statusCode: 0,
      );
    } on FormatException {
      throw CommandeServiceException(
        message: 'Réponse invalide du serveur',
        statusCode: 0,
      );
    } catch (e) {
      if (e is CommandeServiceException) rethrow;
      throw CommandeServiceException(
        message: 'Une erreur inattendue est survenue: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Crée une commande à partir d'une réservation
  Future<CreateCommandeFromReservationResponse> createCommandeFromReservation(
    CreateCommandeFromReservationRequest request,
  ) async {
    final token = await _sessionService.getAccessToken();
    if (token == null) {
      throw CommandeServiceException(
        message: 'Token d\'authentification manquant',
        statusCode: 401,
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/commande/from-reservation');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 && response.statusCode != 201) {
        final message =
            responseData['message'] as String? ??
            'Erreur lors de la création de la commande à partir de la réservation';
        throw CommandeServiceException(
          message: message,
          statusCode: response.statusCode,
        );
      }

      return CreateCommandeFromReservationResponse.fromJson(responseData);
    } on http.ClientException catch (e) {
      throw CommandeServiceException(
        message: 'Erreur de connexion: ${e.message}',
        statusCode: 0,
      );
    } on FormatException {
      throw CommandeServiceException(
        message: 'Réponse invalide du serveur',
        statusCode: 0,
      );
    } catch (e) {
      if (e is CommandeServiceException) rethrow;
      throw CommandeServiceException(
        message: 'Une erreur inattendue est survenue: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}

/// Exception personnalisée pour les erreurs du service de commandes
class CommandeServiceException implements Exception {
  final String message;
  final int statusCode;

  CommandeServiceException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}
