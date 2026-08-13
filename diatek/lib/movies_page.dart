import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/user_films_controller.dart';

/// All films, each with a checkbox to add/remove it from the signed-in
/// user's list (the 'user_film' join table), filterable via a search bar.
///
/// Reads and mutates a [UserFilmsController] shared with `MyListPage` via
/// `provider`, so changes made here show up there immediately.
class MoviesPage extends StatefulWidget {
  const MoviesPage({super.key});

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggle(BuildContext context, int filmId, bool selected) async {
    final controller = context.read<UserFilmsController>();
    final error = await controller.setInList(filmId, selected);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update your list: $error')),
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
            hintText: 'Search movies',
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear search',
                  onPressed: () => setState(_searchController.clear),
                ),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: Consumer<UserFilmsController>(
            builder: (context, controller, _) {
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.error != null) {
                return Center(child: Text('Failed to load films: ${controller.error}'));
              }
              final query = _searchController.text.trim().toLowerCase();
              final films = query.isEmpty
                  ? controller.allFilms
                  : controller.allFilms
                      .where((film) => film.name.toLowerCase().contains(query))
                      .toList();
              if (films.isEmpty) {
                return const Center(child: Text('No movies match your search.'));
              }
              return ListView.builder(
                itemCount: films.length,
                itemBuilder: (context, index) {
                  final film = films[index];
                  return CheckboxListTile(
                    key: ValueKey(film.id),
                    title: Text(film.name),
                    value: controller.isInList(film.id),
                    onChanged: (value) => _toggle(context, film.id, value ?? false),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
