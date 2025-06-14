import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/user.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:toastification/toastification.dart';

class FollowersList extends StatefulWidget {
  const FollowersList({Key? key}) : super(key: key);

  @override
  State<FollowersList> createState() => _FollowersListState();
}

class _FollowersListState extends State<FollowersList> {
  List<User> followers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() { isLoading = true; });
    try {
      final response = await ApiService().request(
        method: 'GET',
        endpoint: '/users/followers',
        withAuth: true,
      );
      if (response.success && response.data is List) {
        setState(() {
          followers = (response.data as List).map((u) => User.fromJson(u)).toList();
        });
      } else {
        ToastService.showToast('Erreur lors du chargement des followers', ToastificationType.error);
      }
    } catch (e) {
      ToastService.showToast('Erreur lors du chargement des followers', ToastificationType.error);
    }
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (followers.isEmpty) {
      return const Center(child: Text('Aucun follower'));
    }
    return RefreshIndicator(
      onRefresh: _loadFollowers,
      child: ListView.builder(
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
      ),
    );
  }
} 