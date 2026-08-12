import 'package:flutter/foundation.dart';

import '../data/film_repository.dart';
import '../data/models.dart';

/// Single source of truth for "all films" plus "which of them are on the
/// signed-in user's list, and whether they're watched".
///
/// Shared between the Movies tab and the My List tab (via `provider`) so a
/// change made in one is immediately reflected in the other, instead of each
/// page holding its own stale copy fetched once at startup.
class UserFilmsController extends ChangeNotifier {
  UserFilmsController({required FilmRepository repository, required String userId})
      : _repository = repository,
        _userId = userId;

  final FilmRepository _repository;
  final String _userId;

  List<Film> _films = [];
  Map<int, bool> _watchedByFilmId = {};

  bool _isLoading = true;
  Object? _error;

  bool get isLoading => _isLoading;
  Object? get error => _error;

  /// Every film in the catalogue.
  List<Film> get allFilms => _films;

  /// Films on the user's list, most-recently-added first is not tracked, so
  /// this preserves catalogue order.
  List<Film> get userFilms =>
      _films.where((film) => _watchedByFilmId.containsKey(film.id)).toList();

  bool isInList(int filmId) => _watchedByFilmId.containsKey(filmId);

  bool isWatched(int filmId) => _watchedByFilmId[filmId] ?? false;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchFilms(),
        _repository.fetchUserFilmStatus(_userId),
      ]);
      _films = results[0] as List<Film>;
      _watchedByFilmId = results[1] as Map<int, bool>;
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds or removes [filmId] from the user's list, updating state
  /// immediately and rolling back if the request fails. Returns an error
  /// object on failure so the caller can show it, or null on success.
  Future<Object?> setInList(int filmId, bool inList) async {
    final previouslyWatched = _watchedByFilmId[filmId];

    _watchedByFilmId = Map.of(_watchedByFilmId);
    if (inList) {
      _watchedByFilmId[filmId] = false;
    } else {
      _watchedByFilmId.remove(filmId);
    }
    notifyListeners();

    try {
      if (inList) {
        await _repository.addToList(_userId, filmId);
      } else {
        await _repository.removeFromList(_userId, filmId);
      }
      return null;
    } catch (e) {
      _watchedByFilmId = Map.of(_watchedByFilmId);
      if (previouslyWatched != null) {
        _watchedByFilmId[filmId] = previouslyWatched;
      } else {
        _watchedByFilmId.remove(filmId);
      }
      notifyListeners();
      return e;
    }
  }

  /// Flips the watched flag for [filmId], persisting the change.
  Future<Object?> toggleWatched(int filmId) async {
    final newValue = !isWatched(filmId);

    _watchedByFilmId = Map.of(_watchedByFilmId)..[filmId] = newValue;
    notifyListeners();

    try {
      await _repository.setWatched(_userId, filmId, newValue);
      return null;
    } catch (e) {
      _watchedByFilmId = Map.of(_watchedByFilmId)..[filmId] = !newValue;
      notifyListeners();
      return e;
    }
  }
}
