import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/interfaces/user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FollowersList extends StatefulWidget {
  final String userId;
  const FollowersList({Key? key, required this.userId}) : super(key: key);

  @override
  State<FollowersList> createState() => _FollowersListState();
}

class _FollowersListState extends State<FollowersList> {
  List<User> _followers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    try {
      final response = await ApiService().request(
        method: 'GET',
        endpoint: '/users/followers',
        withAuth: true,
      );
      setState(() {
        _followers = (response.data as List).map((u) => User.fromJson(u)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_followers.isEmpty) {
      return const Center(child: Text('Aucun follower'));
    }
    return ListView.builder(
      itemCount: _followers.length,
      itemBuilder: (context, index) {
        final user = _followers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.profilePicture.isNotEmpty
                ? NetworkImage(user.profilePicture)
                : const AssetImage('assets/images/dog.webp') as ImageProvider,
          ),
          title: Text(user.userName),
          subtitle: Text(user.bio),
          onTap: () {
            context.push('/profile/${user.userName}');
          },
        );
      },
    );
  }
} 