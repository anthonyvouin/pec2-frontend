import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:firstflutterapp/components/subscription/subscription_required_widget.dart';

import '../../interfaces/post.dart';
import '../../notifiers/sse_provider.dart';
import '../../notifiers/userNotififers.dart';
import '../../screens/home/home-service.dart';

class ProfileFeed extends StatefulWidget {
  final String? userId;
  final bool isFree;
  final bool currentUser;
  final bool? isSubscriber;

  const ProfileFeed({
    super.key,
    required this.currentUser,
    required this.isFree,
    this.userId,
    this.isSubscriber,
  });

  @override
  State<ProfileFeed> createState() => _ProfileFeedState();
}

class _ProfileFeedState extends State<ProfileFeed> {
  bool _isLoading = false;
  List<Post> _posts = [];
  final PostsListingService _postListingService = PostsListingService();
  final ApiService _apiService = ApiService();
  bool currentUserIsSameUserThanProfilUser = false;
  @override
  void didUpdateWidget(covariant ProfileFeed oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isFeedChanged =
        oldWidget.isFree != widget.isFree || oldWidget.userId != widget.userId;

    final shouldLoadPosts =
        widget.isFree || (widget.isSubscriber ?? false) || widget.currentUser || currentUserIsSameUserThanProfilUser;

    if (isFeedChanged && shouldLoadPosts) {
      _loadPosts();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final paginatedResponse = await _postListingService.loadPosts(
        1,
        10,
        widget.isFree,
        widget.userId,
      );
      setState(() {
        _posts = paginatedResponse.data;
        _isLoading = false;
      });

      // Nous ne connectons plus au SSE ici, mais uniquement quand la modal des commentaires est ouverte
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastService.showToast(
          'Erreur lors du chargement des posts: $e',
          ToastificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userNotifier = Provider.of<UserNotifier>(context);
    currentUserIsSameUserThanProfilUser = userNotifier.user?.id == widget.userId ;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Pas de posts pour le moment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isFree ||
        widget.currentUser ||
        currentUserIsSameUserThanProfilUser||
        (!widget.isFree && (widget.isSubscriber ?? false))) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return GestureDetector(
            onTap: () => _navigateToPostDetail(post),
            child: Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(post.pictureUrl, fit: BoxFit.cover),
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
                  if (widget.currentUser)
                    Positioned(
                      top: 3,
                      right: 3,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'edit') {
                            context.go(
                              '/post/edit/${post.id}',
                              extra: {
                                'name': post.name,
                                'categories': post.categories,
                                'visibility': post.isFree,
                                'imageUrl': post.pictureUrl,
                                'description': post.description,
                                'id': post.id,
                              },
                            );
                          } else if (value == 'delete') {
                            deletePost(post.id);
                          }
                        },
                        itemBuilder:
                            (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: Text('Modifier'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Supprimer'),
                              ),
                            ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return SubscriptionRequiredWidget();
    }
  }

  Future<void> deletePost(String id) async {
    ApiResponse response = await _apiService.request(
      endpoint: '/posts/$id',
      method: 'delete',
      withAuth: true,
    );

    if (response.success) {
      ToastService.showToast('Post supprimé', ToastificationType.success);
      setState(() {
        _posts.removeWhere((p) => p.id == id);
      });
    } else {
      ToastService.showToast('Erreur lors de la supression du post: ${response.error}', ToastificationType.success);
    }
  }

  void _navigateToPostDetail(Post post) {
    print('Navigation vers le détail du post: ${post.id}');

    // Nous ne connectons plus au SSE ici, mais uniquement quand la modal des commentaires est ouverte
    if (mounted) {
      final sseProvider = Provider.of<SSEProvider>(context, listen: false);

      // Déconnecter toutes les anciennes connexions
      sseProvider.disconnectAll();
    }

    context.push('/post/${post.id}', extra: _posts);
  }
}
