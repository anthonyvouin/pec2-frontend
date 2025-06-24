import 'package:firstflutterapp/services/user_settings_service.dart';

class UserPreferencesHelper {
  static final UserPreferencesHelper _instance = UserPreferencesHelper._internal();
  final UserSettingsService _settingsService = UserSettingsService();
  
  // Cache des préférences utilisateur
  UserSettings? _cachedSettings;
  DateTime? _lastFetched;
  
  factory UserPreferencesHelper() {
    return _instance;
  }
  
  UserPreferencesHelper._internal();
  
  // Récupérer les préférences en tenant compte du cache (expire après 5 minutes)
  Future<UserSettings?> getUserSettings({bool forceRefresh = false}) async {
    // Si le cache est valide et qu'on ne force pas le rafraîchissement, on retourne les données en cache
    if (!forceRefresh && 
        _cachedSettings != null && 
        _lastFetched != null &&
        DateTime.now().difference(_lastFetched!).inMinutes < 5) {
      return _cachedSettings;
    }
    
    // Sinon, on fait l'appel API
    final response = await _settingsService.getUserSettings();
    
    if (response.success && response.data != null) {
      _cachedSettings = response.data;
      _lastFetched = DateTime.now();
      return response.data;
    }
    
    // En cas d'échec, on retourne null ou les dernières données en cache si disponibles
    return _cachedSettings;
  }
  
  // Méthode pour vérifier si les commentaires sont activés
  Future<bool> areCommentsEnabled() async {
    final settings = await getUserSettings();
    return settings?.commentEnabled ?? true; // Par défaut, les commentaires sont activés
  }
  
  // Méthode pour vérifier si les messages privés sont activés
  Future<bool> areMessagesEnabled() async {
    final settings = await getUserSettings();
    return settings?.messageEnabled ?? true; // Par défaut, les messages sont activés
  }
  
  // Effacer le cache (à appeler après une mise à jour des préférences)
  void clearCache() {
    _cachedSettings = null;
    _lastFetched = null;
  }
}
