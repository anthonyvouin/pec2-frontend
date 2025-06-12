import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/comment.dart';
import 'package:firstflutterapp/services/sse_service.dart';

class SSEProvider extends ChangeNotifier {
  // Map qui garde les services SSE en cours par postId
  final Map<String, SSEService> _sseServices = {};
  // Map qui stocke l'état de connexion pour chaque post
  final Map<String, bool> _connectionStatus = {};
  // Map qui stocke les commentaires par postId
  final Map<String, List<Comment>> _commentsByPostId = {};
  // Map qui stocke le nombre de commentaires par postId
  final Map<String, int> _commentsCountByPostId = {};

  // Getter pour vérifier si un post a une connexion SSE active
  bool isConnected(String postId) {
    return _connectionStatus[postId] ?? false;
  }
  // Getter pour récupérer tous les commentaires d'un post
  List<Comment> getComments(String postId) {
    return _commentsByPostId[postId] ?? [];
  }
  
  // Getter pour récupérer le nombre de commentaires d'un post
  int getCommentsCount(String postId) {
    return _commentsCountByPostId[postId] ?? 0;
  }
  // Initialise une connexion SSE pour un post spécifique
  void connectToSSE(String postId) {
    
    // Si on a déjà une connexion pour ce post, on ne fait rien
    if (_sseServices.containsKey(postId)) {
      return;
    }

    debugPrint('CommentsModal: Initialisation du service SSE pour le post $postId');

    // Crée un nouveau service SSE
    final sseService = SSEService(
      postId: postId,
      onNewComment: (comment) {
        // Utiliser Future.microtask pour éviter les problèmes de setState pendant le build
        Future.microtask(() {
          _addComment(postId, comment);
          notifyListeners();
        });
      },
      onExistingComments: (comments) {
        // Utiliser Future.microtask pour éviter les problèmes de setState pendant le build
        Future.microtask(() {
          _addComments(postId, comments);
          notifyListeners();
        });
      },
      onConnectionStatusChanged: (isConnected) {
        // Utiliser Future.microtask pour éviter les problèmes de setState pendant le build
        Future.microtask(() {
          _connectionStatus[postId] = isConnected;
          notifyListeners();
        });
      },
    );

    // Stocke le service et tente de se connecter
    _sseServices[postId] = sseService;
    
    // On utilise Future.microtask pour s'assurer que l'initialisation est effectuée après le build
    Future.microtask(() {
      sseService.connect().then((_) {
        // Succès - traitement asynchrone
      }).catchError((error) {
        debugPrint('SSEProvider: Erreur de connexion SSE pour post $postId: $error');
        _connectionStatus[postId] = false;
        notifyListeners();
      });
    });
  }
  // Ajoute un nouveau commentaire à la liste pour un post
  void _addComment(String postId, Comment comment) {
    
    if (!_commentsByPostId.containsKey(postId)) {
      _commentsByPostId[postId] = [];
    }
    
    // Vérifie si le commentaire existe déjà
    bool commentExists = _commentsByPostId[postId]!.any((c) => c.id == comment.id);
    if (commentExists) {
      return;
    }
    
    _commentsByPostId[postId]!.add(comment);
    
    _commentsCountByPostId[postId] = comment.commentsCount;
    
    // Tri des commentaires par date (plus récent en dernier)
    _commentsByPostId[postId]!.sort((a, b) {
      final dateA = DateTime.parse(a.createdAt);
      final dateB = DateTime.parse(b.createdAt);
      return dateA.compareTo(dateB);
    });
    
  }
  // Ajoute plusieurs commentaires à la liste pour un post
  void _addComments(String postId, List<Comment> comments) {
    
    if (!_commentsByPostId.containsKey(postId)) {
      _commentsByPostId[postId] = [];
    }
    
    final List<Comment> existingComments = _commentsByPostId[postId]!;
    int addedCount = 0;
    
    // Ajoute seulement les commentaires qui n'existent pas déjà
    for (final comment in comments) {
      if (!existingComments.any((c) => c.id == comment.id)) {
        existingComments.add(comment);
        addedCount++;
      }
    }
    
    if (addedCount > 0) {
      // Tri des commentaires par date (plus récent en dernier)
      _commentsByPostId[postId]!.sort((a, b) {
        final dateA = DateTime.parse(a.createdAt);
        final dateB = DateTime.parse(b.createdAt);
        return dateA.compareTo(dateB);
      });
      
      if (comments.isNotEmpty) {
        _commentsCountByPostId[postId] = comments.last.commentsCount;
      }
    }
  }
  // Envoie un nouveau commentaire
  Future<Comment?> sendComment(String postId, String content) async {
    try {
      final comment = await SSEService.sendComment(postId, content);
      
      // Vérifie si ce commentaire existe déjà dans notre liste locale
      final commentsList = _commentsByPostId[postId] ?? [];
      final commentExists = commentsList.any((c) => c.id == comment.id);
      
      if (!commentExists) {
        // Ajout manuel du commentaire à notre liste locale
        _addComment(postId, comment);
        
        _commentsCountByPostId[postId] = comment.commentsCount;
        
        notifyListeners();
      }
      
      return comment;
    } catch (e, stackTrace) {
      debugPrint('Erreur lors de l\'envoi du commentaire: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }  // Déconnecte tous les services SSE
  void disconnectAll() {
    // Capture les services à déconnecter avant de vider les maps
    final servicesToDisconnect = List<SSEService>.from(_sseServices.values);
    
    // Vider les maps immédiatement pour éviter des manipulations supplémentaires
    _sseServices.clear();
    _connectionStatus.clear();
    _commentsByPostId.clear();
    _commentsCountByPostId.clear();
    
    // Effectuer la déconnexion et la notification dans un microtask
    // pour éviter les problèmes pendant la navigation
    Future.microtask(() {
      for (final service in servicesToDisconnect) {
        try {
          service.disconnect();
        } catch (e) {
          debugPrint('Erreur lors de la déconnexion SSE: $e');
        }
      }
      notifyListeners();
    });
  }
  // Déconnecte tous les services SSE sans notifier les listeners
  // Utile pour éviter les erreurs pendant la disposition des widgets
  void disconnectAllSilently() {
    final servicesToDisconnect = List<SSEService>.from(_sseServices.values);
    
    _sseServices.clear();
    _connectionStatus.clear();
    
    for (final service in servicesToDisconnect) {
      service.disconnect();
    }
    // Pas de notifyListeners() ici pour éviter les erreurs pendant dispose()
  }
  // Déconnecte une connexion SSE spécifique
  void disconnect(String postId) {
    final service = _sseServices[postId];
    if (service != null) {
      final serviceToDisconnect = service;
      _sseServices.remove(postId);
      _connectionStatus[postId] = false;
      
      // Effectuer la déconnexion dans un microtask pour éviter les problèmes
      Future.microtask(() {
        serviceToDisconnect.disconnect();
        notifyListeners();
      });
    }
  }
  // Déconnecte une connexion SSE spécifique sans notifier les listeners
  void disconnectSilently(String postId) {
    final service = _sseServices[postId];
    if (service != null) {
      _sseServices.remove(postId);
      _connectionStatus[postId] = false;
      service.disconnect();
    }
  }
  
  @override
  void dispose() {
    disconnectAllSilently();
    super.dispose();
  }
}
