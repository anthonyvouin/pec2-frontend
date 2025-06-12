import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/interfaces/category.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  bool _isLoading = false;
  List<Post> _posts = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadPosts();
  }

  @override
  void dispose() {
    // Pas besoin de déconnecter les SSE lors de la sortie de la vue
    // car notre implémentation globale gère automatiquement les connexions
    // Seuls les posts qui sont surveillés restent connectés
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ApiService apiService = ApiService();
      final response = await apiService.request(
        method: 'get',
        endpoint: '/categories',
        withAuth: true,
      );

      if (response.success) {
        setState(() {
          _categories =
              (response.data as List)
                  .map((item) => Category.fromJson(item))
                  .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des catégories: $e'),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }  Future<void> _loadPosts({String? categoryId, String? searchQuery}) async {
    print('_loadPosts called with categoryId: $categoryId, searchQuery: $searchQuery');
    
    // Ensure loading state is set and clear posts
    setState(() {
      // Clear posts immediately to avoid showing stale data
      _posts = [];
      _isLoading = true;
    });

    try {        
      final ApiService apiService = ApiService();
      // Directly use queryParams parameter of the request method
      final Map<String, String> queryParams = {};
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categories'] = categoryId;  // Modifié de 'category' à 'categories' pour correspondre au backend
        print('Adding category filter: $categoryId');
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
        print('Adding search query: $searchQuery');
      }
      
      // Log the complete URL for debugging
      final String baseUrl = apiService.baseUrl;
      final Uri uri = Uri.parse('$baseUrl/posts').replace(queryParameters: queryParams);
      print('Full API URL: $uri');
      
      print('Making API request to /posts with params: $queryParams');
      final response = await apiService.request(
        method: 'GET',
        endpoint: '/posts',
        withAuth: true,
        queryParams: queryParams,
      );
      print('API response received: ${response.success}, status code: ${response.statusCode}');
      if (response.success) {
        print('Response data type: ${response.data.runtimeType}');
      } else {
        print('API request failed with error: ${response.error}');
      }
      
      if (!response.success) {
        // Handle failed response but don't throw
        print('API request failed: ${response.error}');
        setState(() {
          _posts = [];
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors du chargement des posts: ${response.error}')),
          );
        }
        return;
      }
      
      print('Raw response data: ${response.data}');
      print('Response data type: ${response.data.runtimeType}');
        
      if (response.success) {
        // Gestion de la structure de réponse avec pagination
        List<dynamic> data;
        if (response.data is Map && response.data.containsKey('posts')) {
          // Format avec pagination
          print('Processing paginated response format');
          data = response.data['posts'] as List;

          // Vérifier si la liste des posts est vide
          if (data.isEmpty) {
            print('Aucun post trouvé pour la catégorie sélectionnée');
          } else {
            print('Found ${data.length} posts in paginated format');
          }
        } else if (response.data is List) {
          // Format sans pagination (directement une liste)
          print('Processing direct list response format');
          data = response.data;

          // Vérifier si la liste des posts est vide
          if (data.isEmpty) {
            print('Aucun post trouvé pour la catégorie sélectionnée');
          } else {
            print('Found ${data.length} posts in direct list format');
          }
        } else {
          // Format inattendu, traiter comme une liste vide
          print('Format de réponse inattendu: ${response.data.runtimeType}');
          print('Unexpected response data: ${response.data}');
          data = [];
        }        
          try {          setState(() {
            _posts = data.map((post) => Post.fromJson(post)).toList();
            _isLoading = false;
          });
          print('Posts loaded successfully: ${_posts.length} posts');
          
          // Nous ne connectons plus au SSE ici, mais uniquement quand la modal des commentaires est ouverte
          if (_posts.isNotEmpty && mounted) {
            print('SSE connections will be established only when comment modals are opened');
          } else {
            print('No posts to connect to SSE or widget not mounted');
          }
        } catch (e) {
          print('Error processing posts data: $e');
          if (mounted) {
            setState(() {
              _posts = [];
              _isLoading = false;
            });
          }
        }
      } else {
        // Gestion des erreurs de l'API
        print('Erreur de l\'API: ${response.error}');
        print('API error details: ${response.data}');
        setState(() {
          _posts = [];
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Erreur lors du chargement des posts: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _isLoading = false;
        // En cas d'erreur, on vide la liste plutôt que d'afficher des données potentiellement incorrectes
        _posts = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des posts: $e')),
        );
      }
    }
  }  void _onCategorySelected(String categoryId) {
    print('Catégorie sélectionnée: $categoryId');
    
    // Déconnexion des SSE avant de changer de catégorie
    if (mounted) {
      final sseProvider = Provider.of<SSEProvider>(context, listen: false);
      sseProvider.disconnectAll();
      print('Disconnected all SSE connections before category change');
    }
    
    // Clear any previous searches when changing categories
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _searchController.clear();
      });
    }
    
    setState(() {
      // Reset posts list immediately to avoid showing old data
      _posts = [];
      
      if (_selectedCategoryId == categoryId) {
        // Si la catégorie est déjà sélectionnée, on la désélectionne
        _selectedCategoryId = null;
        print('Désélection de la catégorie');
      } else {
        _selectedCategoryId = categoryId;
        print('Nouvelle catégorie sélectionnée: $_selectedCategoryId');
      }
      
      // Set _isLoading to true immediately to show loading state
      _isLoading = true;
    });

    // Chargement des posts sans délai avec le bon paramètre 'categories'
    _loadPosts(
      categoryId: _selectedCategoryId,
      searchQuery: null, // Clear search when changing categories
    );
  }
  
  void _onSearch() {
    print('Recherche avec le terme: ${_searchController.text}');
    
    // Déconnexion des SSE avant de lancer une recherche
    if (mounted) {
      final sseProvider = Provider.of<SSEProvider>(context, listen: false);
      sseProvider.disconnectAll();
      print('Disconnected all SSE connections before search');
    }
    
    // Clear posts first
    setState(() {
      _posts = [];
      _isLoading = true;
    });
    
    // Only use searchQuery if it's not empty
    final String? searchQuery = _searchController.text.trim().isNotEmpty 
        ? _searchController.text.trim() 
        : null;
    
    if (searchQuery == null) {
      // If search is empty, just load posts with category filter
      _loadPosts(categoryId: _selectedCategoryId);
      return;
    }
        
    // Search with both filters
    _loadPosts(
      categoryId: _selectedCategoryId,
      searchQuery: searchQuery,
    );
  }
  void _navigateToPostDetail(Post post) {
    print('Navigation vers le détail du post: ${post.id}');
    
    // Nous ne connectons plus au SSE ici, mais uniquement quand la modal des commentaires est ouverte
    if (mounted) {
      final sseProvider = Provider.of<SSEProvider>(context, listen: false);
      
      // Déconnecter toutes les anciennes connexions
      sseProvider.disconnectAll();
    }
    
    context.push('/post/${post.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Barre de recherche
              Container(
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: 8),                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Rechercher',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _onSearch(),
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _onSearch,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),              // Catégories horizontales
              SizedBox(
                height: 90, // Augmentation de la hauteur pour éviter le débordement
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected =
                                _selectedCategoryId == category.id;

                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap:
                                        () => _onCategorySelected(category.id),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? theme.primaryColor
                                                : Colors.grey.shade300,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child:
                                            category.image != null &&
                                                    category.image!.isNotEmpty
                                                ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  child: Image.network(
                                                    category.image!,
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                                : Text(
                                                  category.name
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    category.name,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),

              const SizedBox(height: 16),              // Grille de posts
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              _selectedCategoryId != null
                                  ? 'Chargement des posts pour cette catégorie...'
                                  : _searchController.text.isNotEmpty
                                      ? 'Recherche en cours...'
                                      : 'Chargement des posts...',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            if (_selectedCategoryId != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Catégorie ID: $_selectedCategoryId',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ),
                          ],
                        ),
                      )
                    : _buildPostsGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPostsGrid() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Pas de posts pour le moment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            if (_selectedCategoryId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Essayez une autre catégorie',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              )
            else if (_searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Essayez d\'autres mots-clés',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
            SizedBox(height: 24),
            if (_selectedCategoryId != null || _searchController.text.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategoryId = null;
                    _searchController.clear();
                    _isLoading = true;
                  });
                  _loadPosts();
                },
                icon: Icon(Icons.refresh),
                label: Text('Voir tous les posts'),
              ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {        final post = _posts[index];
        return GestureDetector(
          onTap: () => _navigateToPostDetail(post),
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image du post
                Image.network(post.pictureUrl, fit: BoxFit.cover),

                // Superposition sombre pour lisibilité
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                // Informations du post
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    post.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                // Indicateur si le post est gratuit ou payant
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: post.isFree ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.isFree ? 'Gratuit' : 'Payant',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
