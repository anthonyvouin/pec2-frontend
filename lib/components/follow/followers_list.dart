import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/user.dart';

class FollowersList extends StatelessWidget {
  final List<User> followers;
  const FollowersList({Key? key, required this.followers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (followers.isEmpty) {
      return const Center(child: Text('Aucun follower'));
    }
    return ListView.builder(
      itemCount: followers.length,
      itemBuilder: (context, index) {
        final user = followers[index];
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