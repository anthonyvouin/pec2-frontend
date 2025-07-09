import 'package:flutter/material.dart';

class CommentBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final bool commentEnabled; // Now passed directly from post
  
  const CommentBadge({
    Key? key, 
    required this.count,
    required this.onTap,
    required this.commentEnabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!commentEnabled) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat),
            const SizedBox(width: 8),
            Text(
              count.toString(),
              style: TextStyle(
                // fontWeight: FontWeight.bold,
                color: Theme.of(context).iconTheme.color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
