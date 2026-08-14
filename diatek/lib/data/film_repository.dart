import 'package:supabase_flutter/supabase_flutter.dart';

import 'external/tmdb_models.dart';
import 'models.dart';

/// Owns every Supabase query touching the 'film' and 'user_film' tables, so
/// table/column names live in exactly one place and the pages stay free of
/// direct database calls.
class FilmRepository {
  const FilmRepository(this._client);

  final SupabaseClient _client;

  /// All films in the catalogue.
  Future<List<Film>> fetchFilms() async {
    final rows = await _client.from('film').select();
    return List<Map<String, dynamic>>.from(rows).map(Film.fromMap).toList();
  }

  /// Maps the id of every film [userId] has added to their list to its
  /// watched status.
  Future<Map<int, bool>> fetchUserFilmStatus(String userId) async {
    final rows = await _client
        .from('user_film')
        .select('id_film, watched')
        .eq('id_user', userId);
    return {
      for (final row in List<Map<String, dynamic>>.from(rows))
        row['id_film'] as int: row['watched'] as bool,
    };
  }

  /// Returns the local film matching [result]'s TMDB id, inserting it into
  /// the catalogue first if this is the first time it's been added.
  ///
  /// Uses an atomic upsert (on the 'film_tmdb_id_key' unique index) rather
  /// than a select-then-insert, so two concurrent calls for the same movie
  /// can't race each other into a duplicate-key error.
  Future<Film> upsertFromTmdb(TmdbMovieResult result) async {
    final row = await _client
        .from('film')
        .upsert({
          'name': result.title,
          'tmdb_id': result.tmdbId,
          'poster_path': result.posterPath,
          'overview': result.overview,
        }, onConflict: 'tmdb_id')
        .select()
        .single();
    return Film.fromMap(row);
  }

  Future<void> addToList(String userId, int filmId) {
    return _client.from('user_film').insert({
      'id_user': userId,
      'id_film': filmId,
      'watched': false,
    });
  }

  Future<void> removeFromList(String userId, int filmId) {
    return _client
        .from('user_film')
        .delete()
        .eq('id_user', userId)
        .eq('id_film', filmId);
  }

  Future<void> setWatched(String userId, int filmId, bool watched) {
    return _client
        .from('user_film')
        .update({'watched': watched})
        .eq('id_user', userId)
        .eq('id_film', filmId);
  }
}
