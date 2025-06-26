import 'package:firstflutterapp/config/router.dart';
import 'package:firstflutterapp/notifiers/userNotififers.dart';
import 'package:firstflutterapp/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingUser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Paramètres")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                context.goNamed('update-password');
              },
              style: AppTheme.emptyButtonStyle.merge(
                ElevatedButton.styleFrom(fixedSize: const Size(300, 50)),
              ),
              child: const Text("Changer le mot de passe"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.goNamed('support');
              },
              style: AppTheme.emptyButtonStyle.merge(
                ElevatedButton.styleFrom(fixedSize: const Size(300, 50)),
              ),
              child: const Text("Demande/Support"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.goNamed('preferences');
              },
              style: AppTheme.emptyButtonStyle.merge(
                ElevatedButton.styleFrom(fixedSize: const Size(300, 50)),
              ),
              child: const Text("Préférences"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.goNamed('subscriptions');
              },
              style: AppTheme.emptyButtonStyle.merge(
                ElevatedButton.styleFrom(fixedSize: const Size(300, 50)),
              ),
              child: const Text("Mes abonnements"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final userNotifier = context.read<UserNotifier>();
                userNotifier.logout();
                if (context.mounted) {
                  context.go(loginRoute);
                }
              },
              style: AppTheme.filledButtonStyle.merge(
                ElevatedButton.styleFrom(fixedSize: const Size(300, 50)),
              ),
              child: const Text("Deconnexion"),
            ),
          ],
        ),
      ),
    );
  }
}
