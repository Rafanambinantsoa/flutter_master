/// Modèle détaillé pour une réservation retournée par l'API
class ReservationDetail {
  final int id;
  final int? clientId;
  final DateTime date;
  final String heureDebut;
  final String heureFin;
  final String status;
  final String typeReservation;
  final ReservationClient? client;
  final List<ReservationTable> reservationTables;
  final List<ReservationMenuDetail> reservationMenus;
  final PaymentReservationTable? paymentReservationTable;
  final String code;
  final DateTime createdAt;

  ReservationDetail({
    required this.id,
    this.clientId,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    required this.status,
    required this.typeReservation,
    this.client,
    required this.reservationTables,
    required this.reservationMenus,
    this.paymentReservationTable,
    required this.code,
    required this.createdAt,
  });

  factory ReservationDetail.fromJson(Map<String, dynamic> json) {
    return ReservationDetail(
      id: json['id'] as int,
      clientId: json['client_id'] as int?,
      date: DateTime.parse(json['date'] as String),
      heureDebut: json['heure_debut'] as String,
      heureFin: json['heure_fin'] as String,
      status: json['status'] as String,
      typeReservation: json['type_reservation'] as String,
      client: json['client'] != null
          ? ReservationClient.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      reservationTables:
          (json['reservationTables'] as List<dynamic>?)
              ?.map((e) => ReservationTable.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reservationMenus:
          (json['reservationMenus'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ReservationMenuDetail.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      paymentReservationTable: json['paimentReservationTable'] != null
          ? PaymentReservationTable.fromJson(
              json['paimentReservationTable'] as Map<String, dynamic>,
            )
          : null,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Modèle pour le client dans une réservation
class ReservationClient {
  final int id;
  final String nom;
  final String email;
  final String? telephone;
  final String? adresse;

  ReservationClient({
    required this.id,
    required this.nom,
    required this.email,
    this.telephone,
    this.adresse,
  });

  factory ReservationClient.fromJson(Map<String, dynamic> json) {
    return ReservationClient(
      id: json['id'] as int,
      nom: json['nom'] as String,
      email: json['email'] as String,
      telephone: json['telephone'] as String?,
      adresse: json['adresse'] as String?,
    );
  }
}

/// Modèle pour une table dans une réservation
class ReservationTable {
  final int id;
  final ReservationTableInfo table;

  ReservationTable({required this.id, required this.table});

  factory ReservationTable.fromJson(Map<String, dynamic> json) {
    return ReservationTable(
      id: json['id'] as int,
      table: ReservationTableInfo.fromJson(
        json['table'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Modèle pour les informations d'une table
class ReservationTableInfo {
  final int id;
  final String numeroTable;

  ReservationTableInfo({required this.id, required this.numeroTable});

  factory ReservationTableInfo.fromJson(Map<String, dynamic> json) {
    return ReservationTableInfo(
      id: json['id'] as int,
      numeroTable: json['numero_table'] as String,
    );
  }
}

/// Modèle détaillé pour un menu dans une réservation
class ReservationMenuDetail {
  final int id;
  final ReservationMenuInfo menu;
  final int quantity;

  ReservationMenuDetail({
    required this.id,
    required this.menu,
    required this.quantity,
  });

  factory ReservationMenuDetail.fromJson(Map<String, dynamic> json) {
    return ReservationMenuDetail(
      id: json['id'] as int,
      menu: ReservationMenuInfo.fromJson(json['menu'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }
}

/// Modèle pour les informations d'un menu
class ReservationMenuInfo {
  final int id;
  final String nom;
  final String? description;
  final bool statut;
  final String? image;
  final String prix;
  final int typeMenuId;
  final Map<String, dynamic> typeMenu;
  final List<ReservationMenuQuantity> reservationMenus;
  final List<CommandeMenuDetail> commandeMenus;

  ReservationMenuInfo({
    required this.id,
    required this.nom,
    this.description,
    required this.statut,
    this.image,
    required this.prix,
    required this.typeMenuId,
    required this.typeMenu,
    required this.reservationMenus,
    required this.commandeMenus,
  });

  factory ReservationMenuInfo.fromJson(Map<String, dynamic> json) {
    return ReservationMenuInfo(
      id: json['id'] as int,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      statut: json['statut'] as bool? ?? false,
      image: json['image'] as String?,
      prix: json['prix'] as String,
      typeMenuId: json['type_menu_id'] as int,
      typeMenu: json['type_menu'] as Map<String, dynamic>,
      reservationMenus:
          (json['reservationMenus'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ReservationMenuQuantity.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      commandeMenus:
          (json['commandeMenus'] as List<dynamic>?)
              ?.map(
                (e) => CommandeMenuDetail.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

/// Modèle pour la quantité d'un menu dans une réservation
class ReservationMenuQuantity {
  final int id;
  final int quantity;

  ReservationMenuQuantity({required this.id, required this.quantity});

  factory ReservationMenuQuantity.fromJson(Map<String, dynamic> json) {
    return ReservationMenuQuantity(
      id: json['id'] as int,
      quantity: json['quantity'] as int,
    );
  }
}

/// Modèle pour une commande de menu
class CommandeMenuDetail {
  final int id;
  final int commandeId;
  final int menuId;
  final String status;
  final int quantity;
  final DateTime createdAt;

  CommandeMenuDetail({
    required this.id,
    required this.commandeId,
    required this.menuId,
    required this.status,
    required this.quantity,
    required this.createdAt,
  });

  factory CommandeMenuDetail.fromJson(Map<String, dynamic> json) {
    return CommandeMenuDetail(
      id: json['id'] as int,
      commandeId: json['commande_id'] as int,
      menuId: json['menuId'] as int,
      status: json['status'] as String,
      quantity: json['quantity'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Modèle pour le paiement d'une réservation
class PaymentReservationTable {
  final int id;
  final int reservationId;
  final String typePaiment;
  final String? reference;
  final String? stripePaymentIntentId;
  final num montant;

  PaymentReservationTable({
    required this.id,
    required this.reservationId,
    required this.typePaiment,
    this.reference,
    this.stripePaymentIntentId,
    required this.montant,
  });

  factory PaymentReservationTable.fromJson(Map<String, dynamic> json) {
    return PaymentReservationTable(
      id: json['id'] as int,
      reservationId: json['reservation_id'] as int,
      typePaiment: json['type_paiment'] as String,
      reference: json['reference'] as String?,
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      montant: json['montant'] as num,
    );
  }
}
