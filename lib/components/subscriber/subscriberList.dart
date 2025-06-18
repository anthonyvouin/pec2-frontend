import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/interfaces/user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../interfaces/user_stats.dart';

class SubscribersList extends StatefulWidget {
  final List<UserNameStat> subscribers;
  const SubscribersList({Key? key, required this.subscribers}) : super(key: key);
  @override
  State<SubscribersList> createState() => _SubscribersListState();
}

class _SubscribersListState extends State<SubscribersList> {
  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.subscribers.length,
      itemBuilder: (context, index) {
        final user = widget.subscribers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.profilePicture != null
                ? NetworkImage(user.profilePicture!)
                : const AssetImage('assets/images/dog.webp') as ImageProvider,
          ),
          title: Text(user.userName),
          onTap: () {
            context.push('/profile/${user.userName}');
          },

        );
      },
    );
  }
}