import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:firstflutterapp/services/user_settings_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:toastification/toastification.dart';
import 'package:provider/provider.dart';
import 'package:firstflutterapp/notifiers/userNotififers.dart';
import 'package:firstflutterapp/interfaces/user.dart';

class SettingPreferences extends StatefulWidget {
  @override
  _SettingPreferencesState createState() => _SettingPreferencesState();
}

class _SettingPreferencesState extends State<SettingPreferences> {  bool _isDarkMode = false;
  bool _commentsEnabled = true;
  bool _privateMessagesEnabled = true;
  bool _subscriptionEnabled = true;
  bool _isLoading = true;
  bool _isContentCreator = false;
  final UserSettingsService _settingsService = UserSettingsService();  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _loadUserSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkUserRole();
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
    final savedThemeMode = await AdaptiveTheme.getThemeMode();
    setState(() {
      _isDarkMode = savedThemeMode == AdaptiveThemeMode.dark;
    });
  }  Future<void> _loadUserSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _settingsService.getUserSettings();
      
      if (response.success && response.data != null) {        setState(() {
          _commentsEnabled = response.data!.commentEnabled;
          _privateMessagesEnabled = response.data!.messageEnabled;
          _subscriptionEnabled = response.data!.subscriptionEnabled;
        });
      } else {
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
    try {
      final response = await _settingsService.updateUserSettings(
        commentEnabled: value,
      );

      if (response.success) {
        setState(() {
          _commentsEnabled = value;
        });
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
          _commentsEnabled = !value;
        });
      }
    } catch (e) {
      ToastService.showToast(
        'Une erreur est survenue: $e',
        ToastificationType.error,
      );
      // Revenir à l'état précédent en cas d'échec
      setState(() {
        _commentsEnabled = !value;
      });
    }
  }

  Future<void> _updateMessagesEnabled(bool value) async {
    try {
      final response = await _settingsService.updateUserSettings(
        messageEnabled: value,
      );

      if (response.success) {
        setState(() {
          _privateMessagesEnabled = value;
        });
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
          _privateMessagesEnabled = !value;
        });
      }
    } catch (e) {
      ToastService.showToast(
        'Une erreur est survenue: $e',
        ToastificationType.error,
      );
      // Revenir à l'état précédent en cas d'échec
      setState(() {
        _privateMessagesEnabled = !value;
      });
    }
  }

  Future<void> _updateSubscriptionEnabled(bool value) async {
    try {
      final response = await _settingsService.updateUserSettings(
        subscriptionEnabled: value,
      );

      if (response.success) {
        setState(() {
          _subscriptionEnabled = value;
        });
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
          _subscriptionEnabled = !value;
        });
      }
    } catch (e) {
      ToastService.showToast(
        'Une erreur est survenue: $e',
        ToastificationType.error,
      );
      // Revenir à l'état précédent en cas d'échec
      setState(() {
        _subscriptionEnabled = !value;
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
                  title: const Text("Mode sombre"),
                  subtitle: const Text("Activer/désactiver le thème sombre"),
                  value: _isDarkMode,
                  onChanged: (bool value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                    if (value) {
                      AdaptiveTheme.of(context).setDark();
                    } else {
                      AdaptiveTheme.of(context).setLight();
                    }
                  },
                  secondary: Icon(
                    _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: _isDarkMode ? Colors.amber : Colors.blueGrey,
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
