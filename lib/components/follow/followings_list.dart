import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/user.dart';

class FollowingsList extends StatelessWidget {
  final List<User> followings;
  const FollowingsList({Key? key, required this.followings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (followings.isEmpty) {
      return const Center(child: Text('Aucun suivi'));
    }
    return ListView.builder(
      itemCount: followings.length,
      itemBuilder: (context, index) {
        final user = followings[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.profilePicture.isNotEmpty
                ? NetworkImage(user.profilePicture)
                : const AssetImage('assets/images/dog.webp') as ImageProvider,
          ),
          title: Text(user.userName),
          subtitle: Text(user.bio),
        );
      },
    );
  }
} 