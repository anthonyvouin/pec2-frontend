import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firstflutterapp/theme.dart';

enum AppThemeMode {
  light,
  dark,
  system
}

class ThemeNotifier extends ChangeNotifier {
  static const String _themePreferenceKey = 'theme_preference';
  
  // Thème par défaut
  AppThemeMode _themeMode = AppThemeMode.system;
  
  // Getters pour les thèmes
  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;
  
  // Getter pour le mode de thème actuel
  AppThemeMode get themeMode => _themeMode;
  
  // Getter pour savoir si le mode sombre est actif (sans tenir compte du système)
  bool get isDarkMode => _themeMode == AppThemeMode.dark;
  
  // Vérifie si le mode sombre est actuellement actif (en tenant compte du système)
  bool isCurrentlyDarkMode(BuildContext context) {
    if (_themeMode == AppThemeMode.system) {
      final brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == AppThemeMode.dark;
  }
  
  // Getter pour le thème actuel en fonction du mode système
  ThemeData currentTheme(BuildContext context) {
    if (_themeMode == AppThemeMode.system) {
      final brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.dark ? darkTheme : lightTheme;
    }
    return _themeMode == AppThemeMode.dark ? darkTheme : lightTheme;
  }
  
  // Constructeur
  ThemeNotifier() {
    _loadThemePreference();
  }
  
  // Charger la préférence de thème depuis SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePreferenceKey);
    
    if (themeIndex != null) {
      _themeMode = AppThemeMode.values[themeIndex];
      notifyListeners();
    }
  }
  
  // Définir le thème clair
  Future<void> setLightTheme() async {
    _themeMode = AppThemeMode.light;
    await _saveThemePreference();
    notifyListeners();
  }
  
  // Définir le thème sombre
  Future<void> setDarkTheme() async {
    _themeMode = AppThemeMode.dark;
    await _saveThemePreference();
    notifyListeners();
  }
  
  // Définir le thème système
  Future<void> setSystemTheme() async {
    _themeMode = AppThemeMode.system;
    await _saveThemePreference();
    notifyListeners();
  }
  
  // Basculer entre les thèmes clair et sombre
  Future<void> toggleTheme() async {
    if (_themeMode == AppThemeMode.light) {
      await setDarkTheme();
    } else {
      await setLightTheme();
    }
  }
  
  // Enregistrer la préférence de thème
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePreferenceKey, _themeMode.index);
  }
}
