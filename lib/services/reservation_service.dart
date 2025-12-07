import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/reservation_detail.dart';
import '../services/session_service.dart';

/// Service pour gérer les réservations
class ReservationService {
  final SessionService _sessionService = SessionService();

  /// Recherche une réservation par son code
  ///
  /// [code] : Code de réservation à rechercher
  ///
  /// Retourne [ReservationDetail] en cas de succès
  /// Lance une [ReservationServiceException] en cas d'erreur
  Future<ReservationDetail> searchByCode(String code) async {
    if (code.trim().isEmpty) {
      throw ReservationServiceException(
        message: 'Le code de réservation ne peut pas être vide',
        statusCode: 400,
      );
    }

    final token = await _sessionService.getAccessToken();
    if (token == null) {
      throw ReservationServiceException(
        message: 'Token d\'authentification manquant',
        statusCode: 401,
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/reservation/search/code/$code');
    try {
      final response = await http
          .get(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      final responseData = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      //log the response data

      if (response.statusCode == 200) {
        // Succès
        return ReservationDetail.fromJson(responseData);
      } else if (response.statusCode == 404) {
        // Réservation introuvable
        final message =
            responseData['message'] as String? ?? 'Réservation introuvable';
        throw ReservationServiceException(message: message, statusCode: 404);
      } else {
        // Autre erreur
        final message =
            responseData['message'] as String? ??
            'Erreur lors de la recherche de la réservation';
        throw ReservationServiceException(
          message: message,
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw ReservationServiceException(
        message: 'Erreur de connexion: ${e.message}',
        statusCode: 0,
      );
    } on FormatException {
      throw ReservationServiceException(
        message: 'Réponse invalide du serveur',
        statusCode: 0,
      );
    } catch (e) {
      //log the error
      print("Error: ${e.toString()}");
      if (e is ReservationServiceException) {
        rethrow;
      }
      throw ReservationServiceException(
        message: 'Une erreur inattendue est survenue: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}

/// Exception personnalisée pour les erreurs du service de réservations
class ReservationServiceException implements Exception {
  final String message;
  final int statusCode;

  ReservationServiceException({
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => message;
}
