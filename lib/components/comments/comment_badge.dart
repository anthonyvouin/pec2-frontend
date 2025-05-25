import 'package:flutter/material.dart';

class CommentBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  
  const CommentBadge({
    Key? key, 
    required this.count,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat, size: 16),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
