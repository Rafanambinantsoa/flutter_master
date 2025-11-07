import 'order.dart';

/// Type de réservation
enum ReservationType {
  standard, // Réservation standard (table uniquement)
  prepaidMenu, // Réservation avec menu prépayé
}

/// Modèle de réservation
class Reservation {
  final String id;
  final String code;
  final DateTime date;
  final DateTime heureDebut;
  final DateTime heureFin;
  final int nombrePersonnes;
  final ReservationType type;
  final String?
  tableId; // Table réservée (peut être null si pas encore assignée)
  final String? clientName;
  final String? clientPhone;

  /// Pour les réservations avec menu prépayé
  final List<OrderLine>? prepaidMenuItems;

  Reservation({
    required this.id,
    required this.code,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    required this.nombrePersonnes,
    required this.type,
    this.tableId,
    this.clientName,
    this.clientPhone,
    this.prepaidMenuItems,
  });

  /// Vérifie si la réservation est pour aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Vérifie si la réservation est en cours (entre heureDebut et heureFin)
  bool get isActive {
    final now = DateTime.now();
    return isToday &&
        now.isAfter(heureDebut.subtract(const Duration(minutes: 15))) &&
        now.isBefore(heureFin.add(const Duration(minutes: 15)));
  }
}
