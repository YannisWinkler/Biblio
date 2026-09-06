import 'package:diatek/data/external/tmdb_models.dart';
import 'package:diatek/data/film_repository.dart';
import 'package:diatek/data/models.dart';
import 'package:diatek/state/user_films_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFilmRepository extends Mock implements FilmRepository {}

void main() {
  const userId = 'user-1';
  const arrival = Film(id: 1, name: 'Arrival', tmdbId: 100);
  const dune = Film(id: 2, name: 'Dune', tmdbId: 200);
  const tmdbResult = TmdbMovieResult(tmdbId: 300, title: 'Interstellar');

  late MockFilmRepository repository;
  late UserFilmsController controller;

  setUpAll(() {
    registerFallbackValue(tmdbResult);
  });

  setUp(() {
    repository = MockFilmRepository();
    controller = UserFilmsController(repository: repository, userId: userId);
  });

  group('load', () {
    test('populates the catalogue and watched status on success', () async {
      when(() => repository.fetchFilms()).thenAnswer((_) async => [arrival, dune]);
      when(() => repository.fetchUserFilmStatus(userId)).thenAnswer((_) async => {1: false});

      await controller.load();

      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
      expect(controller.allFilms, [arrival, dune]);
      expect(controller.userFilms, [arrival]);
      expect(controller.isInList(1), isTrue);
      expect(controller.isInList(2), isFalse);
      expect(controller.isWatched(1), isFalse);
    });

    test('exposes the error and stops loading on failure', () async {
      when(() => repository.fetchFilms()).thenThrow(Exception('network down'));
      when(() => repository.fetchUserFilmStatus(userId)).thenAnswer((_) async => {});

      await controller.load();

      expect(controller.isLoading, isFalse);
      expect(controller.error, isNotNull);
      expect(controller.allFilms, isEmpty);
    });
  });

  group('setInList', () {
    setUp(() async {
      when(() => repository.fetchFilms()).thenAnswer((_) async => [arrival]);
      when(() => repository.fetchUserFilmStatus(userId)).thenAnswer((_) async => {});
      await controller.load();
    });

    test('adds the film immediately and persists it', () async {
      when(() => repository.addToList(userId, 1)).thenAnswer((_) async {});

      final error = await controller.setInList(1, true);

      expect(error, isNull);
      expect(controller.isInList(1), isTrue);
      expect(controller.isWatched(1), isFalse);
      verify(() => repository.addToList(userId, 1)).called(1);
    });

    test('rolls back if persisting the add fails', () async {
      when(() => repository.addToList(userId, 1)).thenThrow(Exception('offline'));

      final error = await controller.setInList(1, true);

      expect(error, isNotNull);
      expect(controller.isInList(1), isFalse);
    });

    test('rolls back to the previous watched state if removing fails', () async {
      when(() => repository.addToList(userId, 1)).thenAnswer((_) async {});
      await controller.setInList(1, true);
      when(() => repository.setWatched(userId, 1, true)).thenAnswer((_) async {});
      await controller.toggleWatched(1);
      expect(controller.isWatched(1), isTrue);

      when(() => repository.removeFromList(userId, 1)).thenThrow(Exception('offline'));
      final error = await controller.setInList(1, false);

      expect(error, isNotNull);
      expect(controller.isInList(1), isTrue);
      expect(controller.isWatched(1), isTrue);
    });
  });

  group('addFromTmdb', () {
    setUp(() async {
      when(() => repository.fetchFilms()).thenAnswer((_) async => []);
      when(() => repository.fetchUserFilmStatus(userId)).thenAnswer((_) async => {});
      await controller.load();
    });

    test('imports a new film into the catalogue and adds it to the list', () async {
      const imported = Film(id: 3, name: 'Interstellar', tmdbId: 300);
      when(() => repository.upsertFromTmdb(tmdbResult)).thenAnswer((_) async => imported);
      when(() => repository.addToList(userId, 3)).thenAnswer((_) async {});

      final error = await controller.addFromTmdb(tmdbResult);

      expect(error, isNull);
      expect(controller.allFilms, contains(imported));
      expect(controller.isInList(3), isTrue);
    });

    test('does not duplicate a film already in the catalogue', () async {
      when(() => repository.fetchFilms()).thenAnswer((_) async => [arrival]);
      await controller.load();
      when(() => repository.upsertFromTmdb(any())).thenAnswer((_) async => arrival);
      when(() => repository.addToList(userId, 1)).thenAnswer((_) async {});

      await controller.addFromTmdb(tmdbResult);

      expect(controller.allFilms.where((f) => f.id == 1), hasLength(1));
    });

    test('returns the error and leaves state untouched if the import fails', () async {
      when(() => repository.upsertFromTmdb(tmdbResult)).thenThrow(Exception('tmdb down'));

      final error = await controller.addFromTmdb(tmdbResult);

      expect(error, isNotNull);
      expect(controller.allFilms, isEmpty);
    });
  });

  group('markWatchedFromTmdb', () {
    test('imports the film and marks it watched', () async {
      when(() => repository.fetchFilms()).thenAnswer((_) async => []);
      when(() => repository.fetchUserFilmStatus(userId)).thenAnswer((_) async => {});
      await controller.load();

      const imported = Film(id: 3, name: 'Interstellar', tmdbId: 300);
      when(() => repository.upsertFromTmdb(tmdbResult)).thenAnswer((_) async => imported);
      when(() => repository.setWatched(userId, 3, true)).thenAnswer((_) async {});

      final error = await controller.markWatchedFromTmdb(tmdbResult);

      expect(error, isNull);
      expect(controller.isInList(3), isTrue);
      expect(controller.isWatched(3), isTrue);
    });
  });

  group('toggleWatched', () {
    setUp(() async {
      when(() => repository.fetchFilms()).thenAnswer((_) async => [arrival]);
      when(() => repository.fetchUserFilmStatus(userId)).thenAnswer((_) async => {1: false});
      await controller.load();
    });

    test('flips and persists the watched flag', () async {
      when(() => repository.setWatched(userId, 1, true)).thenAnswer((_) async {});

      final error = await controller.toggleWatched(1);

      expect(error, isNull);
      expect(controller.isWatched(1), isTrue);
    });

    test('rolls back if persisting fails', () async {
      when(() => repository.setWatched(userId, 1, true)).thenThrow(Exception('offline'));

      final error = await controller.toggleWatched(1);

      expect(error, isNotNull);
      expect(controller.isWatched(1), isFalse);
    });
  });
}
