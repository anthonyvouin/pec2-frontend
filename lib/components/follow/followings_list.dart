import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/interfaces/user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FollowingsList extends StatefulWidget {
  final String searchUser;
  const FollowingsList({Key? key, required this.searchUser}) : super(key: key);
  @override
  State<FollowingsList> createState() => _FollowingsListState();
}

class _FollowingsListState extends State<FollowingsList> {
  List<User> _followings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFollowings();
  }

  Future<void> _fetchFollowings() async {
    try {
      final response = await ApiService().request(
        method: 'GET',
        endpoint: '/users/followings?userSearch=${widget.searchUser}',
        withAuth: true,
      );
      setState(() {
        _followings = (response.data as List).map((u) => User.fromJson(u)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_followings.isEmpty) {
      return const Center(child: Text('Aucun suivi'));
    }
    return ListView.builder(
      itemCount: _followings.length,
      itemBuilder: (context, index) {
        final user = _followings[index];
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