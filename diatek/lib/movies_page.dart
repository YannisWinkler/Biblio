import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/external/tmdb_client.dart';
import 'data/external/tmdb_models.dart';
import 'state/user_films_controller.dart';
import 'utils/error_messages.dart';

/// Search TMDB to add new films to the catalogue, or browse the catalogue
/// (films already added) when the search bar is empty. Each result has a
/// checkbox to add/remove it from the signed-in user's list.
///
/// Reads and mutates a [UserFilmsController] shared with `MyListPage` via
/// `provider`, so changes made here show up there immediately.
class MoviesPage extends StatefulWidget {
  const MoviesPage({super.key});

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  static const _debounceDuration = Duration(milliseconds: 400);

  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _searching = false;
  Object? _searchError;
  List<TmdbMovieResult>? _searchResults;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    setState(() {});
    _debounce?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searching = false;
        _searchError = null;
        _searchResults = null;
      });
      return;
    }

    _debounce = Timer(_debounceDuration, () => _runSearch(trimmed));
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });

    try {
      final results = await context.read<TmdbClient>().searchMovies(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) setState(() => _searchError = e);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _setTmdbResultInList(TmdbMovieResult result, bool selected) async {
    final controller = context.read<UserFilmsController>();
    final Object? error;
    if (selected) {
      error = await controller.addFromTmdb(result);
    } else {
      final localId = controller.localFilmIdForTmdbId(result.tmdbId);
      error = localId == null ? null : await controller.setInList(localId, false);
    }
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update your list: ${friendlyMessage(error)}')),
      );
    }
  }

  Future<void> _toggleCatalogueFilm(int filmId, bool selected) async {
    final controller = context.read<UserFilmsController>();
    final error = await controller.setInList(filmId, selected);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update your list: ${friendlyMessage(error)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search TMDB to add a film',
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    _onQueryChanged('');
                  },
                ),
            ],
            onChanged: _onQueryChanged,
          ),
        ),
        Expanded(
          child: _searchController.text.trim().isEmpty
              ? _CatalogueList(onToggle: _toggleCatalogueFilm)
              : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searching && _searchResults == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchError != null) {
      return Center(child: Text('Search failed: ${friendlyMessage(_searchError!)}'));
    }
    final results = _searchResults ?? const [];
    if (results.isEmpty) {
      return const Center(child: Text('No movies match your search.'));
    }
    return Consumer<UserFilmsController>(
      builder: (context, controller, _) => ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          return CheckboxListTile(
            key: ValueKey(result.tmdbId),
            secondary: _Poster(url: result.posterUrl),
            title: Text(result.title),
            subtitle: result.overview == null || result.overview!.isEmpty
                ? null
                : Text(result.overview!, maxLines: 2, overflow: TextOverflow.ellipsis),
            value: controller.isTmdbIdInList(result.tmdbId),
            onChanged: (value) => _setTmdbResultInList(result, value ?? false),
          );
        },
      ),
    );
  }
}

/// Browsing view for the catalogue: films already imported from TMDB.
class _CatalogueList extends StatelessWidget {
  const _CatalogueList({required this.onToggle});

  final void Function(int filmId, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserFilmsController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error != null) {
          return Center(child: Text('Failed to load films: ${friendlyMessage(controller.error!)}'));
        }
        final films = controller.allFilms;
        if (films.isEmpty) {
          return const Center(child: Text('Your catalogue is empty. Search above to add a film.'));
        }
        return ListView.builder(
          itemCount: films.length,
          itemBuilder: (context, index) {
            final film = films[index];
            return CheckboxListTile(
              key: ValueKey(film.id),
              secondary: _Poster(url: film.posterUrl),
              title: Text(film.name),
              value: controller.isInList(film.id),
              onChanged: (value) => onToggle(film.id, value ?? false),
            );
          },
        );
      },
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return const SizedBox(width: 40, height: 60, child: Icon(Icons.movie_outlined));
    }
    return SizedBox(
      width: 40,
      height: 60,
      child: Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie_outlined),
      ),
    );
  }
}
