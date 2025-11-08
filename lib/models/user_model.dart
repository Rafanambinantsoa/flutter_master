/// Modèle pour le rôle utilisateur
class Role {
  final int id;
  final String nom;
  final String description;
  final String couleur;

  Role({
    required this.id,
    required this.nom,
    required this.description,
    required this.couleur,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      nom: json['nom'] as String,
      description: json['description'] as String,
      couleur: json['couleur'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'couleur': couleur,
    };
  }
}

/// Modèle pour l'utilisateur
class User {
  final int id;
  final String nom;
  final String email;
  final bool statut;
  final int roleId;
  final Role role;
  final List<dynamic> userTypeMenus;

  User({
    required this.id,
    required this.nom,
    required this.email,
    required this.statut,
    required this.roleId,
    required this.role,
    required this.userTypeMenus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      nom: json['nom'] as String,
      email: json['email'] as String,
      statut: json['statut'] as bool,
      roleId: json['role_id'] as int,
      role: Role.fromJson(json['role'] as Map<String, dynamic>),
      userTypeMenus: json['userTypeMenus'] as List<dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'statut': statut,
      'role_id': roleId,
      'role': role.toJson(),
      'userTypeMenus': userTypeMenus,
    };
  }
}

/// Modèle pour la réponse de login réussie
class LoginResponse {
  final String message;
  final User user;
  final String accessToken;

  LoginResponse({
    required this.message,
    required this.user,
    required this.accessToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user': user.toJson(),
      'access_token': accessToken,
    };
  }
}

/// Modèle pour la réponse d'erreur de login
class LoginErrorResponse {
  final String message;
  final String error;
  final int statusCode;

  LoginErrorResponse({
    required this.message,
    required this.error,
    required this.statusCode,
  });

  factory LoginErrorResponse.fromJson(Map<String, dynamic> json) {
    return LoginErrorResponse(
      message: json['message'] as String,
      error: json['error'] as String,
      statusCode: json['statusCode'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'error': error, 'statusCode': statusCode};
  }
}

