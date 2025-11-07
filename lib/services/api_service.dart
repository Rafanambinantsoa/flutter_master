import '../models/table.dart';
import '../models/reservation.dart';

/// Service API abstrait pour communiquer avec le backend
/// Cette interface peut être implémentée avec HTTP ou mockée pour les tests
abstract class ApiService {
  /// Trouve les tables disponibles pour une plage horaire donnée
  /// Retourne la liste des tables disponibles (non réservées et non occupées)
  Future<List<DiningTable>> findTablesDisponibles({
    required DateTime date,
    required DateTime heureDebut,
    required DateTime heureFin,
  });

  /// Récupère une réservation par son code
  Future<Reservation?> getReservationByCode(String code);

  /// Vérifie la disponibilité d'une table spécifique pour une plage horaire
  Future<bool> isTableAvailable({
    required String tableId,
    required DateTime date,
    required DateTime heureDebut,
    required DateTime heureFin,
  });

  /// Assigne une table à une réservation
  Future<void> assignTableToReservation({
    required String reservationId,
    required String tableId,
  });

  /// Crée une commande pour une réservation avec menu prépayé
  Future<String> createOrderFromPrepaidReservation(String reservationId);
}
