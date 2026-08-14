import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/user_films_controller.dart';
import 'utils/error_messages.dart';
import 'widgets/movie_card.dart';
import 'widgets/movie_grid.dart';

/// The signed-in user's personal list: films they've added. Each poster has
/// a watched/not-watched badge, and is long-pressed (not a delete button)
/// to remove the film from the list, so removal stays deliberate.
///
/// Reads and mutates a [UserFilmsController] shared with `HomePage` (and
/// with the search results in `HomeShell`) via `provider`, so changes made
/// here show up there immediately.
class MyListPage extends StatelessWidget {
  const MyListPage({super.key});

  Future<void> _toggleWatched(BuildContext context, int filmId) async {
    final controller = context.read<UserFilmsController>();
    final error = await controller.toggleWatched(filmId);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update watched status: ${friendlyMessage(error)}')),
      );
    }
  }

  Future<void> _remove(BuildContext context, int filmId) async {
    final controller = context.read<UserFilmsController>();
    final error = await controller.setInList(filmId, false);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove film: ${friendlyMessage(error)}')),
      );
    }
  }

  Future<void> _confirmRemove(BuildContext context, int filmId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from list?'),
        content: Text('"$title" will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _remove(context, filmId);
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
          return Center(child: Text('Failed to load your list: ${friendlyMessage(controller.error!)}'));
        }
        final films = controller.userFilms;
        if (films.isEmpty) {
          return const Center(child: Text('Your list is empty.'));
        }
        return MovieGrid(
          itemCount: films.length,
          itemBuilder: (context, index) {
            final film = films[index];
            final watched = controller.isWatched(film.id);
            return MovieCard(
              key: ValueKey(film.id),
              title: film.name,
              posterUrl: film.posterUrl,
              overview: film.overview,
              tmdbId: film.tmdbId,
              onLongPress: () => _confirmRemove(context, film.id, film.name),
              overlay: _WatchedBadge(
                watched: watched,
                onPressed: () => _toggleWatched(context, film.id),
              ),
            );
          },
        );
      },
    );
  }
}

class _WatchedBadge extends StatelessWidget {
  const _WatchedBadge({required this.watched, required this.onPressed});

  final bool watched;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(
          watched ? Icons.visibility : Icons.visibility_off,
          color: Colors.white,
        ),
        tooltip: watched ? 'Mark as not watched' : 'Mark as watched',
        onPressed: onPressed,
      ),
    );
  }
}
