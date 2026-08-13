import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models.dart';

/// Shows the signed-in user's name and avatar; tapping the avatar reveals
/// the sign-out option.
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key, required this.profileFuture});

  final Future<Profile> profileFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(
      future: profileFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final username = profile?.username;
        final avatarUrl = profile?.avatarUrl;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (username != null) Text(username),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Account',
              onSelected: (_) => Supabase.instance.client.auth.signOut(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'logout', child: Text('Sign out')),
              ],
              child: CircleAvatar(
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}
