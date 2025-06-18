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

  const FreeFeed({super.key, required this.currentUser, required this.isFree, this.userId});


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

    if (oldWidget.isFree != widget.isFree || oldWidget.userId != widget.userId) {
      _loadPosts();
    }
  }

  @override
  void dispose() {
    // La déconnexion est gérée par le provider
    // final sseProvider = Provider.of<SSEProvider>(context, listen: false);
    // sseProvider.disconnectAll();
    super.dispose();
  }  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final paginatedResponse = await _postListingService.loadPosts(widget.isFree, widget.userId);
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
        if(!widget.currentUser)
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
    return Provider<List<Post>>.value(
      value: _posts,
      child: _buildForYouSection(),
    );
  }
}
