import 'package:firstflutterapp/components/feed/profile_feed.dart';
import 'package:firstflutterapp/config/router.dart';
import 'package:firstflutterapp/interfaces/user.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:firstflutterapp/theme.dart';
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
  bool isFree = true;
  bool _isAlreadyCreator = false;

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
      } else {
        ToastService.showToast(
          "Impossible de récupérer les follows",
          ToastificationType.error,
        );
      }
    } catch (e) {
      ToastService.showToast(
        "Impossible de récupérer les follows",
        ToastificationType.error,
      );
    }
  }

  Future<void> _getInscription() async {
    try {
      final response = await _apiService.request(
        method: 'GET',
        endpoint: '/content-creators',
        withAuth: true,
      );
      if (response.statusCode == 200) {
        setState(() {
          _isAlreadyCreator = response.data != null;
        });
      }
    } catch (e) {
      ToastService.showToast(
        "Impossible de récupérer l'inscription",
        ToastificationType.error,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _currentUser = context.read<UserNotifier>().user;
    _getInscription();


    if (widget.isCurrentUser || (widget.username == _currentUser?.userName)) {
      _initCurrentUserProfile();
      _fetchFollowingsAndSync();
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
    _fetchFollowCounts();
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
        await _fetchFollowCounts();
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

  void _showFollowModal(BuildContext context, bool showFollowers) async {
    await showModalBottomSheet(
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
                TabBar(
                  labelColor: AppTheme.darkColor,
                  tabs: const [Tab(text: 'Followings'), Tab(text: 'Followers')],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      FollowingsList(searchUser: _user?.id ?? ""),
                      FollowersList(searchUser: _user?.id ?? ""),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    await _fetchFollowingsAndSync();
    await _fetchFollowCounts();
    await _fetchOtherUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : AppTheme.darkColor,
          ),
        ),
        actions:
            widget.isCurrentUser
                ? [
                  IconButton(
                    onPressed: () => context.goNamed("statistic-creator"),
                    icon: Icon(
                      Icons.timeline,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : AppTheme.darkColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_user != null) {
                        context.goNamed('edit-profile');
                      }
                    },
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : AppTheme.darkColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.goNamed("messages"),
                    icon: Icon(
                      Icons.mail_outline,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : AppTheme.darkColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : AppTheme.darkColor,
                    ),
                    onPressed: () {
                      context.push(profileParams);
                    },
                  ),
                ]
                : [],
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.darkColor),
                  ),
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundImage:
                  _avatarUrl != ""
                      ? NetworkImage(_avatarUrl) as ImageProvider
                      : const AssetImage('assets/images/dog.webp'),
              backgroundColor: const Color(0xFFE4DAFF),
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  _user?.userName != null
                      ? '@${_user!.userName}'
                      : '@utilisateur',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCounter(
                'Following',
                _followingsCount,
                () => _showFollowModal(context, false),
              ),
              _verticalDivider(),
              _buildCounter(
                'Follower',
                _followersCount,
                () => _showFollowModal(context, true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _user?.bio ?? "Aucune bio disponible",
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButtons(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    isFree = true;
                  });
                },
                child: Icon(
                  Icons.border_all,
                  color: isFree == true ? AppTheme.darkColor : Theme.of(context).iconTheme.color,
                ),
              ),
              SizedBox(width: 16),
              _verticalDivider(),
              SizedBox(width: 16),
              if (_user != null && _user!.role == "CONTENT_CREATOR")
                InkWell(
                  onTap: () {
                    setState(() {
                      isFree = false;
                    });
                  },
                  child: Icon(
                    Icons.paid,
                    color: isFree == false ? AppTheme.darkColor : Theme.of(context).iconTheme.color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1),
          const SizedBox(height: 8),
          ProfileFeed(currentUser: widget.isCurrentUser, isFree: isFree, userId: _user!.id,isSubscriber: _isSubscriber),
        ],
      ),
    );
  }

  Widget _buildCounter(String label, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12, 
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 28, 
      width: 1.2, 
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildActionButtons() {
    if (widget.isCurrentUser || (_user?.userName == _currentUser?.userName)) {
      return Column(
        children: [
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.goNamed('profile-creator');
            },
            child: Text(_isAlreadyCreator?"Modifier ma fiche créateur":"Devenir créateur"),
          ),
          const SizedBox(height: 16),
        ],
      );
    } else {
      final followedUserIds = context.watch<UserNotifier>().followedUserIds;
      final isFollowed = followedUserIds.contains(_user?.id);
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ButtonFollow(
                key: ValueKey(widget.username ?? ''),
                userId: _user?.id ?? '',
                isInitiallyFollowed: isFollowed,
                onFollowChanged: () async {
                  await _fetchFollowingsAndSync();
                  _fetchFollowCounts();
                  _fetchOtherUserData();
                },              ),
              const SizedBox(width: 10),
              // Afficher le bouton d'abonnement uniquement si l'utilisateur accepte les abonnements
              if (_user?.role == "CONTENT_CREATOR" && !_subcriptionCanceled && _user?.subscriptionEnabled == true)
                ElevatedButton(
                  onPressed: () async {
                    if (!_isSubscriber && _stripeLink != null) {
                      final url = Uri.parse(_stripeLink!);
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                    } else {
                      _deleteSubscription();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 50),
                    backgroundColor:
                        _isSubscriber
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                  ),
                  child: Text(_isSubscriber ? "Se désabonner" : "S'abonner"),
                ),
              if (_subcriptionCanceled && _subscriptionCanceledAt != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.darkColor.withOpacity(0.1),
                        AppTheme.darkColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.darkColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.darkColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.darkColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.schedule,
                          size: 18,
                          color: AppTheme.darkColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Abonné jusqu'au ${DateFormat('dd/MM/yyyy').format(_subscriptionCanceledAt!)}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_user?.messageEnabled == true && !widget.isCurrentUser)
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final TextEditingController _msgController =
                      TextEditingController();
                  bool sending = false;
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: Text(
                          'Envoyer un message à @${_user?.userName ?? ''}',
                        ),
                        content: TextField(
                          controller: _msgController,
                          decoration: const InputDecoration(
                            hintText: 'Votre message...',
                          ),
                          minLines: 1,
                          maxLines: 5,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed:
                                sending
                                    ? null
                                    : () async {
                                      if (_msgController.text.trim().isEmpty)
                                        return;
                                      setState(() => sending = true);
                                      final ApiService api = ApiService();
                                      final resp = await api.request(
                                        method: 'POST',
                                        endpoint: '/private-messages',
                                        withAuth: true,
                                        body: {
                                          'receiverUserName': _user?.userName,
                                          'content': _msgController.text.trim(),
                                        },
                                      );
                                      setState(() => sending = false);
                                      if (resp.success) {
                                        Navigator.pop(context);
                                        ToastService.showToast(
                                          'Message envoyé !',
                                          ToastificationType.success,
                                        );
                                      } else {
                                        ToastService.showToast(
                                          'Erreur : ${(resp.error ?? 'envoi impossible}' )}',
                                          ToastificationType.error,
                                        );
                                      }
                                },
                            child:
                                sending
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text('Envoyer'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            icon: const Icon(Icons.mail_outline),
            label: const Text('Envoyer un message'),
            style: AppTheme.emptyButtonStyle,
          ),
        ],
      );
    }
  }

  Future<void> _fetchFollowingsAndSync() async {
    try {
      final response = await _apiService.request(
        method: 'GET',
        endpoint: '/users/followings',
        withAuth: true,
      );
      if (response.statusCode == 200 && response.data is List) {
        final ids =
            (response.data as List)
                .map((u) => u['id']?.toString() ?? "")
                .where((id) => id.isNotEmpty)
                .toList();
        context.read<UserNotifier>().setFollowedUserIds(ids);
      }
    } catch (e) {
      // ignore
    }
  }
}
