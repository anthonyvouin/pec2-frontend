import 'package:firstflutterapp/screens/profile/profile_base_view.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ProfileBaseView(
      isCurrentUser: true,
    );
  }
}
