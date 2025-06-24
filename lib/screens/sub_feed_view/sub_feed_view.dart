import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/services/subscription_feed_service.dart';
import 'package:firstflutterapp/components/posts_feed_view_base.dart';

class SubscriptionFeedView extends StatefulWidget {
  const SubscriptionFeedView({super.key});

  @override
  _SubscriptionFeedViewState createState() => _SubscriptionFeedViewState();
}

class _SubscriptionFeedViewState extends PostsFeedViewBase<SubscriptionFeedView> {
  final SubscriptionFeedService _subscriptionFeedService = SubscriptionFeedService();
  @override
  String get viewTitle => 'Abonnements';

  // @override
  // Color get badgeColor => Colors.transparent;

  // @override
  // String get badgeText => '';

  @override
  String get emptyStateTitle => 'Aucun post d\'abonnement';

  @override
  String get emptyCategoryStateTitle => 'Aucun post dans cette catégorie';

  @override
  String get emptyStateMessage => 'Abonnez-vous à des créateurs de contenu pour voir leurs posts ici.';

  @override
  String get emptyCategoryStateMessage => 'Essayez une autre catégorie';

  @override
  IconData get emptyStateIcon => Icons.subscriptions_outlined;

  @override
  Future<void> loadPosts({String? categoryId, String? searchQuery}) async {
    setState(() {
      isLoading = true;
      isError = false;
      errorMessage = '';
      posts = [];
    });

    try {
      print('SubscriptionFeedView: Chargement des posts d\'abonnement...');
      final paginatedResponse = await _subscriptionFeedService.loadSubscriptionPosts(
        page: 1,
        limit: 10,
        categoryId: categoryId,
      );
      
      if (mounted) {
        setState(() {
          posts = paginatedResponse.data;
          isLoading = false;
        });
      }
      
      print('SubscriptionFeedView: ${posts.length} posts chargés');
      
      // Afficher un message si aucun post n'a été trouvé
      if (posts.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aucun post payant trouvé parmi vos abonnements. Abonnez-vous à des créateurs pour voir leur contenu exclusif.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isError = true;
          errorMessage = 'Erreur lors du chargement des posts: $e';
          posts = [];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: buildContent(),
      ),
    );
  }
}
