import 'package:firstflutterapp/interfaces/comment.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/notifiers/sse_provider.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:firstflutterapp/utils/date_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CommentsModal extends StatefulWidget {
  final Post post;
  final bool isConnected;
  final String postAuthorName;
  
  const CommentsModal({
    required this.post,
    required this.isConnected,
    required this.postAuthorName,
    super.key
  });

  @override
  _CommentsModalState createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  final TextEditingController _commentController = TextEditingController();

  List<Comment> _comments = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadComments();

    final sseProvider = context.read<SSEProvider>();
    // S'assurer que les commentaires SSE sont reflétés dans l'UI
    sseProvider.connectToSSE(widget.post.id);
  }

  Future<void> _loadComments() async {
    final ApiService apiService = ApiService();

    final response = await apiService.request(
      method: 'get',
      endpoint: '/posts/${widget.post.id}/comments',
      withAuth: true,
    );

    if (response.statusCode == 200) {
      setState(() {
        _comments = response.data['comments'].map<Comment>((json) => Comment.fromJson(json)).toList();
        _isLoading= false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des commentaires')),
      );
    }
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  void _sendComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }
    
    try {
      final sseProvider = context.read<SSEProvider>();
      
      // Store the comment text and clear the input field immediately for better UX
      final String commentText = _commentController.text;
      _commentController.clear();
      FocusScope.of(context).unfocus();
      
      final comment = await sseProvider.sendComment(widget.post.id, commentText);
      
      // Update local state with the new comment
      setState(() {
        if (comment != null && !_comments.any((c) => c.id == comment.id)) {
          _comments.insert(0, comment);
        }
      });
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi du commentaire: ${e.toString().substring(0, 100)}...'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ]
            ),
          ),
          if(_isLoading)
            const LinearProgressIndicator(),
          // Liste des commentaires
          Expanded(
            child: Consumer<SSEProvider>(
              builder: (context, sseProvider, _) {                // Créer une liste combinée de tous les commentaires (SSE + chargés)
                
                // Commencer avec tous les commentaires du SSE provider
                final List<Comment> allComments = [];
                final sseComments = sseProvider.getComments(widget.post.id);
                
                // Toujours afficher les commentaires du SSE provider en priorité
                if (sseComments.isNotEmpty) {
                  allComments.addAll(sseComments);
                }
                
                // Ajouter les commentaires chargés via API REST qui ne sont pas déjà présents
                if (_comments.isNotEmpty) {
                  for (final comment in _comments) {
                    if (!allComments.any((c) => c.id == comment.id)) {
                      allComments.add(comment);
                    }
                  }
                }
                
                // Trier les commentaires par date (plus récent en premier)
                allComments.sort((a, b) {
                  final dateA = DateTime.parse(a.createdAt);
                  final dateB = DateTime.parse(b.createdAt);
                  return dateB.compareTo(dateA);
                });
                                
                if (allComments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun commentaire pour le moment',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Soyez le premier à commenter',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allComments.length,
                  itemBuilder: (context, index) {
                    final comment = allComments[index];
                    bool isAuthor = comment.userName == widget.postAuthorName;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isAuthor ? Colors.purple.shade100 : Colors.grey.shade300,
                            child: Text(
                              comment.userName.isNotEmpty 
                                  ? comment.userName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: isAuthor ? Theme.of(context).primaryColor: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isAuthor ? Theme.of(context).primaryColor : Colors.black87,
                                      ),
                                    ),
                                    if (isAuthor)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Auteur',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ),
                                    const Spacer(),
                                    Text(
                                      DateFormatter.formatTimeAgo(DateTime.parse(comment.createdAt)),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Champ de saisie pour commenter
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Ajoutez un commentaire...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        hintStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                      maxLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<SSEProvider>(
                  builder: (context, sseProvider, _) {
                    return ElevatedButton(
                      onPressed: (widget.isConnected || sseProvider.isConnected(widget.post.id)) 
                          ? () {
                              if (_commentController.text.trim().isNotEmpty) {
                                _sendComment();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    );
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
