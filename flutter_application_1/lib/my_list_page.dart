import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/user_films_controller.dart';

/// The signed-in user's personal list: films they've added, each with a
/// button to toggle watched/not-watched and a button to remove it.
///
/// Reads and mutates a [UserFilmsController] shared with [MoviesPage] via
/// `provider`, so changes made here show up there immediately.
class MyListPage extends StatelessWidget {
  const MyListPage({super.key});

  Future<void> _toggleWatched(BuildContext context, int filmId) async {
    final controller = context.read<UserFilmsController>();
    final error = await controller.toggleWatched(filmId);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update watched status: $error')),
      );
    }
  }

  Future<void> _remove(BuildContext context, int filmId) async {
    final controller = context.read<UserFilmsController>();
    final error = await controller.setInList(filmId, false);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove film: $error')),
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
          return Center(child: Text('Failed to load your list: ${controller.error}'));
        }
        final films = controller.userFilms;
        if (films.isEmpty) {
          return const Center(child: Text('Your list is empty.'));
        }
        return ListView.builder(
          itemCount: films.length,
          itemBuilder: (context, index) {
            final film = films[index];
            final watched = controller.isWatched(film.id);
            return ListTile(
              title: Text(film.name),
              subtitle: Text(watched ? 'Watched' : 'Not watched'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(watched ? Icons.visibility : Icons.visibility_off),
                    tooltip: watched ? 'Mark as not watched' : 'Mark as watched',
                    onPressed: () => _toggleWatched(context, film.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Remove from list',
                    onPressed: () => _remove(context, film.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
