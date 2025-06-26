import 'package:flutter/material.dart';
import 'package:firstflutterapp/interfaces/user.dart';
import 'package:go_router/go_router.dart';

class UserSearchResultItem extends StatelessWidget {
  final User user;

  const UserSearchResultItem({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        context.push('/profile/${user.userName}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            Hero(
              tag: 'user-avatar-${user.id}',
              child: CircleAvatar(
                radius: 25,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                backgroundImage: user.profilePicture.isNotEmpty
                    ? NetworkImage(user.profilePicture)
                    : null,
                child: user.profilePicture.isEmpty
                    ? Text(
                        user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.userName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user.firstName.isNotEmpty || user.lastName.isNotEmpty)
                    Text(
                      '${user.firstName} ${user.lastName}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (user.bio.isNotEmpty)
                    Text(
                      user.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            
            // Badge pour les créateurs de contenu
            if (user.role == "CONTENT_CREATOR")
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Créateur',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
