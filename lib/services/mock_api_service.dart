import 'api_service.dart';
import '../models/table.dart';
import '../models/reservation.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

/// Implémentation mockée du service API pour le développement
class MockApiService implements ApiService {
  final List<DiningTable> _allTables = List.generate(
    12,
    (i) => DiningTable(id: 't$i', number: i + 1, capacity: i % 4 == 0 ? 6 : 4),
  );

  // Stockage mock des réservations
  final Map<String, Reservation> _reservations = {};

  MockApiService() {
    // Initialiser quelques réservations de démonstration
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Réservation standard
    _reservations['RES001'] = Reservation(
      id: 'res1',
      code: 'RES001',
      date: today,
      heureDebut: today.add(Duration(hours: 12)), // 12h00
      heureFin: today.add(Duration(hours: 14)), // 14h00
      nombrePersonnes: 4,
      type: ReservationType.standard,
      tableId: 't3',
      clientName: 'Jean Dupont',
      clientPhone: '06 12 34 56 78',
    );

    // Réservation avec menu prépayé
    _reservations['RES002'] = Reservation(
      id: 'res2',
      code: 'RES002',
      date: today,
      heureDebut: today.add(Duration(hours: 19)), // 19h00
      heureFin: today.add(Duration(hours: 21)), // 21h00
      nombrePersonnes: 2,
      type: ReservationType.prepaidMenu,
      tableId: 't5',
      clientName: 'Marie Martin',
      clientPhone: '06 98 76 54 32',
      prepaidMenuItems: [
        OrderLine(
          item: const MenuItemModel(
            id: 'm1',
            name: 'Burger Classique',
            category: MenuCategory.dish,
            price: 9.5,
            temperature: MenuTemperature.hot,
          ),
          quantity: 2,
        ),
        OrderLine(
          item: const MenuItemModel(
            id: 'm3',
            name: 'Cola',
            category: MenuCategory.drink,
            price: 3.0,
            temperature: MenuTemperature.cold,
          ),
          quantity: 2,
        ),
      ],
    );

    // Autre réservation standard pour demain
    _reservations['RES003'] = Reservation(
      id: 'res3',
      code: 'RES003',
      date: today.add(const Duration(days: 1)),
      heureDebut: today.add(Duration(days: 1, hours: 19)),
      heureFin: today.add(Duration(days: 1, hours: 21)),
      nombrePersonnes: 6,
      type: ReservationType.standard,
      tableId: 't8',
      clientName: 'Pierre Durand',
      clientPhone: '06 11 22 33 44',
    );
  }

  @override
  Future<List<DiningTable>> findTablesDisponibles({
    required DateTime date,
    required DateTime heureDebut,
    required DateTime heureFin,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 300));

    // Filtrer les tables qui sont réservées dans cette plage horaire
    final reservedTableIds = _reservations.values
        .where((res) {
          final resDate = DateTime(res.date.year, res.date.month, res.date.day);
          final checkDate = DateTime(date.year, date.month, date.day);

          // Vérifier si c'est le même jour
          if (resDate.year != checkDate.year ||
              resDate.month != checkDate.month ||
              resDate.day != checkDate.day) {
            return false;
          }

          // Vérifier si les plages horaires se chevauchent
          return !(heureFin.isBefore(res.heureDebut) ||
              heureDebut.isAfter(res.heureFin));
        })
        .map((res) => res.tableId)
        .where((id) => id != null)
        .cast<String>()
        .toSet();

    // Retourner les tables non réservées
    return _allTables
        .where((table) => !reservedTableIds.contains(table.id))
        .toList();
  }

  @override
  Future<Reservation?> getReservationByCode(String code) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 300));

    final reservation = _reservations[code.toUpperCase()];

    // Vérifier si la réservation est valide (pour aujourd'hui ou proche)
    if (reservation != null && reservation.isActive) {
      return reservation;
    }

    return null;
  }

  @override
  Future<bool> isTableAvailable({
    required String tableId,
    required DateTime date,
    required DateTime heureDebut,
    required DateTime heureFin,
  }) async {
    final availableTables = await findTablesDisponibles(
      date: date,
      heureDebut: heureDebut,
      heureFin: heureFin,
    );
    return availableTables.any((table) => table.id == tableId);
  }

  @override
  Future<void> assignTableToReservation({
    required String reservationId,
    required String tableId,
  }) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 200));

    final reservation = _reservations.values.firstWhere(
      (res) => res.id == reservationId,
    );
    // Dans une vraie implémentation, on ferait un appel API
    // Ici on simule juste en mettant à jour le mock
    final updated = Reservation(
      id: reservation.id,
      code: reservation.code,
      date: reservation.date,
      heureDebut: reservation.heureDebut,
      heureFin: reservation.heureFin,
      nombrePersonnes: reservation.nombrePersonnes,
      type: reservation.type,
      tableId: tableId,
      clientName: reservation.clientName,
      clientPhone: reservation.clientPhone,
      prepaidMenuItems: reservation.prepaidMenuItems,
    );
    _reservations[reservation.code] = updated;
  }

  @override
  Future<String> createOrderFromPrepaidReservation(String reservationId) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 300));

    // Vérifier que la réservation existe
    _reservations.values.firstWhere((res) => res.id == reservationId);

    // Retourner un ID de commande simulé
    return 'order_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Méthode utilitaire pour obtenir toutes les tables (pour l'affichage)
  List<DiningTable> getAllTables() => _allTables;
}
