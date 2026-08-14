import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/external/tmdb_client.dart';
import 'data/external/tmdb_models.dart';
import 'data/film_repository.dart';
import 'data/models.dart';
import 'data/profile_repository.dart';
import 'state/user_films_controller.dart';
import 'utils/error_messages.dart';
import 'utils/tmdb_list_actions.dart';
import 'widgets/movie_list_tile.dart';
import 'widgets/profile_menu.dart';

/// Shell around the Home / My List tabs: app bar with a search icon that
/// expands into a TMDB search field (accessible no matter which tab is
/// active; searching overlays the current tab with results until cleared)
/// and the profile menu, bottom navigation wired to the router's branches,
/// and the [UserFilmsController] shared by both tabs so a change in one is
/// immediately visible in the other.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  /// Injected by the `StatefulShellRoute` in router.dart; tracks which
  /// branch (Home / My List) is active and lets us switch between them
  /// while preserving each branch's own navigation state.
  final StatefulNavigationShell navigationShell;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _debounceDuration = Duration(milliseconds: 400);

  late final UserFilmsController _controller;
  late final Future<Profile> _profileFuture;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

  bool _searchExpanded = false;
  bool _searching = false;
  Object? _searchError;
  List<TmdbMovieResult>? _searchResults;

  @override
  void initState() {
    super.initState();
    // Router guarantees only a signed-in user ever reaches HomeShell (see
    // the redirect in router.dart), so currentUser is never null here.
    final userId = Supabase.instance.client.auth.currentUser!.id;
    _controller = UserFilmsController(
      repository: context.read<FilmRepository>(),
      userId: userId,
    )..load();
    _profileFuture = context.read<ProfileRepository>().fetchProfile(userId);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _expandSearch() {
    setState(() => _searchExpanded = true);
    _searchFocusNode.requestFocus();
  }

  void _collapseSearch() {
    _searchController.clear();
    _onQueryChanged('');
    setState(() => _searchExpanded = false);
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

  // Takes `context` explicitly (rather than using the State's own) because
  // it must be a descendant of the ChangeNotifierProvider set up in
  // build() below — the State's context is that provider's parent, so
  // `context.read<UserFilmsController>()` would throw if called from here.
  Future<void> _addFromSearch(BuildContext context, TmdbMovieResult result, bool selected) async {
    await setTmdbResultInList(context, result, selected);
    // Only clear on add: on remove, the user is likely still browsing.
    if (selected && mounted) _collapseSearch();
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

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchController.text.trim().isNotEmpty;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: _searchExpanded
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Close search',
                  onPressed: _collapseSearch,
                )
              : null,
          title: _searchExpanded
              ? TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search TMDB to add a film',
                    border: InputBorder.none,
                  ),
                  onChanged: _onQueryChanged,
                )
              : const Text('Films'),
          actions: [
            if (_searchExpanded && isSearching)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  _onQueryChanged('');
                },
              )
            else if (!_searchExpanded)
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search',
                onPressed: _expandSearch,
              ),
            ProfileMenu(profileFuture: _profileFuture),
          ],
        ),
        body: isSearching ? _buildSearchResults() : widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) => widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.list), label: 'My List'),
          ],
        ),
      ),
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
          return MovieListTile(
            key: ValueKey(result.tmdbId),
            title: result.title,
            posterUrl: result.posterUrl,
            overview: result.overview,
            value: controller.isTmdbIdInList(result.tmdbId),
            onChanged: (value) => _addFromSearch(context, result, value ?? false),
            tmdbId: result.tmdbId,
            detailActionsBuilder: (sheetContext) =>
                buildTmdbResultDetailActions(context, sheetContext, result),
          );
        },
      ),
    );
  }
}
