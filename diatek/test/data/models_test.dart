import 'package:diatek/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Film.fromMap', () {
    test('reads every column', () {
      final film = Film.fromMap({
        'id_film': 1,
        'name': 'Arrival',
        'tmdb_id': 329865,
        'poster_path': '/abc.jpg',
        'overview': 'A linguist deciphers an alien language.',
      });

      expect(film.id, 1);
      expect(film.name, 'Arrival');
      expect(film.tmdbId, 329865);
      expect(film.posterPath, '/abc.jpg');
      expect(film.overview, 'A linguist deciphers an alien language.');
    });

    test('defaults name to Untitled and leaves optional fields null when absent', () {
      final film = Film.fromMap({'id_film': 2, 'name': null});

      expect(film.name, 'Untitled');
      expect(film.tmdbId, isNull);
      expect(film.posterPath, isNull);
      expect(film.overview, isNull);
    });

    test('posterUrl is null without a poster path, and built from it otherwise', () {
      final withoutPoster = Film.fromMap({'id_film': 1, 'name': 'A'});
      final withPoster = Film.fromMap({'id_film': 1, 'name': 'A', 'poster_path': '/abc.jpg'});

      expect(withoutPoster.posterUrl, isNull);
      expect(withPoster.posterUrl, 'https://image.tmdb.org/t/p/w342/abc.jpg');
    });
  });

  group('Profile.fromMap', () {
    test('reads username and avatar', () {
      final profile = Profile.fromMap({'username': 'yannis', 'avatar': 'https://example.com/a.png'});

      expect(profile.username, 'yannis');
      expect(profile.avatarUrl, 'https://example.com/a.png');
    });

    test('leaves fields null when absent', () {
      final profile = Profile.fromMap({});

      expect(profile.username, isNull);
      expect(profile.avatarUrl, isNull);
    });
  });
}
