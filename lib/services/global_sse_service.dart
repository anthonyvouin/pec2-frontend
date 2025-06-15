import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firstflutterapp/utils/platform_utils.dart';
import 'package:firstflutterapp/interfaces/comment.dart';
import 'package:universal_html/html.dart' if (dart.library.html) 'dart:html' as html;

/// Service qui gère une connexion SSE unique pour tous les posts
class GlobalSSEService {
  static final GlobalSSEService _instance = GlobalSSEService._internal();
  factory GlobalSSEService() => _instance;
  
  GlobalSSEService._internal();
  
  // La source d'événements SSE
  EventSourceBase? _eventSource;
  // L'abonnement au flux d'événements
  StreamSubscription? _subscription;
  // Statut de la connexion
  bool _isConnected = false;
  // Le contrôleur de flux pour les événements SSE
  final StreamController<SSEEvent> _eventsController = StreamController<SSEEvent>.broadcast();
  // La liste des posts actuellement surveillés
  final Set<String> _watchedPostIds = {};
  
  /// Stream d'événements SSE, diffusé à tous les abonnés
  Stream<SSEEvent> get events => _eventsController.stream;
  
  /// Vérifie si la connexion SSE est active
  bool get isConnected => _isConnected;
  
  /// Initialise la connexion SSE globale
  Future<void> initialize() async {
    if (_isConnected) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final baseUrl = PlatformUtils.getApiBaseUrl();
      final sseUrl = '$baseUrl/sse/handleSSE?token=$token';
      
      debugPrint('GlobalSSEService: Initialisation de la connexion globale SSE: $sseUrl');
      
      _eventSource = EventSourceFactory.create(sseUrl);
      
      _subscription = _eventSource!.events.listen(
        (event) {
          // Transmet l'événement au StreamController
          _eventsController.add(event);
          
          if (event.type == 'connected') {
            debugPrint('GlobalSSEService: Connexion SSE établie avec succès');
            _isConnected = true;
          }
        },
        onDone: () {
          debugPrint('GlobalSSEService: Connexion SSE terminée');
          _isConnected = false;
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint('GlobalSSEService: Erreur de connexion SSE: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('GlobalSSEService: Échec de l\'initialisation SSE: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }
  
  /// Planifie une reconnexion après un délai
  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) {
        debugPrint('GlobalSSEService: Tentative de reconnexion');
        initialize();
      }
    });
  }
  
  /// Ajoute un post à la liste des posts surveillés
  void watchPost(String postId) {
    _watchedPostIds.add(postId);
    debugPrint('GlobalSSEService: Surveillance du post $postId (total: ${_watchedPostIds.length})');
    
    // Si la connexion n'est pas établie, l'initialiser
    if (!_isConnected) {
      initialize();
    }
  }
  
  /// Arrête la surveillance d'un post
  void unwatchPost(String postId) {
    _watchedPostIds.remove(postId);
    debugPrint('GlobalSSEService: Arrêt de la surveillance du post $postId (restants: ${_watchedPostIds.length})');
  }
  
  /// Vérifie si un post est actuellement surveillé
  bool isWatchingPost(String postId) {
    return _watchedPostIds.contains(postId);
  }
  
  /// Retourne la liste des posts surveillés
  Set<String> get watchedPosts => Set.from(_watchedPostIds);
  
  /// Ferme la connexion SSE
  void close() {
    debugPrint('GlobalSSEService: Fermeture de la connexion SSE globale');
    _subscription?.cancel();
    _eventSource?.close();
    _isConnected = false;
    _watchedPostIds.clear();
  }
}

/// Classe représentant un événement SSE
class SSEEvent {
  final String type;
  final String? data;
  final String? lastEventId;
  
  SSEEvent({
    required this.type,
    this.data,
    this.lastEventId,
  });
  
  /// Tente de parser les données JSON de l'événement
  dynamic get parsedData {
    if (data == null || data!.isEmpty) return null;
    try {
      return jsonDecode(data!);
    } catch (e) {
      debugPrint('SSEEvent: Erreur de parsing JSON: $e');
      return null;
    }
  }
  
  /// Vérifie si l'événement concerne un post spécifique
  bool concernsPost(String postId) {
    final parsed = parsedData;
    if (parsed == null) return false;
    
    if (parsed is Map) {
      // Vérifier différents formats possibles
      if (parsed.containsKey('postId')) {
        return parsed['postId'] == postId;
      } else if (parsed.containsKey('payload') && parsed['payload'] is Map) {
        return parsed['payload']['postId'] == postId;
      }
    }
    
    return false;
  }
}

/// Factory pour créer la source d'événements appropriée
class EventSourceFactory {
  static EventSourceBase create(String url) {
    if (kIsWeb) {
      return WebEventSource(url);
    } else {
      return IoEventSource(url);
    }
  }
}

/// Interface de base pour les sources d'événements
abstract class EventSourceBase {
  Stream<SSEEvent> get events;
  void close();
}

/// Implémentation Web des sources d'événements
class WebEventSource implements EventSourceBase {
  final String url;
  final StreamController<SSEEvent> _streamController = StreamController<SSEEvent>.broadcast();
  html.EventSource? _eventSource;
  
  WebEventSource(this.url) {
    try {
      if (kIsWeb) {
        _eventSource = html.EventSource(url);
        
        _eventSource!.onOpen.listen((event) {
          _streamController.add(SSEEvent(
            type: 'connected'
          ));
        });
        
        _eventSource!.onMessage.listen((event) {
          _streamController.add(SSEEvent(
            type: 'message',
            data: event.data,
            lastEventId: event.lastEventId,
          ));
        });
        
        _eventSource!.onError.listen((event) {
          _streamController.addError('EventSource error');
        });
      }
    } catch (e) {
      debugPrint('WebEventSource: Erreur lors de la création: $e');
      _streamController.addError(e);
    }
  }
  
  @override
  Stream<SSEEvent> get events => _streamController.stream;
  
  @override
  void close() {
    debugPrint('WebEventSource: Fermeture de la connexion SSE');
    _eventSource?.close();
    _streamController.close();
  }
}

/// Implémentation pour les plateformes non Web
class IoEventSource implements EventSourceBase {
  final String url;
  final StreamController<SSEEvent> _streamController = StreamController<SSEEvent>.broadcast();
  
  IoEventSource(this.url) {
    // Implémentation simulée pour les plateformes non Web
    // En production, utilisez une vraie implémentation HTTP
    Future.microtask(() {
      _streamController.add(SSEEvent(
        type: 'connected'
      ));
    });
    
    // En cas d'erreur, ajouter un délai pour éviter des boucles infinies
    Future.delayed(const Duration(minutes: 5), () {
      _streamController.addError('EventSource timeout');
    });
  }
  
  @override
  Stream<SSEEvent> get events => _streamController.stream;
  
  @override
  void close() {
    debugPrint('IoEventSource: Fermeture de la connexion SSE');
    _streamController.close();
  }
}
