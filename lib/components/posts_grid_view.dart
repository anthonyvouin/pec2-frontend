import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/interfaces/category.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
import 'package:firstflutterapp/utils/post_navigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PostsGridView extends StatelessWidget {
  final List<Post> posts;
  
  final List<Category> categories;
  
  final String? selectedCategoryId;
  
  final Function(String) onCategorySelected;
  
  final Future<void> Function({String? categoryId}) onRefresh;
  
  final bool isLoading;
  
  final String title;
  
  // final Color badgeColor;
  
  // final String badgeText;
  
  final List<Widget> headerWidgets;

  const PostsGridView({
    super.key,
    required this.posts,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onRefresh,
    required this.isLoading,
    required this.title,
    // required this.badgeColor,
    // required this.badgeText,
    this.headerWidgets = const [],
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => onRefresh(categoryId: selectedCategoryId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Badge supprimé
              ],
            ),
          ),
          
          ...headerWidgets,
          
          // Catégories horizontales
          if (categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategoryId == category.id;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => onCategorySelected(category.id),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: category.pictureUrl != null &&
                                        category.pictureUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: Image.network(
                                          category.pictureUrl!,
                                          width: 45,
                                          height: 45,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Text(
                                              category.name.substring(0, 1).toUpperCase(),
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Text(
                                        category.name.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
          // Indicateur de chargement ou grille de posts
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          selectedCategoryId != null
                              ? 'Chargement des posts pour votre recherche...'
                              : 'Chargement des posts...',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  )
                : _buildPostsGrid(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(BuildContext context) {
    return Consumer<SSEProvider>(
      builder: (context, sseProvider, _) {
        // Filtrer les posts reportés
        final displayPosts = posts.where((post) => 
          !sseProvider.isPostReported(post.id)).toList();
        
        if (displayPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  selectedCategoryId != null                    ? 'Pas de posts dans cette catégorie'
                    : 'Tous vos posts ont été signalés',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                if (selectedCategoryId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Essayez une autre catégorie',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ),
                const SizedBox(height: 24),
                if (selectedCategoryId != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      onCategorySelected(selectedCategoryId!);  // Désélectionne la catégorie
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Voir tous les posts'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => onRefresh(categoryId: selectedCategoryId),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rafraîchir'),
                  ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2 / 3,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            ),
            itemCount: displayPosts.length,
            itemBuilder: (context, index) {
              final post = displayPosts[index];
              return GestureDetector(
                onTap: () => _navigateToPostDetail(context, post, displayPosts),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image du post
                      Image.network(post.pictureUrl, fit: BoxFit.cover),

                      // Superposition sombre pour lisibilité
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

                      // Informations du post
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
                      ),                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToPostDetail(BuildContext context, Post post, List<Post> allPosts) {
    // Utilisez le PostNavigator pour naviguer vers la vue en plein écran
    PostNavigator.navigateToFullscreen(
      context,
      initialPostId: post.id,
      allPosts: allPosts,
    );
  }
}
