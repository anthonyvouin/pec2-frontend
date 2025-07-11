import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/components/comments/comments_modal.dart';
import 'package:firstflutterapp/components/comments/comment_badge.dart';
import 'package:firstflutterapp/components/post-card/report_bottom_sheet.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
import 'package:firstflutterapp/utils/post_navigator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

final ApiService _apiService = ApiService();

class PostCard extends StatefulWidget {
  final Post post;
  final bool isSSEConnected;
  final Function(String)? onPostUpdated;

  const PostCard({
    super.key,
    required this.post,
    required this.isSSEConnected,
    this.onPostUpdated,
  });
  
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int _likesCount;
  bool _isLikeInProgress = false;
  bool _isLiked = false; // Track si l'utilisateur a liké le post
  
  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    _isLiked = widget.post.isLikedByUser; // Initialiser avec la valeur du backend
  }
  
  String getFormattedDate(DateTime date) {
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
  void _openCommentsModal(BuildContext context) {
    if (!widget.post.commentEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les commentaires sont désactivés pour ce post'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final sseProvider = Provider.of<SSEProvider>(context, listen: false);
    sseProvider.connectToSSE(widget.post.id);
    debugPrint('PostCard: Connexion SSE établie pour le post ${widget.post.id}');
    
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
              post: widget.post,
              isConnected: widget.isSSEConnected,
              postAuthorName: widget.post.user.userName,
            );
          },
        );
      },
    ).then((_) {
      // Déconnexion du SSE quand la modal est fermée
      sseProvider.disconnect(widget.post.id);
      debugPrint('PostCard: Arrêt de l\'écoute SSE pour le post ${widget.post.id}');
    });
  }
  
  Future<void> toggleLike(String postId) async {
    // J'ai essayé de faire un debounce pour éviter les clics trop rapides
    if (_isLikeInProgress) {
      return;
    }
    
    setState(() {
      _isLikeInProgress = true;
    });
    
    try {
      final response = await _apiService.request(
        method: 'post',
        endpoint: '/posts/$postId/like',
        withAuth: true,
      );


      if (response.success) {
        setState(() {
          if (response.data['action'] == "added") {
            _likesCount++;
            _isLiked = true;
            widget.post.likesCount++;
            widget.post.isLikedByUser = true; // Mettre à jour la propriété du post
          } else if (response.data['action'] == "removed") {
            _likesCount--;
            _isLiked = false;
            widget.post.likesCount--;
            widget.post.isLikedByUser = false; // Mettre à jour la propriété du post
          }
        });
      } else {
        throw Exception('Échec de l\'ajout du like: ${response.error}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      // O.5 seconde pour le debounce
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isLikeInProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
            child: Row(
              children: [                
                CircleAvatar(
                  backgroundImage: widget.post.user.profilePicture.isEmpty
                      ? const AssetImage('assets/images/dog.webp') as ImageProvider
                      : NetworkImage(widget.post.user.profilePicture),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.go('/profile/${widget.post.user.userName}'); // Navigate to user profile
                      },
                      child: Text(
                        widget.post.user.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      getFormattedDate(widget.post.updatedAt),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),                
                IconButton(
                  icon: const Icon(Icons.report_outlined),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true, 
                      backgroundColor: Colors.transparent,
                      builder: (context) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: ReportBottomSheet(
                          postId: widget.post.id,
                          onPostReported: (postId) {
                            if (widget.onPostUpdated != null) {
                              widget.onPostUpdated!(postId);
                            } else {
                              print('PostCard: ERREUR - callback onPostUpdated est null');
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),          
          
          GestureDetector(
            onTap: () {
              // Naviguer vers la vue en plein écran en différant la déconnexion
              // pour éviter les problèmes de notifications pendant le build
              Future.microtask(() {
                if (!mounted) return;
                
                final postsProvider = Provider.of<SSEProvider>(context, listen: false);
                postsProvider.disconnectAll();
                
                // Récupérer la liste des posts du parent (FreeFeed)
                final posts = Provider.of<List<Post>?>(context, listen: false) ?? [widget.post];
                PostNavigator.navigateToFullscreen(
                  context,
                  initialPostId: widget.post.id,
                  allPosts: posts,
                );
              });
            },
            onDoubleTap: () {
              toggleLike(widget.post.id).then((_) {
                // We need to notify parent to update posts list
                if (widget.onPostUpdated != null) {
                  widget.onPostUpdated!(widget.post.id);
                }
              });
            },
            child: Container(
              constraints: const BoxConstraints(maxHeight: 380, minHeight: 380),
              width: double.infinity,
              child: Image(
                image: widget.post.pictureUrl.isEmpty
                    ? const AssetImage('assets/images/default_image.png') as ImageProvider
                    : NetworkImage(widget.post.pictureUrl),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                    ),
                  );
                },
                errorBuilder:
                    (context, error, stackTrace) => const Icon(Icons.error),
              ),
            ),
          ),

          // Post caption
          if (widget.post.name.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 4, top: 12, bottom: 0),
              child: Text(widget.post.name, style: const TextStyle(fontSize: 15)),
            ),
          
          // Post description
          // if (widget.post.description.isNotEmpty)
          //   Padding(
          //     padding: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 8),
          //     child: Container(
          //       constraints: const BoxConstraints(maxHeight: 60),
          //       child: SingleChildScrollView(
          //         child: Text(
          //           widget.post.description,
          //           style: const TextStyle(fontSize: 14, color: Colors.grey),
          //         ),
          //       ),
          //     ),
          //   ),

          // Like and comment actions
          Padding(
            padding: const EdgeInsets.only(left: 0, right: 4, top: 4, bottom: 0),
            child: Row(
              children: [                
                IconButton(
                  icon: _isLikeInProgress 
                      ? Icon(Icons.favorite, color: Colors.red.withOpacity(0.5))
                      : Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Theme.of(context).iconTheme.color,
                        ),
                  onPressed: () {
                    toggleLike(widget.post.id).then((_) {
                      // We need to notify parent to update posts list
                      if (widget.onPostUpdated != null) {
                        widget.onPostUpdated!(widget.post.id);
                      }
                    });
                  },
                ),
                Text(
                  _likesCount.toString(),
                  style: TextStyle(color: Theme.of(context).iconTheme.color),
                ),
                
                // Afficher le badge de commentaire uniquement si les commentaires sont activés pour le post
                const SizedBox(width: 8),
                Consumer<SSEProvider>(
                  builder: (context, sseProvider, _) {
                    final commentCount = sseProvider.getCommentsCount(widget.post.id) > 0 
                        ? sseProvider.getCommentsCount(widget.post.id)
                        : widget.post.commentsCount;
                    
                    return CommentBadge(
                      count: commentCount,
                      onTap: () => _openCommentsModal(context),
                      commentEnabled: widget.post.commentEnabled,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostCardContainer extends StatefulWidget {
  final Post post;
  final bool isSSEConnected;
  final Function(String)? onPostUpdated;

  const PostCardContainer({
    super.key,
    required this.post,
    required this.isSSEConnected,
    this.onPostUpdated,
  });
  
  @override
  State<PostCardContainer> createState() => _PostCardContainerState();
}

class _PostCardContainerState extends State<PostCardContainer> {
  late int _likesCount;
  bool _isLikeInProgress = false;
  bool _isLiked = false; // Track si l'utilisateur a liké le post
  
  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    _isLiked = widget.post.isLikedByUser; // Initialiser avec la valeur du backend
  }
  
  String getFormattedDate(DateTime date) {
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
  
  void _openCommentsModal(BuildContext context) {
    // Vérifier si les commentaires sont activés pour le post
    if (!widget.post.commentEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les commentaires sont désactivés pour ce post'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final sseProvider = Provider.of<SSEProvider>(context, listen: false);
    sseProvider.connectToSSE(widget.post.id);
    debugPrint('PostCard: Connexion SSE établie pour le post ${widget.post.id}');
    
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
              post: widget.post,
              isConnected: widget.isSSEConnected,
              postAuthorName: widget.post.user.userName,
            );
          },
        );
      },
    ).then((_) {
      // Déconnexion du SSE quand la modal est fermée
      sseProvider.disconnect(widget.post.id);
      debugPrint('PostCard: Arrêt de l\'écoute SSE pour le post ${widget.post.id}');
    });
  }
  
  Future<void> toggleLike(String postId) async {
    // J'ai essayé de faire un debounce pour éviter les clics trop rapides
    if (_isLikeInProgress) {
      return;
    }
    
    setState(() {
      _isLikeInProgress = true;
    });
    
    try {
      final response = await _apiService.request(
        method: 'post',
        endpoint: '/posts/$postId/like',
        withAuth: true,
      );


      if (response.success) {
        setState(() {
          if (response.data['action'] == "added") {
            _likesCount++;
            _isLiked = true;
            widget.post.likesCount++;
          } else if (response.data['action'] == "removed") {
            _likesCount--;
            _isLiked = false;
            widget.post.likesCount--;
          }
        });
      } else {
        throw Exception('Échec de l\'ajout du like: ${response.error}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      // O.5 seconde pour le debounce
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isLikeInProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12), // Réduit de 16 à 12 pour éviter le dépassement
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with username and timestamp
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [                
                CircleAvatar(
                  backgroundImage: widget.post.user.profilePicture.isEmpty
                      ? const AssetImage('assets/images/dog.webp') as ImageProvider
                      : NetworkImage(widget.post.user.profilePicture),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.go('/profile/${widget.post.user.userName}');
                      },
                      child: Text(
                        widget.post.user.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      getFormattedDate(widget.post.updatedAt),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),                IconButton(
                  icon: const Icon(Icons.report_outlined),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true, 
                      backgroundColor: Colors.transparent,
                      builder: (context) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: ReportBottomSheet(
                          postId: widget.post.id,
                          onPostReported: (postId) {
                            if (widget.onPostUpdated != null) {
                              widget.onPostUpdated!(postId);
                            } else {
                              print('PostCard: ERREUR - callback onPostUpdated est null');
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),          GestureDetector(
            onTap: () {
              // Naviguer vers la vue en plein écran en différant la déconnexion
              // pour éviter les problèmes de notifications pendant le build
              Future.microtask(() {
                if (!mounted) return;
                
                final postsProvider = Provider.of<SSEProvider>(context, listen: false);
                postsProvider.disconnectAll();
                
                // Récupérer la liste des posts du parent (FreeFeed)
                final posts = Provider.of<List<Post>?>(context, listen: false) ?? [widget.post];
                PostNavigator.navigateToFullscreen(
                  context,
                  initialPostId: widget.post.id,
                  allPosts: posts,
                );
              });
            },
            onDoubleTap: () {
              toggleLike(widget.post.id).then((_) {
                // We need to notify parent to update posts list
                if (widget.onPostUpdated != null) {
                  widget.onPostUpdated!(widget.post.id);
                }
              });
            },
            child: Container(
              constraints: const BoxConstraints(maxHeight: 380, minHeight: 380), // Réduit de 400 à 380 pour réduire le dépassement
              width: double.infinity,
              child: Image(
                image: widget.post.pictureUrl.isEmpty
                    ? const AssetImage('assets/images/default_image.png') as ImageProvider
                    : NetworkImage(widget.post.pictureUrl),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                    ),
                  );
                },
                errorBuilder:
                    (context, error, stackTrace) => const Icon(Icons.error),
              ),
            ),
          ),

          // Post caption
          if (widget.post.name.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(widget.post.name, style: const TextStyle(fontSize: 15)),
            ),
          
          // Post description
          if (widget.post.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 60), // Limite la hauteur de la description
                child: SingleChildScrollView(
                  child: Text(
                    widget.post.description,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ),
            ),

          // Like and comment actions
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4), // Ajout d'un padding vertical réduit
            child: Row(
              children: [                
                IconButton(
                  icon: _isLikeInProgress 
                      ? Icon(Icons.favorite, color: Colors.red.withOpacity(0.5))
                      : Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.grey[600],
                        ),
                  onPressed: () {
                    toggleLike(widget.post.id).then((_) {
                      
                      // We need to notify parent to update posts list
                      if (widget.onPostUpdated != null) {
                        widget.onPostUpdated!(widget.post.id);
                      }
                    });
                  },
                ),
                Text(
                  _likesCount.toString(),
                  style: TextStyle(color: Colors.grey[700]),
                ),
                
                // Afficher le badge de commentaire uniquement si les commentaires sont activés pour le post
                const SizedBox(width: 8),
                Consumer<SSEProvider>(
                  builder: (context, sseProvider, _) {
                    final commentCount = sseProvider.getCommentsCount(widget.post.id) > 0 
                        ? sseProvider.getCommentsCount(widget.post.id)
                        : widget.post.commentsCount;
                    
                    return CommentBadge(
                      count: commentCount,
                      onTap: () => _openCommentsModal(context),
                      commentEnabled: widget.post.commentEnabled,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
