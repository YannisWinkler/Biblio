import 'package:diatek/data/external/api_client.dart';
import 'package:diatek/data/external/tmdb_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late TmdbClient client;

  setUpAll(() {
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    api = MockApiClient();
    client = TmdbClient(readAccessToken: 'unused', apiClient: api);
  });

  group('searchMovies', () {
    test('queries /search/movie and maps results', () async {
      when(() => api.getJson('/search/movie', query: any(named: 'query'))).thenAnswer(
        (_) async => {
          'results': [
            {'id': 1, 'title': 'Arrival'},
          ],
        },
      );

      final results = await client.searchMovies('arrival');

      expect(results, hasLength(1));
      expect(results.single.title, 'Arrival');
      final capturedQuery = verify(() => api.getJson('/search/movie', query: captureAny(named: 'query')))
          .captured
          .single as Map<String, String>;
      expect(capturedQuery, {'query': 'arrival', 'include_adult': 'false'});
    });
  });

  group('nowPlaying', () {
    test('queries /movie/now_playing and maps results', () async {
      when(() => api.getJson('/movie/now_playing')).thenAnswer(
        (_) async => {
          'results': [
            {'id': 2, 'title': 'Dune'},
          ],
        },
      );

      final results = await client.nowPlaying();

      expect(results, hasLength(1));
      expect(results.single.title, 'Dune');
    });
  });

  group('watchProviders', () {
    test('returns providers for the requested region', () async {
      when(() => api.getJson('/movie/1/watch/providers')).thenAnswer(
        (_) async => {
          'results': {
            'FR': {
              'link': 'https://www.themoviedb.org/movie/1/watch',
              'flatrate': [
                {'provider_id': 8, 'provider_name': 'Netflix', 'logo_path': '/netflix.png'},
              ],
            },
          },
        },
      );

      final providers = await client.watchProviders(1);

      expect(providers, isNotNull);
      expect(providers!.flatrate.single.name, 'Netflix');
    });

    test('returns null when TMDB has no data for the region', () async {
      when(() => api.getJson('/movie/1/watch/providers')).thenAnswer(
        (_) async => {
          'results': <String, dynamic>{},
        },
      );

      final providers = await client.watchProviders(1);

      expect(providers, isNull);
    });
  });
}
