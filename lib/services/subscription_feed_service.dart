import 'package:firstflutterapp/interfaces/paginated_response.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/services/api_service.dart';

class SubscriptionFeedService {
  final ApiService _apiService = ApiService();
  
  // Charger les posts payants des utilisateurs auxquels l'utilisateur est abonné
  Future<PaginatedResponse<Post>> loadSubscriptionPosts({
    int page = 1,
    int limit = 10,
    String? categoryId,
  }) async {
    // Construire les paramètres de requête pour obtenir uniquement les posts payants
    // auxquels l'utilisateur a accès via ses abonnements
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'isFree': 'false', // Ne récupérer que les posts payants
      'subscriptionFeed': 'true', // Paramètre pour indiquer que nous voulons les posts des abonnements
    };
    
    // Ajout du filtre par catégorie si spécifié
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParams['categories'] = categoryId;
    }

    print('SubscriptionFeedService: Chargement des posts d\'abonnement avec paramètres: $queryParams');

    final response = await _apiService.request(
      method: 'get',
      endpoint: '/posts',
      withAuth: true, // L'authentification est nécessaire pour accéder aux posts d'abonnement
      queryParams: queryParams,
    );

    if (response.success) {
      print('SubscriptionFeedService: Réponse reçue avec succès');
      print('SubscriptionFeedService: Type de données reçues: ${response.data.runtimeType}');
      
      // Log pour mieux comprendre la structure des données reçues
      if (response.data is Map) {
        print('SubscriptionFeedService: Structure de la réponse (Map): ${response.data.keys}');
        if (response.data.containsKey('posts')) {
          final posts = response.data['posts'] as List;
          print('SubscriptionFeedService: Nombre de posts reçus: ${posts.length}');
        }
      } else if (response.data is List) {
        final posts = response.data as List;
        print('SubscriptionFeedService: Nombre de posts reçus (liste directe): ${posts.length}');
      }
      return PaginatedResponse<Post>.fromJson(
        response.data,
        (post) => Post.fromJson(post),
      );
    }

    throw Exception('Échec du chargement des posts d\'abonnement: ${response.error}');
  }
}
