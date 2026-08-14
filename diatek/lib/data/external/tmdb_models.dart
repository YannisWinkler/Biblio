/// Builds a full poster image URL from the `poster_path` TMDB returns
/// (e.g. `/abc123.jpg`). Shared by every model that stores a TMDB poster
/// path, so the image size/host lives in one place.
String tmdbPosterUrl(String posterPath) => 'https://image.tmdb.org/t/p/w342$posterPath';

/// Builds a full provider logo image URL from a `logo_path` TMDB returns.
String tmdbLogoUrl(String logoPath) => 'https://image.tmdb.org/t/p/w92$logoPath';

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

/// A single subscription streaming service (e.g. Netflix) a movie is
/// available on, per TMDB/JustWatch.
class WatchProvider {
  const WatchProvider({required this.id, required this.name, required this.logoPath});

  final int id;
  final String name;
  final String logoPath;

  String get logoUrl => tmdbLogoUrl(logoPath);

  factory WatchProvider.fromJson(Map<String, dynamic> json) => WatchProvider(
        id: json['provider_id'] as int,
        name: json['provider_name'] as String,
        logoPath: json['logo_path'] as String,
      );
}

/// Where a movie can be watched in a single region, per TMDB's watch
/// providers endpoint (sourced from JustWatch). Only subscription streaming
/// ("flatrate") is kept — rent/buy aren't "where to watch it" in the sense
/// the app cares about.
class WatchProviders {
  const WatchProviders({required this.link, required this.flatrate});

  /// JustWatch page for this movie/region, for the required attribution
  /// link and as a fallback when a title isn't available to stream.
  final String? link;
  final List<WatchProvider> flatrate;

  factory WatchProviders.fromJson(Map<String, dynamic> json) => WatchProviders(
        link: json['link'] as String?,
        flatrate: (json['flatrate'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(WatchProvider.fromJson)
            .toList(),
      );
}
