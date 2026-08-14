/// Builds a full poster image URL from the `poster_path` TMDB returns
/// (e.g. `/abc123.jpg`). Shared by every model that stores a TMDB poster
/// path, so the image size/host lives in one place.
String tmdbPosterUrl(String posterPath) => 'https://image.tmdb.org/t/p/w342$posterPath';

/// A single result from a TMDB movie search, before it's been imported
/// into the local catalogue.
class TmdbMovieResult {
  const TmdbMovieResult({
    required this.tmdbId,
    required this.title,
    this.posterPath,
    this.overview,
  });

  final int tmdbId;
  final String title;
  final String? posterPath;
  final String? overview;

  /// Full poster URL, or null if TMDB has no poster for this movie.
  String? get posterUrl => posterPath == null ? null : tmdbPosterUrl(posterPath!);

  factory TmdbMovieResult.fromJson(Map<String, dynamic> json) => TmdbMovieResult(
        tmdbId: json['id'] as int,
        title: json['title'] as String? ?? 'Untitled',
        posterPath: json['poster_path'] as String?,
        overview: json['overview'] as String?,
      );
}
