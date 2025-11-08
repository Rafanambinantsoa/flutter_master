import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/table_available_request.dart';
import '../services/session_service.dart';
import '../models/table.dart';

/// Service pour gérer les tables disponibles
class TablesService {
  final SessionService _sessionService = SessionService();

  /// Arrondit une heure aux tranches de 30 minutes (12:00, 12:30, 13:00, etc.)
  ///
  /// [dateTime] : DateTime à arrondir
  ///
  /// Retourne une DateTime arrondie à la tranche de 30 minutes supérieure
  /// Exemples: 12:15 -> 12:30, 12:45 -> 13:00, 12:00 -> 12:00
  DateTime roundToNextHalfHour(DateTime dateTime) {
    final minutes = dateTime.minute;

    if (minutes == 0 || minutes == 30) {
      // Déjà sur une tranche de 30 minutes
      return dateTime;
    } else if (minutes < 30) {
      // Arrondir à 30 minutes de la même heure
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        30,
      );
    } else {
      // Arrondir à l'heure suivante (00 minutes)
      return DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour + 1,
        0,
      );
    }
  }

  /// Formate une DateTime en format de date "YYYY-MM-DD"
  String formatDate(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Formate une DateTime en format d'heure "HH:mm"
  String formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Calcule l'heure de fin (2h30 après l'heure de début)
  DateTime calculateHeureFin(DateTime heureDebut) {
    return heureDebut.add(const Duration(hours: 2, minutes: 30));
  }

  /// Récupère les tables disponibles pour une plage horaire
  ///
  /// [date] : Date de la réservation (DateTime)
  /// [heureDebut] : Heure de début (DateTime) - optionnel, utilise l'heure actuelle par défaut
  /// [heureFin] : Heure de fin (DateTime) - optionnel, calcule automatiquement (heureDebut + 2h30)
  ///
  /// Retourne [TablesDisponiblesResponse] en cas de succès
  /// Lance une [TablesServiceException] en cas d'échec
  Future<TablesDisponiblesResponse> getTablesDisponibles({
    DateTime? date,
    DateTime? heureDebut,
    DateTime? heureFin,
  }) async {
    try {
      // Utiliser l'heure actuelle par défaut si non fournie
      final now = DateTime.now();
      final dateToUse = date ?? now;

      // Arrondir l'heure de début à la tranche de 30 minutes suivante
      final heureDebutToUse = heureDebut ?? now;
      final heureDebutRounded = roundToNextHalfHour(heureDebutToUse);

      // Calculer l'heure de fin (2h30 après l'heure de début)
      // L'heure de fin doit aussi être arrondie aux tranches de 30 minutes
      final heureFinCalculated =
          heureFin ?? calculateHeureFin(heureDebutRounded);
      final heureFinRounded = roundToNextHalfHour(heureFinCalculated);

      // Formater les dates et heures
      final dateStr = formatDate(dateToUse);
      final heureDebutStr = formatTime(heureDebutRounded);
      final heureFinStr = formatTime(heureFinRounded);

      // Créer la requête
      final request = TablesDisponiblesRequest(
        date: dateStr,
        heureDebut: heureDebutStr,
        heureFin: heureFinStr,
      );

      // Récupérer le token d'authentification
      final token = await _sessionService.getAccessToken();
      if (token == null) {
        throw TablesServiceException(
          message: 'Token d\'authentification manquant',
          statusCode: 401,
        );
      }

      // Appel API
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/reservation/tables-disponibles',
      );

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Succès
        return TablesDisponiblesResponse.fromJson(responseData);
      } else {
        // Erreur
        final message =
            responseData['message'] as String? ??
            'Erreur lors de la récupération des tables';
        throw TablesServiceException(
          message: message,
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw TablesServiceException(
        message: 'Erreur de connexion: ${e.message}',
        statusCode: 0,
      );
    } on FormatException {
      throw TablesServiceException(
        message: 'Réponse invalide du serveur',
        statusCode: 0,
      );
    } catch (e) {
      if (e is TablesServiceException) {
        rethrow;
      }
      throw TablesServiceException(
        message: 'Une erreur inattendue est survenue: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Convertit une TableDisponible en DiningTable
  DiningTable convertToDiningTable(TableDisponible tableDisponible) {
    // Extraire le numéro de table depuis numero_table
    // Supporte différents formats: "Table 1", "Table1", "1", etc.
    int number;
    final numeroTable = tableDisponible.numeroTable.trim();

    // Essayer d'extraire le numéro
    final regex = RegExp(r'\d+');
    final match = regex.firstMatch(numeroTable);

    if (match != null) {
      number = int.parse(match.group(0)!);
    } else {
      // Si pas de numéro trouvé, utiliser l'ID
      number = tableDisponible.id;
    }

    // Capacité par défaut (peut être ajustée selon vos besoins)
    // Vous pouvez modifier cette logique si vous recevez la capacité depuis l'API
    final capacity = number % 4 == 0 ? 6 : 4;

    return DiningTable(
      id: 't${tableDisponible.id}',
      number: number,
      capacity: capacity,
    );
  }
}

/// Exception personnalisée pour les erreurs du service de tables
class TablesServiceException implements Exception {
  final String message;
  final int statusCode;

  TablesServiceException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}
