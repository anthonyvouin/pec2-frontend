import 'package:flutter/material.dart';
import 'package:firstflutterapp/components/message/conversation_item.dart';

class MessageBubble extends StatelessWidget {
  final PrivateMessage message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrentUser = message.isCurrentUser;
    
    final backgroundColor = isCurrentUser 
        ? colorScheme.primary 
        : colorScheme.surfaceContainerHighest;
    final textColor = isCurrentUser 
        ? colorScheme.onPrimary 
        : colorScheme.onSurface;
    final timeColor = isCurrentUser 
        ? colorScheme.onPrimary.withValues(alpha: 0.7)
        : colorScheme.onSurfaceVariant;
    
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content, 
              style: TextStyle(fontSize: 16, color: textColor)
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(message.createdAt),
              style: TextStyle(fontSize: 12, color: timeColor),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
