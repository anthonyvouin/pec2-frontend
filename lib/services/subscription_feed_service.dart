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

    try {
      final response = await _apiService.request(
        method: 'get',
        endpoint: '/posts',
        withAuth: true,
        queryParams: queryParams,
      );

      if (response.success) {
        
        if (response.data is Map) {
          if (response.data.containsKey('posts')) {
            final posts = response.data['posts'] as List;
          }
        } else if (response.data is List) {
          final posts = response.data as List;
        }
        
        var paginatedResponse = PaginatedResponse<Post>.fromJson(
          response.data,
          (post) => Post.fromJson(post),
        );

        return paginatedResponse;
      }

      throw Exception('Échec du chargement des posts d\'abonnement: ${response.error}');
    } catch (e) {
      print('SubscriptionFeedService: Exception lors du chargement des posts: $e');
      rethrow;
    }
  }
}
