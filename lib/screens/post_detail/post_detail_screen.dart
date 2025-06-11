import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/components/comments/comments_modal.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
import 'package:provider/provider.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLoading = true;
  Post? _post;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }
  @override
  void dispose() {
    // Nous n'avons plus besoin de déconnecter le SSE ici car elle est gérée à la fermeture de la modal
    super.dispose();
  }

  Future<void> _loadPostDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ApiService apiService = ApiService();
      final response = await apiService.request(
        method: 'get',
        endpoint: '/posts/${widget.postId}',
        withAuth: false,
      );      if (response.success) {
        setState(() {
          _post = Post.fromJson(response.data);
          _isLoading = false;
        });
        // Nous ne connectons plus au SSE ici, mais uniquement quand la modal est ouverte
      } else {
        setState(() {
          _error = 'Impossible de charger les détails du post';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement du post: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;

    try {
      final ApiService apiService = ApiService();
      final response = await apiService.request(
        method: 'post',
        endpoint: '/posts/${_post!.id}/like',
        withAuth: true,
      );

      if (response.success) {
        setState(() {
          if (response.data['action'] == "added") {
            _post!.likesCount++;
          } else if (response.data['action'] == "removed") {
            _post!.likesCount--;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
  void _openCommentsModal() {
    if (_post == null) return;

    // Connexion au SSE quand on ouvre la modal
    final sseProvider = Provider.of<SSEProvider>(context, listen: false);
    sseProvider.connectToSSE(_post!.id);
    debugPrint('PostDetailScreen: Connexion SSE établie pour le post ${_post!.id}');
    
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
              post: _post!,
              isConnected: true,
              postAuthorName: _post!.user.userName,
            );
          },
        );
      },
    ).then((_) {
      // Déconnexion du SSE quand la modal est fermée
      sseProvider.disconnect(_post!.id);
      debugPrint('PostDetailScreen: Arrêt de l\'écoute SSE pour le post ${_post!.id}');
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_post?.name ?? 'Détail du post'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildPostDetail(),
    );
  }

  Widget _buildPostDetail() {
    if (_post == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: _post!.user.profilePicture.isEmpty
                      ? const AssetImage('assets/images/default_avatar.png') as ImageProvider
                      : NetworkImage(_post!.user.profilePicture),
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _post!.user.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      _getFormattedDate(_post!.updatedAt),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Payment or free indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _post!.isFree ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _post!.isFree ? 'Gratuit' : 'Payant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Post image
          Container(
            constraints: const BoxConstraints(maxHeight: 500),
            width: double.infinity,
            child: Image(
              image: _post!.pictureUrl.isEmpty
                  ? const AssetImage('assets/images/default_image.png') as ImageProvider
                  : NetworkImage(_post!.pictureUrl),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
            ),
          ),

          // Post name and description
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_post!.categories.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    children: _post!.categories.map((category) {
                      return Chip(
                        label: Text(category.name),
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),

          // Like and comment actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.favorite, color: Colors.red),
                  onPressed: _toggleLike,
                ),
                Text(
                  _post!.likesCount.toString(),
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                Consumer<SSEProvider>(
                  builder: (context, sseProvider, _) {
                    final commentCount = sseProvider.getCommentsCount(_post!.id) > 0
                        ? sseProvider.getCommentsCount(_post!.id)
                        : _post!.commentsCount;

                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.comment),
                          onPressed: _openCommentsModal,
                        ),
                        Text(
                          commentCount.toString(),
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
