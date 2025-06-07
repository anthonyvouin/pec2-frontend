import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/components/comments/comments_modal.dart';
import 'package:firstflutterapp/components/comments/comment_badge.dart';
import 'package:firstflutterapp/components/post-card/report_bottom_sheet.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
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
  
  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
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
    final sseProvider = Provider.of<SSEProvider>(context, listen: false);
    sseProvider.connectToSSE(widget.post.id);
    
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
    );
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
            widget.post.likesCount++;
          } else if (response.data['action'] == "removed") {
            _likesCount--;
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
      margin: const EdgeInsets.only(bottom: 16),
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
                      ? const AssetImage('assets/images/default_avatar.png') as ImageProvider
                      : NetworkImage(widget.post.user.profilePicture),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.push('/profile/${widget.post.user.userName}'); // Navigate to user profile
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
                        child: ReportBottomSheet(postId: widget.post.id),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: () {
              toggleLike(widget.post.id).then((_) {
                // We need to notify parent to update posts list
                if (widget.onPostUpdated != null) {
                  widget.onPostUpdated!(widget.post.id);
                }
              });
            },
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              width: double.infinity,              child: Image(
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

          // Like and comment actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [                IconButton(
                  icon: _isLikeInProgress 
                      ? Icon(Icons.favorite, color: Colors.red.withOpacity(0.5))
                      : Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    toggleLike(widget.post.id).then((_) {
                      debugPrint('Post liked: ${widget.post.id}');
                      debugPrint('Post likes count: ${_likesCount}');
                      
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
                ),                const SizedBox(width: 8),
                Consumer<SSEProvider>(
                  builder: (context, sseProvider, _) {
                    final commentCount = sseProvider.getCommentsCount(widget.post.id) > 0 
                        ? sseProvider.getCommentsCount(widget.post.id)
                        : widget.post.commentsCount;
                    
                    return CommentBadge(
                      count: commentCount,
                      onTap: () => _openCommentsModal(context),
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
