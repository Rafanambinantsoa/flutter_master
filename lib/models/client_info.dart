/// Modèle pour les informations d'un client sans réservation
class ClientInfo {
  final String nom;
  final String email;
  final String? telephone;
  final String? adresse;

  ClientInfo({
    required this.nom,
    required this.email,
    this.telephone,
    this.adresse,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
    };
  }

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      nom: json['nom'] as String,
      email: json['email'] as String,
      telephone: json['telephone'] as String?,
      adresse: json['adresse'] as String?,
    );
  }
}
