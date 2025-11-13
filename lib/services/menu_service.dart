import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/menu_item.dart';
import '../services/session_service.dart';

class MenuService {
  final SessionService _sessionService = SessionService();

  Future<List<MenuItemModel>> getMenus() async {
    final token = await _sessionService.getAccessToken();
    if (token == null) {
      throw MenuServiceException(
        message: 'Token d\'authentification manquant',
        statusCode: 401,
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/menu');
    try {
      final response = await http
          .get(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(Duration(seconds: ApiConfig.requestTimeout));

      if (response.statusCode != 200) {
        throw MenuServiceException(
          message: 'Erreur lors de la récupération du menu',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((e) => _fromApiJson(e as Map<String, dynamic>)).toList();
    } on http.ClientException catch (e) {
      throw MenuServiceException(
        message: 'Erreur de connexion: ${e.message}',
        statusCode: 0,
      );
    } on FormatException {
      throw MenuServiceException(
        message: 'Réponse invalide du serveur',
        statusCode: 0,
      );
    } catch (e) {
      if (e is MenuServiceException) rethrow;
      throw MenuServiceException(
        message: 'Une erreur inattendue est survenue: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  MenuItemModel _fromApiJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    final name = (json['nom'] ?? '').toString();
    final description = json['description']?.toString();

    // Map type_menu.nom vers temperature/category
    final typeMenu = (json['type_menu'] as Map<String, dynamic>?) ?? {};
    final typeName = (typeMenu['nom'] ?? '').toString().toLowerCase();

    // Temperature
    final temperature = switch (typeName) {
      'froid' => MenuTemperature.cold,
      _ => MenuTemperature.hot,
    };

    // Category: 'dessert' -> dessert, sinon dish par défaut (s'il y a une catégorie Boisson plus tard, on pourra l'ajouter)
    final category = switch (typeName) {
      'dessert' => MenuCategory.dessert,
      _ => MenuCategory.dish,
    };

    // Prix: lire le champ 'prix' de l'API (peut être un num ou une string)
    double price = 0.0;
    final prixValue = json['prix'];
    if (prixValue != null) {
      if (prixValue is num) {
        price = prixValue.toDouble();
      } else if (prixValue is String) {
        price = double.tryParse(prixValue) ?? 0.0;
      }
    }

    // Image: privilégier imageUrl si complet, sinon construire depuis image
    final imageUrl = _resolveImageUrl(
      json['imageUrl'] as String?,
      json['image'] as String?,
    );

    return MenuItemModel(
      id: id,
      name: name,
      category: category,
      price: price,
      imageUrl: imageUrl,
      description: description,
      temperature: temperature,
    );
  }

  String? _resolveImageUrl(String? directUrl, String? imagePath) {
    final base = ApiConfig.baseUrl;

    // Priorité au champ image (fichier) si présent
    if (imagePath != null && imagePath.isNotEmpty) {
      return _joinBaseWithPath(base, '/uploads/menu/$imagePath');
    }

    if (directUrl == null || directUrl.isEmpty) return null;

    final uri = Uri.tryParse(directUrl);
    if (uri == null) {
      return _joinBaseWithPath(base, directUrl);
    }

    if (uri.hasScheme && uri.host.isNotEmpty) {
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        return _joinBaseWithPath(base, uri.path);
      }
      return directUrl;
    }

    return _joinBaseWithPath(base, uri.toString());
  }

  String _joinBaseWithPath(String base, String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final normalizedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedBase$normalizedPath';
  }
}

class MenuServiceException implements Exception {
  final String message;
  final int statusCode;
  MenuServiceException({required this.message, required this.statusCode});
  @override
  String toString() => message;
}
