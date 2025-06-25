import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
import 'package:provider/provider.dart';
import 'package:firstflutterapp/components/comments/comments_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:firstflutterapp/services/user_preferences_helper.dart';
import 'package:firstflutterapp/components/post-card/report_bottom_sheet.dart';

class PostFullscreenView extends StatefulWidget {
  final String initialPostId;
  final List<Post> allPosts;

  const PostFullscreenView({
    super.key,
    required this.initialPostId,
    required this.allPosts,
  });

  @override
  State<PostFullscreenView> createState() => _PostFullscreenViewState();
}

class _PostFullscreenViewState extends State<PostFullscreenView> {
  late PageController _pageController;
  List<Post> _posts = [];
  int _currentIndex = 0;

  // Variable pour stocker une référence au Provider
  late SSEProvider _sseProvider;
  final UserPreferencesHelper _preferencesHelper = UserPreferencesHelper();
  bool _areCommentsEnabled = true;

  @override
  void initState() {
    super.initState();
    _posts = widget.allPosts;

    // Trouver l'index du post initial
    _currentIndex = _posts.indexWhere(
      (post) => post.id == widget.initialPostId,
    );
    if (_currentIndex == -1) {
      _currentIndex = 0; // Fallback à l'index 0 si le post n'est pas trouvé
    }

    // Initialiser le PageController à l'index du post initial
    _pageController = PageController(initialPage: _currentIndex);

    _loadCommentsPreference();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Stocker une référence au Provider que nous pourrons utiliser en toute sécurité dans dispose()
    _sseProvider = Provider.of<SSEProvider>(context, listen: false);

    // On va utiliser un Future.microtask pour éviter de faire des modifications d'état pendant le build
    Future.microtask(() {
      // Vérification de sécurité pour s'assurer que le widget est toujours monté
      if (mounted && _posts.isNotEmpty) {
        _connectToSSE(_posts[_currentIndex].id);
      }
    });
  }

  @override
  void dispose() {
    // Utiliser la référence stockée au lieu d'accéder au contexte dans dispose
    // Utiliser disconnectAllSilently pour éviter les problèmes avec notifyListeners pendant dispose
    _sseProvider.disconnectAllSilently();

    _pageController.dispose();
    super.dispose();
  }

  void _connectToSSE(String postId) {
    if (!mounted) return;

    try {
      // Stocker l'ID du post actuel pour vérifier si on est toujours sur le même post après le délai
      final currentPostId = postId;

      // Utiliser la référence stockée au lieu d'accéder au Provider chaque fois

      // Déconnecter d'abord toutes les anciennes connexions
      // Utiliser un Future.microtask pour s'assurer que cela ne se produit pas pendant le build
      Future.microtask(() {
        _sseProvider.disconnectAll();

        // Attendre un court instant avant de se reconnecter
        Future.delayed(const Duration(milliseconds: 100), () {
          // Vérifier si le widget est toujours monté et si on est toujours sur le même post
          if (mounted &&
              _posts.isNotEmpty &&
              _currentIndex < _posts.length &&
              _posts[_currentIndex].id == currentPostId) {
            // Connecter uniquement pour le post sélectionné
            debugPrint(
              'Setting up SSE connection for selected post: $currentPostId',
            );
            _sseProvider.connectToSSE(currentPostId);
          }
        });
      });
    } catch (e) {
      debugPrint('Erreur lors de la connexion SSE: $e');
    }
  }

  Future<void> _toggleLike(Post post) async {
    try {
      final ApiService apiService = ApiService();
      final response = await apiService.request(
        method: 'post',
        endpoint: '/posts/${post.id}/like',
        withAuth: true,
      );

      if (response.success) {
        setState(() {
          if (response.data['action'] == "added") {
            post.likesCount++;
          } else if (response.data['action'] == "removed") {
            post.likesCount--;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
  void _openCommentsModal(Post post) {
    if (!mounted) return;

    // Vérifier si les commentaires sont activés
    if (!_areCommentsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les commentaires sont désactivés dans vos préférences'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Utiliser la référence stockée au lieu d'accéder au Provider chaque fois
    _sseProvider.connectToSSE(post.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return CommentsModal(
              post: post,
              isConnected: true,
              postAuthorName: post.user.userName,
            );
          },
        );
      },
    );
  }

  void _openReportModal(Post post) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReportBottomSheet(
          postId: post.id,
          onPostReported: (postId) {
            setState(() {
              final currentIndex = _currentIndex;
              
              // Supprimer le post de la liste
              _posts.removeWhere((p) => p.id == postId);
              
              // Si c'était le dernier post ou si la liste est vide, fermer la vue
              if (_posts.isEmpty) {
                Navigator.of(context).pop();
                return;
              }
              
              if (_currentIndex >= _posts.length) {
                _currentIndex = _posts.length - 1;
              }
              
              if (currentIndex != _currentIndex && _pageController.hasClients) {
                _pageController.animateToPage(
                  _currentIndex,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            });
          },
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  Future<void> _loadCommentsPreference() async {
    try {
      final commentsEnabled = await _preferencesHelper.areCommentsEnabled();
      if (mounted) {
        setState(() {
          _areCommentsEnabled = commentsEnabled;
        });
      }
    } catch (e) {
      // En cas d'erreur, on suppose que les commentaires sont activés
      print('Erreur lors du chargement de la préférence commentaires: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      // Permet au contenu de s'étendre sous la barre d'applications
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // Appbar transparente
        elevation: 0,
        // Sans ombre
        title: const Text(
          'Publications',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Déconnexion silencieuse avant de naviguer
            _sseProvider.disconnectAllSilently();
            Navigator.pop(context);
          },
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        // Intercepte les notifications de défilement pour améliorer l'expérience
        onNotification: (ScrollNotification notification) {
          // Permet de manipuler les événements de défilement si nécessaire
          return false; // Retourne false pour laisser la notification se propager
        },
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: const ClampingScrollPhysics(),
          // Utiliser ClampingScrollPhysics pour un défilement plus naturel
          itemCount: _posts.length,
          onPageChanged: (index) {
            // Mettre à jour l'index courant
            setState(() {
              _currentIndex = index;
            });

            // Utiliser Future.microtask pour éviter de notifier pendant le build
            Future.microtask(() {
              if (mounted) {
                _connectToSSE(_posts[index].id);
              }
            });
          },
          itemBuilder: (context, index) {
            final post = _posts[index];
            return _buildFullscreenPost(post);
          },
        ),
      ),
    );
  }

  Widget _buildFullscreenPost(Post post) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image du post - maintenant avec fit: BoxFit.cover pour prendre tout l'écran
        InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            post.pictureUrl,
            fit: BoxFit.cover,
            // Modifié de contain à cover pour prendre tout l'écran
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                ),
              );
            },
            errorBuilder:
                (context, error, stackTrace) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 50),
                ),
          ),
        ),

        // Overlay noir en bas pour les informations
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations de l'auteur
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          post.user.profilePicture.isEmpty
                              ? const AssetImage('assets/images/panda.png')
                                  as ImageProvider
                              : NetworkImage(post.user.profilePicture),
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // Navigation vers le profil de l'utilisateur
                        context.go('/profile/${post.user.userName}');
                      },
                      child: Text(
                        post.user.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration:                              TextDecoration
                                  .underline, // Indication visuelle que c'est cliquable
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                // Titre et description
                Text(
                  post.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (post.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      post.description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),

                Row(
                  children: [
                    Text(
                      _getFormattedDate(post.createdAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Actions (like, commentaire)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                      ),
                      onPressed: () => _toggleLike(post),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),                    const SizedBox(width: 4),                    Text(
                      post.likesCount.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (_areCommentsEnabled) ...[
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white,
                        ),
                        onPressed: () => _openCommentsModal(post),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      Consumer<SSEProvider>(
                        builder: (context, sseProvider, _) {
                          // Obtenir le nombre de commentaires avec une gestion plus défensive
                          int commentCount;
                          try {
                            final sseCount = sseProvider.getCommentsCount(
                              post.id,
                            );
                            commentCount =
                                sseCount > 0 ? sseCount : post.commentsCount;
                          } catch (e) {
                            // En cas d'erreur, revenir au nombre de commentaires du post
                            commentCount = post.commentsCount;
                          }
                          return Text(
                            commentCount.toString(),
                            style: const TextStyle(color: Colors.white),
                          );                        
                        },
                      ),
                    ],
                    const Spacer(),
                    // Bouton de signalement
                    IconButton(
                      icon: const Icon(
                        Icons.report_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => _openReportModal(post),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Indicateur de défilement supprimé
      ],
    );
  }
}
