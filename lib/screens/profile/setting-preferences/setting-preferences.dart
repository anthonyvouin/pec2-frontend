import 'package:flutter/material.dart';
import 'package:firstflutterapp/services/user_settings_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:toastification/toastification.dart';
import 'package:provider/provider.dart';
import 'package:firstflutterapp/notifiers/userNotififers.dart';
import 'package:firstflutterapp/notifiers/theme_notifier.dart';
import 'package:go_router/go_router.dart';

class SettingPreferences extends StatefulWidget {
  @override
  _SettingPreferencesState createState() => _SettingPreferencesState();
}

class _SettingPreferencesState extends State<SettingPreferences> {
  bool _isDarkMode = false;
  bool _isSystemTheme = false;
  bool _commentsEnabled = true;
  bool _privateMessagesEnabled = true;
  bool _subscriptionEnabled = true;
  bool _isLoading = true;
  bool _isContentCreator = false;
  final UserSettingsService _settingsService = UserSettingsService();  
  
  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndLoad();
    
    // Ajouter un timeout de sécurité
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
        ToastService.showToast(
          'Timeout - Impossible de charger les préférences',
          ToastificationType.warning,
        );
      }
    });
  }
  
  Future<void> _checkAuthenticationAndLoad() async {
    // Vérifier si l'utilisateur est connecté
    final userNotifier = Provider.of<UserNotifier>(context, listen: false);
    final isAuth = await userNotifier.isAuthenticated();
    
    if (!isAuth) {
      setState(() {
        _isLoading = false;
      });
      ToastService.showToast(
        'Vous devez être connecté pour accéder aux préférences',
        ToastificationType.error,
      );
      // Rediriger vers la page de connexion
      if (mounted) {
        context.go('/login');
      }
      return;
    }
    
    // Si authentifié, charger les préférences
    _loadThemePreference();
    _loadUserSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkUserRole();
    
    // Si on est en mode système, on met à jour l'état du switch selon le thème système actuel
    if (_isSystemTheme) {
      final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
      setState(() {
        _isDarkMode = themeNotifier.isCurrentlyDarkMode(context);
      });
    }
  }

  void _checkUserRole() {
    final userNotifier = Provider.of<UserNotifier>(context, listen: false);
    if (userNotifier.user != null) {
      setState(() {
        _isContentCreator = userNotifier.user!.role == "CONTENT_CREATOR";
      });
    }
  }

  Future<void> _loadThemePreference() async {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    
    setState(() {
      _isSystemTheme = themeNotifier.themeMode == AppThemeMode.system;
      
      // Si on est en mode système, déterminer le mode clair/sombre basé sur le système
      if (_isSystemTheme) {
        _isDarkMode = themeNotifier.isCurrentlyDarkMode(context);
      } else {
        // Sinon, utiliser le mode explicitement défini
        _isDarkMode = themeNotifier.isDarkMode;
      }
    });
  }  Future<void> _loadUserSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading user settings...');
      final response = await _settingsService.getUserSettings();
      print('Response received: success=${response.success}, data=${response.data}');
      
      if (response.success && response.data != null) {
        setState(() {
          _commentsEnabled = response.data!.commentEnabled;
          _privateMessagesEnabled = response.data!.messageEnabled;
          _subscriptionEnabled = response.data!.subscriptionEnabled;
        });
        print('Settings loaded successfully');
      } else {
        print('Error loading settings: ${response.error}');
        ToastService.showToast(
          response.error ?? 'Impossible de charger les préférences',
          ToastificationType.error,
        );
      }
    } catch (e) {
      print('Exception loading settings: $e');
      ToastService.showToast(
        'Une erreur est survenue: $e',
        ToastificationType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _updateCommentsEnabled(bool value) async {
    final oldValue = _commentsEnabled; // Sauvegarder l'ancienne valeur
    
    // Mise à jour optimiste de l'UI
    setState(() {
      _commentsEnabled = value;
    });
    
    try {
      final response = await _settingsService.updateUserSettings(
        commentEnabled: value,
      );

      if (response.success) {
        ToastService.showToast(
          'Préférences de commentaires mises à jour',
          ToastificationType.success,
        );
      } else {
        ToastService.showToast(
          response.error ?? 'Erreur lors de la mise à jour',
          ToastificationType.error,
        );
        // Revenir à l'état précédent en cas d'échec
        setState(() {
          _commentsEnabled = oldValue;
        });
      }
    } catch (e) {
      ToastService.showToast(
        'Une erreur est survenue: $e',
        ToastificationType.error,
      );
      // Revenir à l'état précédent en cas d'échec
      setState(() {
        _commentsEnabled = oldValue;
      });
    }
  }

  Future<void> _updateMessagesEnabled(bool value) async {
    final oldValue = _privateMessagesEnabled; // Sauvegarder l'ancienne valeur
    
    // Mise à jour optimiste de l'UI
    setState(() {
      _privateMessagesEnabled = value;
    });
    
    try {
      final response = await _settingsService.updateUserSettings(
        messageEnabled: value,
      );

      if (response.success) {
        ToastService.showToast(
          'Préférences de messages privés mises à jour',
          ToastificationType.success,
        );
      } else {
        ToastService.showToast(
          response.error ?? 'Erreur lors de la mise à jour',
          ToastificationType.error,
        );
        // Revenir à l'état précédent en cas d'échec
        setState(() {
          _privateMessagesEnabled = oldValue;
        });
      }
    } catch (e) {
      ToastService.showToast(
        'Une erreur est survenue: $e',
        ToastificationType.error,
      );
      // Revenir à l'état précédent en cas d'échec
      setState(() {
        _privateMessagesEnabled = oldValue;
      });
    }
  }

  Future<void> _updateSubscriptionEnabled(bool value) async {
    final oldValue = _subscriptionEnabled; // Sauvegarder l'ancienne valeur
    
    // Mise à jour optimiste de l'UI
    setState(() {
      _subscriptionEnabled = value;
    });
    
    try {
      final response = await _settingsService.updateUserSettings(
        subscriptionEnabled: value,
      );

      if (response.success) {
        ToastService.showToast(
          'Préférences d\'abonnement mises à jour',
          ToastificationType.success,
        );
      } else {
        ToastService.showToast(
          response.error ?? 'Erreur lors de la mise à jour',
          ToastificationType.error,
        );
        // Revenir à l'état précédent en cas d'échec
        setState(() {
          _subscriptionEnabled = oldValue;
        });
      }
    } catch (e) {
      ToastService.showToast(
        'Une erreur est survenue: $e',
        ToastificationType.error,
      );
      // Revenir à l'état précédent en cas d'échec
      setState(() {
        _subscriptionEnabled = oldValue;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Préférences")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Apparence",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SwitchListTile(
                  title: const Text("Thème"),
                  subtitle: _isSystemTheme 
                    ? const Text("Déterminé par le thème système") 
                    : const Text("Choisir entre le thème clair et sombre"),
                  value: _isDarkMode,
                  onChanged: _isSystemTheme 
                    ? null 
                    : (bool value) {
                        final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
                        if (value) {
                          themeNotifier.setDarkTheme();
                        } else {
                          themeNotifier.setLightTheme();
                        }
                        setState(() {
                          _isDarkMode = value;
                        });
                      },
                  secondary: Icon(
                    _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: _isDarkMode ? Colors.amber : Colors.blueGrey,
                  ),
                ),
                SwitchListTile(
                  title: const Text("Thème système"),
                  subtitle: const Text("Utiliser le thème de votre appareil"),
                  value: _isSystemTheme,
                  onChanged: (bool value) {
                    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
                    
                    if (value) {
                      // Activer le thème système
                      themeNotifier.setSystemTheme();
                      // Mettre à jour l'état du switch dark mode pour refléter le thème système actuel
                      setState(() {
                        _isSystemTheme = true;
                        _isDarkMode = themeNotifier.isCurrentlyDarkMode(context);
                      });
                    } else {
                      // Désactiver le thème système et utiliser explicitement light/dark
                      setState(() {
                        _isSystemTheme = false;
                        // Conserver l'état actuel du thème comme base
                        _isDarkMode = themeNotifier.isCurrentlyDarkMode(context);
                      });
                      
                      // Appliquer le thème en fonction de l'état actuel
                      if (_isDarkMode) {
                        themeNotifier.setDarkTheme();
                      } else {
                        themeNotifier.setLightTheme();
                      }
                    }
                  },
                  secondary: Icon(
                    Icons.settings_suggest,
                    color: _isSystemTheme ? Colors.blue : Colors.grey,
                  ),
                ),
                Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Confidentialité",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SwitchListTile(
                  title: const Text("Commentaires"),
                  subtitle: const Text(
                    "Autoriser les commentaires sur vos publications",
                  ),
                  value: _commentsEnabled,
                  onChanged: (bool value) {
                    _updateCommentsEnabled(value);
                  },
                  secondary: Icon(
                    Icons.comment,
                    color: _commentsEnabled ? Colors.green : Colors.grey,
                  ),
                ),                SwitchListTile(
                  title: const Text("Messages privés"),
                  subtitle: const Text("Autoriser les messages privés"),
                  value: _privateMessagesEnabled,
                  onChanged: (bool value) {
                    _updateMessagesEnabled(value);
                  },
                  secondary: Icon(
                    Icons.message,
                    color: _privateMessagesEnabled ? Colors.green : Colors.grey,
                  ),
                ),
                // N'afficher l'option d'abonnement que pour les créateurs de contenu
                if (_isContentCreator)
                  SwitchListTile(
                    title: const Text("Abonnement"),
                    subtitle: const Text("Activer/désactiver les abonnements"),
                    value: _subscriptionEnabled,
                    onChanged: (bool value) {
                      _updateSubscriptionEnabled(value);
                    },
                    secondary: Icon(
                      Icons.monetization_on,
                      color: _subscriptionEnabled ? Colors.green : Colors.grey,
                    ),
                  ),
              ],
            ),
    );
  }
}
