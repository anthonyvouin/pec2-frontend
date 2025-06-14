import 'package:flutter/material.dart';
import 'package:firstflutterapp/services/api_service.dart';
import 'package:firstflutterapp/services/toast_service.dart';
import 'package:toastification/toastification.dart';

class ButtonFollow extends StatefulWidget {
  final String userId;
  final bool isInitiallyFollowed;
  final VoidCallback? onFollowChanged;

  const ButtonFollow({
    Key? key,
    required this.userId,
    required this.isInitiallyFollowed,
    this.onFollowChanged,
  }) : super(key: key);

  @override
  State<ButtonFollow> createState() => _ButtonFollowState();
}

class _ButtonFollowState extends State<ButtonFollow> {
  late bool _isFollowed;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isFollowed = widget.isInitiallyFollowed;
  }

  Future<void> _follow() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService().request(
        method: 'POST',
        endpoint: '/users/${widget.userId}/follow',
        withAuth: true,
      );
      if (response.success) {
        setState(() => _isFollowed = true);
        ToastService.showToast('Utilisateur suivi', ToastificationType.success);
        widget.onFollowChanged?.call();
      } else {
        ToastService.showToast('Erreur lors du follow', ToastificationType.error);
      }
    } catch (e) {
      ToastService.showToast('Erreur réseau', ToastificationType.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _unfollow() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService().request(
        method: 'DELETE',
        endpoint: '/users/${widget.userId}/follow',
        withAuth: true,
      );
      if (response.success) {
        setState(() => _isFollowed = false);
        ToastService.showToast('Utilisateur unfollow', ToastificationType.success);
        widget.onFollowChanged?.call();
      } else {
        ToastService.showToast('Erreur lors du unfollow', ToastificationType.error);
      }
    } catch (e) {
      ToastService.showToast('Erreur réseau', ToastificationType.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _loading
          ? null
          : _isFollowed
              ? _unfollow
              : _follow,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(120, 50),
        backgroundColor: _isFollowed ? Colors.grey : Theme.of(context).primaryColor,
      ),
      child: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(_isFollowed ? 'Ne plus suivre' : 'Suivre'),
    );
  }
}
