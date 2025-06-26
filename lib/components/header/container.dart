import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firstflutterapp/config/router.dart';
import 'package:provider/provider.dart';
import 'package:firstflutterapp/notifiers/userNotififers.dart';

class Header extends StatefulWidget {
  @override
  _HeaderState createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  Widget _buildHeader() {
    final userNotifier = Provider.of<UserNotifier>(context);
    final userName = userNotifier.user?.userName ?? "Utilisateur";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Salut,", style: TextStyle(fontSize: 16)),
            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // Action pour les notifications
              },
            ),
            IconButton(
              icon: const Icon(Icons.send_outlined),
              onPressed: () {
                context.go(messageRoute);
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildHeader();
  }
}
