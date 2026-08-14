import 'api_client.dart';
import 'tmdb_models.dart';

/// TMDB-specific endpoints, built on the generic [ApiClient]. Movie search
/// today; other TMDB endpoints (or other external sources entirely) can be
/// added the same way without touching [ApiClient].
class TmdbClient {
  TmdbClient({required String readAccessToken})
      : _api = ApiClient(
          baseUrl: 'https://api.themoviedb.org/3',
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
    final results = (json['results'] as List).cast<Map<String, dynamic>>();
    return results.map(TmdbMovieResult.fromJson).toList();
  }
}
