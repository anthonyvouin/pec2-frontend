import 'package:firstflutterapp/interfaces/user.dart';
import 'package:firstflutterapp/services/api_service.dart';

class UserSearchService {
  final ApiService _apiService = ApiService();

  // Rechercher des utilisateurs par nom d'utilisateur
  Future<List<User>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final response = await _apiService.request(
        method: 'GET',
        endpoint: '/users',
        withAuth: true,
        queryParams: {
          'search': query,
        },
      );

      if (response.success) {
        if (response.data is List) {
          return (response.data as List)
              .map((userData) => User.fromJson(userData))
              .toList();
        }
        
        // Cas où il n'y a pas de résultats
        return [];
      }

      throw Exception('Échec de la recherche d\'utilisateurs: ${response.error}');
    } catch (e) {
      print('Erreur lors de la recherche d\'utilisateurs: $e');
      throw Exception('Erreur lors de la recherche d\'utilisateurs: $e');
    }
  }

  // Obtenir un utilisateur par son nom d'utilisateur
  Future<User> getUserByUsername(String username) async {
    try {
      final response = await _apiService.request(
        method: 'GET',
        endpoint: '/users/$username',
        withAuth: true,
      );

      if (response.success) {
        return User.fromJson(response.data);
      }

      throw Exception('Utilisateur non trouvé: ${response.error}');
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }
}
