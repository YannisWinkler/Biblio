import 'api_client.dart';
import 'tmdb_models.dart';

/// TMDB-specific endpoints, built on the generic [ApiClient]. Movie search
/// today; other TMDB endpoints (or other external sources entirely) can be
/// added the same way without touching [ApiClient].
class TmdbClient {
  TmdbClient({required String readAccessToken})
      : _api = ApiClient(
          baseUrl: 'https://api.themoviedb.org/3?language=fr-FR',
          headers: {
            'Authorization': 'Bearer $readAccessToken',
            'Accept': 'application/json',
          },
        );

  final ApiClient _api;

  /// Searches TMDB's movie catalogue for [query], most relevant first.
  Future<List<TmdbMovieResult>> searchMovies(String query) async {
    final json = await _api.getJson(
      '/search/movie',
      query: {'query': query, 'include_adult': 'false'},
    );
    return _movieResultsFrom(json);
  }

  /// Movies currently in theaters, per TMDB.
  Future<List<TmdbMovieResult>> nowPlaying() async {
    final json = await _api.getJson('/movie/now_playing');
    return _movieResultsFrom(json);
  }

  /// Where [tmdbId] can be streamed in [region] (ISO 3166-1 alpha-2, e.g.
  /// 'FR'), or null if TMDB has no data for that region.
  Future<WatchProviders?> watchProviders(int tmdbId, {String region = 'FR'}) async {
    final json = await _api.getJson('/movie/$tmdbId/watch/providers');
    final results = json['results'] as Map<String, dynamic>? ?? const {};
    final regionJson = results[region] as Map<String, dynamic>?;
    return regionJson == null ? null : WatchProviders.fromJson(regionJson);
  }

  List<TmdbMovieResult> _movieResultsFrom(Map<String, dynamic> json) {
    final results = (json['results'] as List).cast<Map<String, dynamic>>();
    return results.map(TmdbMovieResult.fromJson).toList();
  }
}
