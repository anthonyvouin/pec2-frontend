import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/user.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:toastification/toastification.dart';

class FollowingsList extends StatefulWidget {
  const FollowingsList({Key? key}) : super(key: key);

  @override
  State<FollowingsList> createState() => _FollowingsListState();
}

class _FollowingsListState extends State<FollowingsList> {
  List<User> followings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowings();
  }

  Future<void> _loadFollowings() async {
    setState(() { isLoading = true; });
    try {
      final response = await ApiService().request(
        method: 'GET',
        endpoint: '/users/followings',
        withAuth: true,
      );
      if (response.success && response.data is List) {
        setState(() {
          followings = (response.data as List).map((u) => User.fromJson(u)).toList();
        });
      } else {
        ToastService.showToast('Erreur lors du chargement des followings', ToastificationType.error);
      }
    } catch (e) {
      ToastService.showToast('Erreur lors du chargement des followings', ToastificationType.error);
    }
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (followings.isEmpty) {
      return const Center(child: Text('Aucun suivi'));
    }
    return RefreshIndicator(
      onRefresh: _loadFollowings,
      child: ListView.builder(
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
      ),
    );
  }
} 