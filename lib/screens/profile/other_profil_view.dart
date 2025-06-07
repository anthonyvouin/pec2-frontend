import 'package:firstflutterapp/screens/profile/profile_base_view.dart';
import 'package:flutter/material.dart';

class OtherProfileView extends StatelessWidget {
  final String? username;
  
  const OtherProfileView({Key? key, this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProfileBaseView(
      username: username,
      isCurrentUser: false,
    );
  }
}
