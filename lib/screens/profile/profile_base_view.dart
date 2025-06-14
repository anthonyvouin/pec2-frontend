import 'package:firstflutterapp/config/router.dart';
import 'package:firstflutterapp/interfaces/user.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:firstflutterapp/theme.dart';
import 'package:firstflutterapp/screens/creator/creator-view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../notifiers/userNotififers.dart';
import 'package:firstflutterapp/components/follow/followers_list.dart';
import 'package:firstflutterapp/components/follow/followings_list.dart';
import 'package:firstflutterapp/components/follow/button_follow.dart';

class ProfileBaseView extends StatefulWidget {
  final String? username;
  final bool isCurrentUser;

  const ProfileBaseView({Key? key, this.username, required this.isCurrentUser})
    : super(key: key);

  @override
  _ProfileBaseViewState createState() => _ProfileBaseViewState();
}

class _ProfileBaseViewState extends State<ProfileBaseView> {
  User? _user;
  String _avatarUrl = "";
  User? _currentUser;
  bool _isLoading = true;
  bool _isSubscriber = false;
  String? _stripeLink;
  bool _subcriptionCanceled = false;
  DateTime? _subscriptionCanceledAt;
  int _followersCount = 0;
  int _followingsCount = 0;
  bool _isFollowed = false;

  final ApiService _apiService = ApiService();

  Future<void> _fetchFollowCounts() async {
    try {
      final response = await _apiService.request(
        method: 'GET',
        endpoint: '/users/id/${_user?.id ?? widget.username}/follow-counts',
        withAuth: true,
      );
      if (response.statusCode == 200) {
        setState(() {
          _followersCount = response.data['followers'] ?? 0;
          _followingsCount = response.data['followings'] ?? 0;
        });
      }
    } catch (e) {
    }
  }

  @override
  void initState() {
    super.initState();
    _currentUser = context.read<UserNotifier>().user;

    if (widget.isCurrentUser) {
      _initCurrentUserProfile();
    } else {
      _fetchOtherUserData();
    }
    _fetchFollowCounts();
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

  Future<void> _getStripeLink() async {
    if (_user != null) {
      final ApiResponse response = await _apiService.request(
        method: 'Post',
        endpoint: '/subscriptions/checkout/${_user?.id!}',
        withAuth: true,
      );

      if (response.success) {
        setState(() {
          _stripeLink = response.data['url'];
        });
      }
    }
  }

  Future<void> _fetchOtherUserData() async {
    if (widget.username == null) {
      debugPrint("Error: Username is null");
      return;
    }

    try {
      final response = await _apiService.request(
        method: 'GET',
        endpoint: '/users/${widget.username}',
        withAuth: true,
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _user = User.fromJson(response.data['user']);
          _isSubscriber = response.data['isSubscriberToSearchUser'];
          _subcriptionCanceled = response.data['canceledSubscription'] ?? false;
          _subscriptionCanceledAt =
              response.data['subscriberUntil'] != null
                  ? DateTime.parse(response.data['subscriberUntil'])
                  : null;
          _avatarUrl = _user?.profilePicture ?? "";
          _isLoading = false;
          _isFollowed = response.data['isFollowed'] ?? false;
        });

        if (!_isSubscriber) {
          await _getStripeLink();
        }
      } else {
        debugPrint("Error fetching user data: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Exception while fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSubscription() async {
    setState(() {
      _isLoading = true;
    });
    final ApiResponse response = await _apiService.request(
      method: "Delete",
      endpoint: "/subscriptions/${_user?.id}",
    );
    if (response.success) {
      ToastService.showToast(
        "désabonnement validé",
        ToastificationType.success,
      );
      setState(() {
        _subcriptionCanceled = true;
        _subscriptionCanceledAt =
            response.data['endDate'] != null
                ? DateTime.parse(response.data['endDate'])
                : null;
        _isLoading = false;
      });
    } else {
      ToastService.showToast(
        "Erreur lors du désabonnement",
        ToastificationType.error,
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _showFollowModal(BuildContext context, bool showFollowers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: DefaultTabController(
            length: 2,
            initialIndex: showFollowers ? 1 : 0,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Followings'),
                    Tab(text: 'Followers'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      FollowingsList(userId: _user?.id ?? ""),
                      FollowersList(userId: _user?.id ?? ""),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      body:
          _isLoading
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
          backgroundImage:
              _avatarUrl != ""
                  ? NetworkImage(_avatarUrl) as ImageProvider
                  : const AssetImage('assets/images/dog.webp'),
          backgroundColor: const Color(0xFFE4DAFF),
        ),
        GestureDetector(
          onTap: () => _showFollowModal(context, false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _followingsCount.toString(),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text("Followings", style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: () => _showFollowModal(context, true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _followersCount.toString(),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text("Followers", style: TextStyle(fontSize: 10)),
            ],
          ),
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
      return Row(
        children: [
          ButtonFollow(
            userId: _user?.id ?? '',
            isInitiallyFollowed: _isFollowed,
            onFollowChanged: () {
              _fetchFollowCounts();
              _fetchOtherUserData();
            },
          ),
          const SizedBox(width: 10),

          if (_user?.role == "CONTENT_CREATOR" && !_subcriptionCanceled)
            ElevatedButton(
              onPressed: () async {
                if (!_isSubscriber && _stripeLink != null) {
                  final url = Uri.parse(_stripeLink!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                } else {
                  _deleteSubscription();
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 50),
                backgroundColor:
                    _isSubscriber ? Colors.red : Theme.of(context).primaryColor,
              ),
              child: Text(_isSubscriber ? "Se désabonner" : "S'abonner"),
            ),

          if (_subcriptionCanceled && _subscriptionCanceledAt != null)
            Text(
              "Abonné jusqu'au ${DateFormat('dd/MM/yyyy').format(_subscriptionCanceledAt!)}",
            ),
        ],
      );
    }
  }
}
