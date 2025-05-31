import 'package:firstflutterapp/components/post-card/container.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
import 'package:firstflutterapp/screens/home/home-service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FreeFeed extends StatefulWidget {
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
  void dispose() {
    // La déconnexion est gérée par le provider
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await _postListingService.loadPosts();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
      
      // Initialise les connexions SSE pour chaque post
      final sseProvider = Provider.of<SSEProvider>(context, listen: false);
      for (final post in posts) {
        sseProvider.connectToSSE(post.id);
      }
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
        const Text(
          "Pour vous",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _posts.length,
          itemBuilder: (_, index) {
            final post = _posts[index];
            return Consumer<SSEProvider>(
              builder: (context, sseProvider, _) {
                final isConnected = sseProvider.isConnected(post.id);
                return PostCard(
                  post: post,
                  isSSEConnected: isConnected,
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildForYouSection();
  }
}
