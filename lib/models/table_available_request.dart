/// Modèle pour la requête de tables disponibles
class TablesDisponiblesRequest {
  final String date; // Format: "2025-01-22"
  final String heureDebut; // Format: "12:00"
  final String heureFin; // Format: "14:00"

  TablesDisponiblesRequest({
    required this.date,
    required this.heureDebut,
    required this.heureFin,
  });

  Map<String, dynamic> toJson() {
    return {'date': date, 'heureDebut': heureDebut, 'heureFin': heureFin};
  }
}

/// Modèle pour une table disponible dans la réponse
class TableDisponible {
  final int id;
  final String numeroTable;
  final List<dynamic> reservationTables;

  TableDisponible({
    required this.id,
    required this.numeroTable,
    required this.reservationTables,
  });

  factory TableDisponible.fromJson(Map<String, dynamic> json) {
    return TableDisponible(
      id: json['id'] as int,
      numeroTable: json['numero_table'] as String,
      reservationTables: json['reservationTables'] as List<dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_table': numeroTable,
      'reservationTables': reservationTables,
    };
  }
}

/// Modèle pour la réponse de tables disponibles
class TablesDisponiblesResponse {
  final String date;
  final String heureDebut;
  final String heureFin;
  final List<TableDisponible> disponibles;
  final int total;

  TablesDisponiblesResponse({
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    required this.disponibles,
    required this.total,
  });

  factory TablesDisponiblesResponse.fromJson(Map<String, dynamic> json) {
    return TablesDisponiblesResponse(
      date: json['date'] as String,
      heureDebut: json['heureDebut'] as String,
      heureFin: json['heureFin'] as String,
      disponibles: (json['disponibles'] as List<dynamic>)
          .map((item) => TableDisponible.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'heureDebut': heureDebut,
      'heureFin': heureFin,
      'disponibles': disponibles.map((t) => t.toJson()).toList(),
      'total': total,
    };
  }
}
