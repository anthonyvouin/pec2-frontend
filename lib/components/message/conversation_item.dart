import 'package:flutter/material.dart';

class PrivateMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String status;
  final DateTime createdAt;
  final String senderName;
  final String receiverName;
  final bool isCurrentUser;
  final bool senderMessageEnable;
  final bool receiverMessageEnable;

  PrivateMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.senderName,
    required this.receiverName,
    required this.isCurrentUser,
    this.senderMessageEnable = true,
    this.receiverMessageEnable = true,
  });

  factory PrivateMessage.fromJson(Map<String, dynamic> json) {
    return PrivateMessage(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      senderName: json['senderName'] ?? '',
      receiverName: json['receiverName'] ?? '',
      isCurrentUser: json['isCurrentUser'] ?? false,
      senderMessageEnable: json['senderMessageEnable'] ?? true,
      receiverMessageEnable: json['receiverMessageEnable'] ?? true,
    );
  }
}

class ConversationItem extends StatelessWidget {
  final PrivateMessage message;
  final VoidCallback onTap;

  const ConversationItem({Key? key, required this.message, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final otherPersonName =
        message.isCurrentUser ? message.receiverName : message.senderName;

    final isUnread = message.status == 'UNREAD' && !message.isCurrentUser;

    return ListTile(
      leading: CircleAvatar(
        child: Text(
          otherPersonName.isNotEmpty ? otherPersonName[0].toUpperCase() : '?',
        ),
      ),
      title: Text(
        otherPersonName,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        message.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatDate(message.createdAt),
            style: const TextStyle(fontSize: 12),
          ),
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
  }
}
