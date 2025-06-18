import 'package:firstflutterapp/components/post-card/container.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
import 'package:firstflutterapp/screens/home/home-service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FreeFeed extends StatefulWidget {
  final bool currentUser;
  final bool isFree;
  final String? userId;
  final bool homeFeed;

  const FreeFeed({
    super.key,
    required this.currentUser,
    required this.isFree,
    this.userId,
    required this.homeFeed,
  });

  @override
  _FreeFeedState createState() => _FreeFeedState();
}

class _FreeFeedState extends State<FreeFeed> {
  bool _isLoading = false;
  List<Post> _posts = [];
  final PostsListingService _postListingService = PostsListingService();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void didUpdateWidget(covariant FreeFeed oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isFree != widget.isFree ||
        oldWidget.userId != widget.userId) {
      _loadPosts();
    }
  }

  @override
  void dispose() {
    super.dispose();
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
        false,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des posts: $e')),
        );
      }
    }
  }

  Widget _buildForYouSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.currentUser)
          const Text(
            "Pour vous",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 24),
        // GridView.builder(
        //   shrinkWrap: true,
        //   physics: const NeverScrollableScrollPhysics(),
        //   itemCount: _posts.length,
        //   gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        //     maxCrossAxisExtent: 600,
        //     childAspectRatio: 2 / 3,
        //     crossAxisSpacing: 8,
        //     mainAxisSpacing: 8,
        //   ),
        //   itemBuilder: (context, index) {
        //     final post = _posts[index];
        //     return Consumer<SSEProvider>(
        //       builder: (context, sseProvider, _) {
        //         final isConnected = sseProvider.isConnected(post.id);
        //         return ConstrainedBox(
        //           constraints: const BoxConstraints(
        //             maxHeight: 500, // ✅ Hauteur minimale ici
        //           ),
        //           child: PostCard(
        //             post: post,
        //             isSSEConnected: isConnected,
        //           ),
        //         );
        //       },
        //     );
        //   },
        // ),
        Column(
          children: [
            Wrap(
              spacing: 8, // espace horizontal entre les cartes
              runSpacing: 8, // espace vertical entre les lignes
              children:
                  _posts.map((post) {
                    return Consumer<SSEProvider>(
                      builder: (context, sseProvider, _) {
                        final isConnected = sseProvider.isConnected(post.id);
                        return ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 400,
                            minWidth: 400,
                            minHeight: 580,
                            maxHeight: 580,
                          ),
                          child: PostCard(
                            post: post,
                            isSSEConnected: isConnected,
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),
          ],
        ),

        // ListView.builder(
        //   physics: const NeverScrollableScrollPhysics(),
        //   shrinkWrap: true,
        //   itemCount: _posts.length,
        //   itemBuilder: (_, index) {
        //     final post = _posts[index];
        //     return Consumer<SSEProvider>(
        //       builder: (context, sseProvider, _) {
        //         final isConnected = sseProvider.isConnected(post.id);
        //         return PostCard(
        //           post: post,
        //           isSSEConnected: isConnected,
        //         );
        //       },
        //     );
        //   },
        // ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Provider<List<Post>>.value(
      value: _posts,
      child: _buildForYouSection(),
    );
  }
}
