import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/interfaces/category.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/components/posts_grid_view.dart';
import 'package:firstflutterapp/components/state_views.dart';
import 'package:provider/provider.dart';

abstract class PostsFeedViewBase<T extends StatefulWidget> extends State<T> {
  bool isLoading = false;
  bool isError = false;
  String errorMessage = '';
  List<Post> posts = [];
  List<Category> categories = [];
  String? selectedCategoryId;
  final ApiService apiService = ApiService();
  final TextEditingController searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    loadCategories();
    loadPosts();
  }
  
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String get viewTitle;

  Color get badgeColor;

  String get badgeText;

  String get emptyStateTitle;

  String get emptyCategoryStateTitle;

  String get emptyStateMessage;

  String get emptyCategoryStateMessage;
  IconData get emptyStateIcon;

  List<Widget> getHeaderWidgets() => [];
  
  void onSearch() {}
  
  Future<void> loadCategories() async {
    try {
      final response = await apiService.request(
        method: 'get',
        endpoint: '/categories',
        withAuth: true,
      );

      if (response.success && mounted) {
        setState(() {
          categories = (response.data as List)
              .map((item) => Category.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des catégories: $e');
      // On continue sans les catégories en cas d'erreur
    }
  }

  Future<void> loadPosts({String? categoryId, String? searchQuery});
  void onCategorySelected(String categoryId) {
    print('Catégorie sélectionnée: $categoryId');
    
    if (mounted) {
      final sseProvider = Provider.of<SSEProvider>(context, listen: false);
      sseProvider.disconnectAll();
    }

    if (searchController.text.isNotEmpty) {
      setState(() {
        searchController.clear();
      });
    }

    setState(() {
      posts = [];

      if (selectedCategoryId == categoryId) {
        // Si la catégorie est déjà sélectionnée, on la désélectionne
        selectedCategoryId = null;
        print('Désélection de la catégorie');
      } else {
        selectedCategoryId = categoryId;
        print('Nouvelle catégorie sélectionnée: $selectedCategoryId');
      }

      // Set isLoading to true immediately to show loading state
      isLoading = true;
    });
    
    // Charge les posts avec le filtre de catégorie
    loadPosts(categoryId: selectedCategoryId);
  }

  /// Vérifie si des posts ont été signalés et les retire de la liste
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Vérifier si des posts ont été reportés
    final sseProvider = Provider.of<SSEProvider>(context, listen: false);
    bool hasReportedPosts = false;
    
    // Vérifier tous les posts de la liste
    for (final post in List.from(posts)) {
      if (sseProvider.isPostReported(post.id)) {
        hasReportedPosts = true;
        break;
      }
    }
    
    // Si des posts ont été reportés, filtrer la liste
    if (hasReportedPosts) {
      setState(() {
        posts.removeWhere((p) => sseProvider.isPostReported(p.id));
      });
    }
  }

  /// Construit la vue complète selon l'état (chargement, erreur, vide, ou contenu)
  Widget buildContent({String? searchQuery}) {
    if (isLoading && categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isError) {
      return ErrorStateView(
        errorMessage: errorMessage,
        onRetry: () => loadPosts(
          categoryId: selectedCategoryId,
          searchQuery: searchQuery,
        ),
        onAlternativeAction: selectedCategoryId != null || searchQuery != null ? () {
          setState(() {
            selectedCategoryId = null;
            isLoading = true;
          });
          loadPosts();
        } : null,
        alternativeActionText: selectedCategoryId != null || searchQuery != null ? 'Voir tous les posts' : null,
      );
    }

    if (posts.isEmpty && !isLoading) {
      return EmptyStateView(
        title: searchQuery != null && searchQuery.isNotEmpty
            ? 'Aucun résultat pour "$searchQuery"'
            : selectedCategoryId != null
                ? emptyCategoryStateTitle
                : emptyStateTitle,
        message: searchQuery != null && searchQuery.isNotEmpty
            ? 'Essayez d\'autres mots-clés ou catégories'
            : selectedCategoryId != null
                ? emptyCategoryStateMessage
                : emptyStateMessage,
        icon: emptyStateIcon,
        onPrimaryAction: () => loadPosts(
          categoryId: selectedCategoryId,
          searchQuery: searchQuery,
        ),
        primaryActionText: 'Actualiser',
        onSecondaryAction: selectedCategoryId != null || (searchQuery != null && searchQuery.isNotEmpty) ? () {
          setState(() {
            selectedCategoryId = null;
            isLoading = true;
          });
          loadPosts();
        } : null,
        secondaryActionText: selectedCategoryId != null || (searchQuery != null && searchQuery.isNotEmpty) ? 'Voir tous les posts' : null,
      );
    }

    return PostsGridView(
      posts: posts,
      categories: categories,
      selectedCategoryId: selectedCategoryId,
      onCategorySelected: onCategorySelected,
      onRefresh: ({categoryId}) => loadPosts(
        categoryId: categoryId,
        searchQuery: searchQuery,
      ),
      isLoading: isLoading,
      title: viewTitle,
      badgeColor: badgeColor,
      badgeText: badgeText,
      headerWidgets: getHeaderWidgets(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SSEProvider>(
      builder: (context, sseProvider, child) {
        final postsToRemove = posts.where((post) => 
          sseProvider.isPostReported(post.id)).toList();
        
        if (postsToRemove.isNotEmpty) {
          Future.microtask(() {
            if (mounted) {
              setState(() {
                for (final post in postsToRemove) {
                  posts.removeWhere((p) => p.id == post.id);
                }
              });
            }
          });
        }
        
        return Scaffold(
          body: SafeArea(
            child: buildContent(),
          ),
        );
      },
    );
  }
}
