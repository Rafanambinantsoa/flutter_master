/// Modèle pour un client (dans le contexte d'une commande)
class CommandeClient {
  final int id;
  final String nom;
  final String email;
  final String? telephone;
  final String? adresse;

  CommandeClient({
    required this.id,
    required this.nom,
    required this.email,
    this.telephone,
    this.adresse,
  });

  factory CommandeClient.fromJson(Map<String, dynamic> json) {
    return CommandeClient(
      id: json['id'] as int,
      nom: json['nom'] as String,
      email: json['email'] as String,
      telephone: json['telephone'] as String?,
      adresse: json['adresse'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
    };
  }
}

/// Modèle pour un menu dans une commande
class CommandeMenuInfo {
  final int id;
  final String nom;
  final String? description;
  final bool statut;
  final String? image;
  final String prix;
  final int typeMenuId;
  final Map<String, dynamic> typeMenu;

  CommandeMenuInfo({
    required this.id,
    required this.nom,
    this.description,
    required this.statut,
    this.image,
    required this.prix,
    required this.typeMenuId,
    required this.typeMenu,
  });

  factory CommandeMenuInfo.fromJson(Map<String, dynamic> json) {
    return CommandeMenuInfo(
      id: json['id'] as int,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      statut: json['statut'] as bool? ?? false,
      image: json['image'] as String?,
      prix: json['prix'] as String,
      typeMenuId: json['type_menu_id'] as int,
      typeMenu: json['type_menu'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'statut': statut,
      'image': image,
      'prix': prix,
      'type_menu_id': typeMenuId,
      'type_menu': typeMenu,
    };
  }
}

/// Modèle pour un élément de menu dans une commande
class CommandeMenu {
  final int id;
  final int commandeId;
  final int menuId;
  final String status;
  final CommandeMenuInfo menu;
  final int quantity;

  CommandeMenu({
    required this.id,
    required this.commandeId,
    required this.menuId,
    required this.status,
    required this.menu,
    required this.quantity,
  });

  factory CommandeMenu.fromJson(Map<String, dynamic> json) {
    return CommandeMenu(
      id: json['id'] as int,
      commandeId: json['commande_id'] as int,
      menuId: json['menuId'] as int,
      status: json['status'] as String? ?? 'en_attente',
      menu: CommandeMenuInfo.fromJson(json['menu'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commande_id': commandeId,
      'menuId': menuId,
      'status': status,
      'menu': menu.toJson(),
      'quantity': quantity,
    };
  }
}

/// Modèle pour une réservation dans le contexte d'une commande
class CommandeReservation {
  final int id;
  final int? clientId;
  final DateTime date;
  final String heureDebut;
  final String heureFin;
  final String status;
  final String typeReservation;
  final CommandeClient? client;
  final List<Map<String, dynamic>> reservationTables;
  final List<dynamic> reservationMenus;

  CommandeReservation({
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
  });

  factory CommandeReservation.fromJson(Map<String, dynamic> json) {
    return CommandeReservation(
      id: json['id'] as int,
      clientId: json['client_id'] as int?,
      date: DateTime.parse(json['date'] as String),
      heureDebut: json['heure_debut'] as String,
      heureFin: json['heure_fin'] as String,
      status: json['status'] as String,
      typeReservation: json['type_reservation'] as String,
      client: json['client'] != null
          ? CommandeClient.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      reservationTables:
          (json['reservationTables'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      reservationMenus: json['reservationMenus'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'date': date.toIso8601String(),
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
      'status': status,
      'type_reservation': typeReservation,
      'client': client?.toJson(),
      'reservationTables': reservationTables,
      'reservationMenus': reservationMenus,
    };
  }
}

/// Statut d'une commande
enum CommandeStatus {
  enCours('en_cours'),
  enAttente('en_attente'),
  terminee('terminee'),
  annulee('annulee');

  final String value;
  const CommandeStatus(this.value);

  static CommandeStatus fromString(String value) {
    return CommandeStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CommandeStatus.enAttente,
    );
  }
}

/// Modèle pour une commande
class Commande {
  final int id;
  final String reference;
  final int? reservationId;
  final CommandeReservation? reservation;
  final List<CommandeMenu> commandeMenu;
  final DateTime dateCommande;
  final CommandeStatus status;
  final double totalPrice;

  Commande({
    required this.id,
    required this.reference,
    this.reservationId,
    this.reservation,
    required this.commandeMenu,
    required this.dateCommande,
    required this.status,
    required this.totalPrice,
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json['id'] as int,
      reference: json['reference'] as String,
      reservationId: json['reservation_id'] as int?,
      reservation: json['reservation'] != null
          ? CommandeReservation.fromJson(
              json['reservation'] as Map<String, dynamic>,
            )
          : null,
      commandeMenu:
          (json['commandeMenu'] as List<dynamic>?)
              ?.map((e) => CommandeMenu.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dateCommande: DateTime.parse(json['date_commande'] as String),
      status: CommandeStatus.fromString(json['status'] as String),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'reservation_id': reservationId,
      'reservation': reservation?.toJson(),
      'commandeMenu': commandeMenu.map((e) => e.toJson()).toList(),
      'date_commande': dateCommande.toIso8601String(),
      'status': status.value,
      'total_price': totalPrice,
    };
  }
}

/// Modèle pour créer une commande (POST request)
class CreateCommandeRequest {
  final int reservationId;
  final DateTime dateCommande;
  final String nom;
  final String email;
  final String? telephone;
  final String? adresse;
  final String dateReservation; // Format: "YYYY-MM-DD"
  final String heureDebut; // Format: "HH:mm"
  final String heureFin; // Format: "HH:mm"
  final List<int> tablesIds;
  final List<int> menuIds;
  final List<int> quantities;

  CreateCommandeRequest({
    required this.reservationId,
    required this.dateCommande,
    required this.nom,
    required this.email,
    this.telephone,
    this.adresse,
    required this.dateReservation,
    required this.heureDebut,
    required this.heureFin,
    required this.tablesIds,
    required this.menuIds,
    required this.quantities,
  });

  Map<String, dynamic> toJson() {
    return {
      'reservation_id': reservationId,
      'date_commande': dateCommande.toIso8601String(),
      'nom': nom,
      'email': email,
      if (telephone != null) 'telephone': telephone,
      if (adresse != null) 'adresse': adresse,
      'date_reservation': dateReservation,
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
      'tablesIds': tablesIds,
      'menuIds': menuIds,
      'quantities': quantities,
    };
  }
}

/// Modèle pour la réponse de création de commande (POST response)
class CreateCommandeResponse {
  final String message;
  final Commande commande;

  CreateCommandeResponse({required this.message, required this.commande});

  factory CreateCommandeResponse.fromJson(Map<String, dynamic> json) {
    return CreateCommandeResponse(
      message: json['message'] as String,
      commande: Commande.fromJson(json['commande'] as Map<String, dynamic>),
    );
  }
}

/// Modèle pour mettre à jour les menus d'une commande (PUT request)
class UpdateCommandeMenusRequest {
  final List<int> menuIds;
  final List<int> quantities;

  UpdateCommandeMenusRequest({required this.menuIds, required this.quantities});

  Map<String, dynamic> toJson() {
    return {'menuIds': menuIds, 'quantities': quantities};
  }
}

/// Modèle pour la réponse de mise à jour des menus (PUT response)
class UpdateCommandeMenusResponse {
  final String message;
  final Commande commande;

  UpdateCommandeMenusResponse({required this.message, required this.commande});

  factory UpdateCommandeMenusResponse.fromJson(Map<String, dynamic> json) {
    return UpdateCommandeMenusResponse(
      message: json['message'] as String,
      commande: Commande.fromJson(json['commande'] as Map<String, dynamic>),
    );
  }
}
