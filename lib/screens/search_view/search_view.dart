import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/interfaces/category.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/components/posts_feed_view_base.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
import 'package:provider/provider.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends PostsFeedViewBase<SearchView> {  @override
  String get viewTitle => 'Découvrir';

  @override
  Color get badgeColor => Colors.transparent;

  @override
  String get badgeText => '';

  @override
  String get emptyStateTitle => 'Aucun post disponible';

  @override
  String get emptyCategoryStateTitle => 'Aucun post dans cette catégorie';

  @override
  String get emptyStateMessage => 'Aucun post disponible pour le moment';

  @override
  String get emptyCategoryStateMessage => 'Essayez une autre catégorie';

  @override
  IconData get emptyStateIcon => Icons.search_off;

  @override
  List<Widget> getHeaderWidgets() => [_buildSearchBar()];

  @override
  void onSearch() {
    print('Recherche avec le terme: ${searchController.text}');

    // Déconnexion des SSE
    final sseProvider = Provider.of<SSEProvider>(context, listen: false);
    sseProvider.disconnectAll();
    print('Disconnected all SSE connections before search');

    // Effacer les posts d'abord
    setState(() {
      posts = [];
      isLoading = true;
    });

    // Utiliser searchQuery seulement s'il n'est pas vide
    final String? searchQuery =
        searchController.text.trim().isNotEmpty
            ? searchController.text.trim()
            : null;

    if (searchQuery == null) {
      // Si la recherche est vide, charger les posts avec le filtre de catégorie
      loadPosts(categoryId: selectedCategoryId);
      return;
    }

    // Recherche avec les deux filtres
    loadPosts(categoryId: selectedCategoryId, searchQuery: searchQuery);
  }

  @override
  Future<void> loadPosts({String? categoryId, String? searchQuery}) async {
    print('loadPosts called with categoryId: $categoryId, searchQuery: $searchQuery');

    // Mettre à jour l'état immédiatement
    setState(() {
      // Effacer les posts pour éviter d'afficher des données obsolètes
      posts = [];
      isLoading = true;
      isError = false;
      errorMessage = '';
    });

    try {
      final Map<String, String> queryParams = {
        'isFree': 'true',
      };
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categories'] = categoryId;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
        print('Adding search query: $searchQuery');
      }
  
      final response = await apiService.request(
        method: 'GET',
        endpoint: '/posts',
        withAuth: true,
        queryParams: queryParams,
      );
      
      if (!response.success) {
        print('API request failed: ${response.error}');
        setState(() {
          posts = [];
          isLoading = false;
          isError = true;
          errorMessage = response.error ?? 'Erreur lors du chargement des posts';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement des posts: ${response.error}'),
            ),
          );
        }
        return;
      }

      // Gestion de la structure de réponse avec pagination
      List<dynamic> data;
      if (response.data is Map && response.data.containsKey('posts')) {
        // Format avec pagination
        data = response.data['posts'] as List;
      } else if (response.data is List) {
        // Format sans pagination (directement une liste)
        data = response.data;
      } else {
        // Format inattendu, traiter comme une liste vide
        print('Format de réponse inattendu: ${response.data.runtimeType}');
        data = [];
      }
      
      setState(() {
        posts = data.map((post) => Post.fromJson(post)).toList();
        isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = 'Erreur lors du chargement des posts: $e';
        // En cas d'erreur, on vide la liste plutôt que d'afficher des données potentiellement incorrectes
        posts = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des posts: $e')),
        );
      }
    }
  }

  // Construire la barre de recherche
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const Icon(Icons.search),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => onSearch(),
              textInputAction: TextInputAction.search,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearch,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: buildContent(searchQuery: searchController.text.isNotEmpty ? searchController.text : null),
        ),
      ),
    );
  }
}
