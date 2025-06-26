import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/interfaces/category.dart';
import 'package:firstflutterapp/interfaces/user.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/user_search_service.dart';
import 'package:firstflutterapp/components/posts_feed_view_base.dart';
import 'package:firstflutterapp/components/search/user_search_result_item.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
import 'package:provider/provider.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends PostsFeedViewBase<SearchView> with SingleTickerProviderStateMixin {
  final UserSearchService _userSearchService = UserSearchService();
  List<User> _userSearchResults = [];
  bool _showUserResults = false;
  bool _isSearchingUsers = false;
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Ecouter les changements du champ de recherche pour déclencher la recherche
    searchController.addListener(_onSearchTextChanged);
    
    // Écouter le focus pour afficher/masquer les résultats
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _showUserResults) {
        _hideUserResults();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _searchFocusNode.dispose();
    // Supprimer le listener pour éviter les fuites de mémoire
    searchController.removeListener(_onSearchTextChanged);
    super.dispose();
  }
  
  void _onSearchTextChanged() {
    final query = searchController.text.trim();
    
    // Masquer les résultats si le champ est vide
    if (query.isEmpty) {
      _hideUserResults();
      return;
    }
    
    // Lancer la recherche après un court délai pour éviter des appels API trop fréquents
    Future.delayed(Duration(milliseconds: 300), () {
      // Vérifier si le texte est toujours le même après le délai
      if (query == searchController.text.trim() && query.isNotEmpty) {
        onSearch();
      }
    });
  }
  
  void _hideUserResults() {
    if (_showUserResults) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _showUserResults = false;
            _userSearchResults = [];
          });
        }
      });
    }
  }
  
  @override
  String get viewTitle => 'Découvrir';

  // Suppression des propriétés obsolètes
  // badgeColor et badgeText ne sont plus utilisés dans la classe parent

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
  void onSearch() async {
    print('Recherche avec le terme: ${searchController.text}');
    final searchQuery = searchController.text.trim();

    if (searchQuery.isEmpty) {
      _hideUserResults();
      return;
    }

    // Déconnexion des SSE
    final sseProvider = Provider.of<SSEProvider>(context, listen: false);
    sseProvider.disconnectAll();
    
    // Rechercher des utilisateurs uniquement
    setState(() {
      _isSearchingUsers = true;
      _userSearchResults = [];
    });
    
    try {
      final users = await _userSearchService.searchUsers(searchQuery);
      if (mounted) {
        setState(() {
          _userSearchResults = users;
          _showUserResults = true;
          _isSearchingUsers = false;
        });
        
        // Démarrer l'animation d'apparition
        if (_showUserResults) {
          _animationController.forward();
        }
        
        print('Trouvé ${users.length} utilisateurs pour la recherche: $searchQuery');
      }
    } catch (e) {
      print('Erreur lors de la recherche d\'utilisateurs: $e');
      if (mounted) {
        setState(() {
          _isSearchingUsers = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la recherche: $e'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
              behavior: SnackBarBehavior.floating,
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
          SnackBar(
            content: Text('Erreur lors du chargement des posts: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Construire la barre de recherche
  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Rechercher des utilisateurs',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                hintStyle: TextStyle(color: theme.hintColor),
              ),
              onSubmitted: (_) => onSearch(),
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          // Bouton pour effacer la recherche
          if (searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, size: 20, color: theme.hintColor),
              onPressed: () {
                searchController.clear();
                _hideUserResults();
                FocusScope.of(context).unfocus();
              },
            ),
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.primary),
            onPressed: onSearch,
          ),
        ],
      ),
    );
  }
  
  // Construire la liste des résultats de recherche d'utilisateurs
  Widget _buildUserSearchResults() {
    final theme = Theme.of(context);
    
    if (_isSearchingUsers) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      );
    }
    
    if (_userSearchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun utilisateur trouvé',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec titre et bouton de fermeture
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Résultats (${_userSearchResults.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20),
                onPressed: _hideUserResults,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                splashRadius: 20,
              ),
            ],
          ),
        ),
        
        const Divider(height: 2),
        
        // Liste des résultats
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _userSearchResults.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              return UserSearchResultItem(user: _userSearchResults[index]);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        // Masquer les résultats et le clavier lorsque l'utilisateur tape en dehors
        FocusScope.of(context).unfocus();
        _hideUserResults();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              children: [
                // Contenu principal (posts)
                Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: buildContent(searchQuery: null),
                    ),
                  ],
                ),
                
                // Résultats de recherche en overlay avec animation
                if (_showUserResults)
                  Positioned(
                    top: 70, // Juste en dessous de la barre de recherche
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.1),
                          end: Offset.zero,
                        ).animate(_animation),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                spreadRadius: 1,
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          constraints: BoxConstraints(maxHeight: 350),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Material(
                              color: Colors.transparent,
                              child: _buildUserSearchResults(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
