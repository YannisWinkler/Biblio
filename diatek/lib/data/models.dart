import 'external/tmdb_models.dart';

/// A row from the 'film' table.
class Film {
  const Film({
    required this.id,
    required this.name,
    this.tmdbId,
    this.posterPath,
    this.overview,
  });

  final int id;
  final String name;

  /// Null for films added before TMDB linking existed, or entered by hand.
  final int? tmdbId;
  final String? posterPath;
  final String? overview;

  /// Full poster URL, or null if this film has no poster on file.
  String? get posterUrl => posterPath == null ? null : tmdbPosterUrl(posterPath!);

  factory Film.fromMap(Map<String, dynamic> map) => Film(
        id: map['id_film'] as int,
        name: map['name'] as String? ?? 'Untitled',
        tmdbId: map['tmdb_id'] as int?,
        posterPath: map['poster_path'] as String?,
        overview: map['overview'] as String?,
      );
}

/// A row from the 'profile' table.
class Profile {
  const Profile({this.username, this.avatarUrl});

  final String? username;
  final String? avatarUrl;

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        username: map['username'] as String?,
        avatarUrl: map['avatar'] as String?,
      );
}
