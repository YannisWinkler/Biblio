import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Owns every Supabase query touching the 'profile' table.
class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile> fetchProfile(String userId) async {
    final row =
        await _client.from('profile').select().eq('id', userId).single();
    return Profile.fromMap(row);
  }

  Future<void> createProfile({
    required String userId,
    required String username,
  }) {
    return _client.from('profile').insert({
      'id': userId,
      'username': username,
    });
  }
}
