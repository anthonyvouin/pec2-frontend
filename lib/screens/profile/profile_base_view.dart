import 'package:firstflutterapp/config/router.dart';
import 'package:firstflutterapp/interfaces/user.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/theme.dart';
import 'package:firstflutterapp/screens/creator/creator-view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../notifiers/userNotififers.dart';

class ProfileBaseView extends StatefulWidget {
  final String? username;
  final bool isCurrentUser;

  const ProfileBaseView({
    Key? key, 
    this.username,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  _ProfileBaseViewState createState() => _ProfileBaseViewState();
}

class _ProfileBaseViewState extends State<ProfileBaseView> {
  User? _user;
  String _avatarUrl = "";
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = context.read<UserNotifier>().user;
    
    if (widget.isCurrentUser) {
      _initCurrentUserProfile();
    } else {
      _fetchOtherUserData();
    }
  }

  void _initCurrentUserProfile() {
    if (_currentUser == null) {
      context.go(loginRoute);
      return;
    }    
    setState(() {
      _user = _currentUser;
      if (_user != null && _user!.profilePicture.trim() != "") {
        _avatarUrl = _user!.profilePicture;
      }
      _isLoading = false;
    });
  }

  Future<void> _fetchOtherUserData() async {
    if (widget.username == null) {
      debugPrint("Error: Username is null");
      return;
    }
    
    try {
      final response = await ApiService().request(
        method: 'GET',
        endpoint: '/users/${widget.username}',
        withAuth: true,
      );
      
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _user = User.fromJson(response.data);
          _avatarUrl = _user?.profilePicture ?? "";
          _isLoading = false;
        });
      } else {
        debugPrint("Error fetching user data: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Exception while fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _user?.userName ?? 'Utilisateur',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 8),
          _buildBioSection(),
          const SizedBox(height: 32),
          _buildActionButtons(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(Icons.border_all)],
          ),
          const SizedBox(height: 8),
          Divider(height: 1),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: _avatarUrl != "" 
              ? NetworkImage(_avatarUrl) as ImageProvider
              : const AssetImage('assets/images/dog.webp'),
          backgroundColor: const Color(0xFFE4DAFF),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "10",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text("abonnements", style: TextStyle(fontSize: 10)),
          ],
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "5",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text("abonné(e)s", style: TextStyle(fontSize: 10)),
          ],
        ),
        widget.isCurrentUser
            ? IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  context.push(profileParams);
                },
              )
            : const SizedBox(width: 40), // Placeholder to maintain layout
      ],
    );
  }

  Widget _buildBioSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        _user?.bio ?? "Aucune bio disponible",
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.grey[700],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.isCurrentUser) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (_user != null) {
                    context.push('/profile/edit');
                  }
                },
                style: AppTheme.emptyButtonStyle,
                child: const Text("Modifier le profil"),
              ),
              ElevatedButton(
                onPressed: () {
                  // Statistics feature
                },
                style: AppTheme.emptyButtonStyle,
                child: const Text("Statistiques"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatorView()),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Devenir créateur"),
          ),
        ],
      );
    } else {
      return ElevatedButton(
        onPressed: () {
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        child: const Text("S'abonner"),
      );
    }
  }
}
