import 'dart:developer' as developer;

import 'package:firstflutterapp/interfaces/user.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserNotifier extends ChangeNotifier {
  User? user;
  String? token;
  final ApiService _apiService = ApiService();

  // Ajout de la gestion des followings
  List<String> _followedUserIds = [];
  List<String> get followedUserIds => _followedUserIds;

  void setFollowedUserIds(List<String> ids) {
    _followedUserIds = ids;
    notifyListeners();
  }

  void addFollowedUser(String id) {
    if (!_followedUserIds.contains(id)) {
      _followedUserIds.add(id);
      notifyListeners();
    }
  }

  void removeFollowedUser(String id) {
    _followedUserIds.remove(id);
    notifyListeners();
  }

  void onAuthenticationSuccess(Map<String, dynamic> json) async {
    user = User.fromJson(json['user']);
    token = json['token'];
    notifyListeners();
  }

  void updateUser(Map<String, dynamic> json) async {
    user = User.fromJson(json);
    notifyListeners();
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenSaved = prefs.getString('auth_token');

    if (tokenSaved == null) {
      developer.log('Token non trouvé, utilisateur non connecté');
      return false;
    }

    if(user == null && tokenSaved != null){
     var request = await _apiService.request(method: 'GET', endpoint: '/users/profile');

     if(request != null && request.data != null){
       user = User.fromJson(request.data);
       token = tokenSaved;
     }
    }


    return token != null && user != null;
  }

  Future<bool> isAdmin() async {
      final prefs = await SharedPreferences.getInstance();
      final tokenSaved = prefs.getString('auth_token');

      if (tokenSaved == null) {
        developer.log('Token non trouvé, impossible de vérifier le rôle admin');
        return false;
      }
    try {
      // Décode le token pour accéder aux claims
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(tokenSaved);
      developer.log('Token décodé: $decodedToken');

      // Vérification exhaustive du rôle admin dans différents formats possibles
      if (decodedToken.containsKey('role')) {
        developer.log('Vérification du champ "role": ${decodedToken['role']}');
        if (decodedToken['role'] == 'admin' || decodedToken['role'] == 'ADMIN') {
          return true;
        }
      }

      if (decodedToken.containsKey('roles')) {
        developer.log('Vérification du champ "roles": ${decodedToken['roles']}');
        var roles = decodedToken['roles'];
        if (roles is List && (roles.contains('admin') || roles.contains('ADMIN'))) {
          return true;
        } else if (roles is String && (roles == 'admin' || roles == 'ADMIN')) {
          return true;
        }
      }


      developer.log('Aucun rôle admin trouvé dans le token');
      return false;
    } catch (e) {
      developer.log('Erreur lors du décodage du token: $e');
      return false;
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    user = null;
    token = null;
    developer.log('Utilisateur déconnecté');
  }
}
