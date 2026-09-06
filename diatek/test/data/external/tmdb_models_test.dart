import 'package:diatek/data/external/tmdb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tmdbPosterUrl builds a w342 image URL', () {
    expect(tmdbPosterUrl('/abc.jpg'), 'https://image.tmdb.org/t/p/w342/abc.jpg');
  });

  test('tmdbLogoUrl builds a w92 image URL', () {
    expect(tmdbLogoUrl('/logo.png'), 'https://image.tmdb.org/t/p/w92/logo.png');
  });

  group('TmdbMovieResult.fromJson', () {
    test('reads every field', () {
      final result = TmdbMovieResult.fromJson({
        'id': 329865,
        'title': 'Arrival',
        'poster_path': '/abc.jpg',
        'overview': 'A linguist deciphers an alien language.',
      });

      expect(result.tmdbId, 329865);
      expect(result.title, 'Arrival');
      expect(result.posterUrl, 'https://image.tmdb.org/t/p/w342/abc.jpg');
      expect(result.overview, 'A linguist deciphers an alien language.');
    });

    test('defaults title to Untitled and posterUrl to null when absent', () {
      final result = TmdbMovieResult.fromJson({'id': 1, 'title': null});

      expect(result.title, 'Untitled');
      expect(result.posterUrl, isNull);
    });
  });

  group('WatchProvider.fromJson', () {
    test('reads id, name and builds the logo URL', () {
      final provider = WatchProvider.fromJson({
        'provider_id': 8,
        'provider_name': 'Netflix',
        'logo_path': '/netflix.png',
      });

      expect(provider.id, 8);
      expect(provider.name, 'Netflix');
      expect(provider.logoUrl, 'https://image.tmdb.org/t/p/w92/netflix.png');
    });
  });

  group('WatchProviders.fromJson', () {
    test('reads the link and flatrate list', () {
      final providers = WatchProviders.fromJson({
        'link': 'https://www.themoviedb.org/movie/1/watch',
        'flatrate': [
          {'provider_id': 8, 'provider_name': 'Netflix', 'logo_path': '/netflix.png'},
        ],
      });

      expect(providers.link, 'https://www.themoviedb.org/movie/1/watch');
      expect(providers.flatrate, hasLength(1));
      expect(providers.flatrate.single.name, 'Netflix');
    });

    test('defaults link and flatrate when absent, ignoring rent/buy-only regions', () {
      final providers = WatchProviders.fromJson({});

      expect(providers.link, isNull);
      expect(providers.flatrate, isEmpty);
    });
  });
}
