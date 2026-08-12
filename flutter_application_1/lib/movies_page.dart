import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/user_films_controller.dart';

/// All films, each with a checkbox to add/remove it from the signed-in
/// user's list (the 'user_film' join table).
///
/// Reads and mutates a [UserFilmsController] shared with [MyListPage] via
/// `provider`, so changes made here show up there immediately.
class MoviesPage extends StatelessWidget {
  const MoviesPage({super.key});

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
    return Consumer<UserFilmsController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error != null) {
          return Center(child: Text('Failed to load films: ${controller.error}'));
        }
        final films = controller.allFilms;
        return ListView.builder(
          itemCount: films.length,
          itemBuilder: (context, index) {
            final film = films[index];
            return CheckboxListTile(
              title: Text(film.name),
              value: controller.isInList(film.id),
              onChanged: (value) => _toggle(context, film.id, value ?? false),
            );
          },
        );
      },
    );
  }
}
