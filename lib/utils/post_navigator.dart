import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/screens/post_detail/post_fullscreen_view.dart';

/// Utilitaire pour naviguer vers la vue en plein écran des posts
class PostNavigator {
  /// Ouvre la vue en plein écran pour un post spécifique
  static void navigateToFullscreen(BuildContext context, {
    required String initialPostId,
    required List<Post> allPosts,
  }) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => PostFullscreenView(
          initialPostId: initialPostId,
          allPosts: allPosts,
        ),
      ),
    );
  }
}
