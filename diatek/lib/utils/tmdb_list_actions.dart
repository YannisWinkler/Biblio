import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/external/tmdb_models.dart';
import '../state/user_films_controller.dart';
import 'error_messages.dart';

/// Adds or removes a TMDB result from the signed-in user's list (importing
/// it into the catalogue first if needed), showing a SnackBar on failure.
/// Shared by every page that lets the user check/uncheck a TMDB result.
Future<void> setTmdbResultInList(BuildContext context, TmdbMovieResult result, bool selected) async {
  final controller = context.read<UserFilmsController>();
  final Object? error;
  if (selected) {
    error = await controller.addFromTmdb(result);
  } else {
    final localId = controller.localFilmIdForTmdbId(result.tmdbId);
    error = localId == null ? null : await controller.setInList(localId, false);
  }
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update your list: ${friendlyMessage(error)}')),
    );
  }
}

/// The "add to my list" / "mark as watched" action pair shown in a TMDB
/// result's detail sheet — identical wherever a TMDB result is shown
/// (Home's "now playing", search results), so the two stay in sync.
///
/// [pageContext] is the (still-mounted-after-the-sheet-closes) context the
/// actions run in; [sheetContext] is only used to close the sheet first.
List<Widget> buildTmdbResultDetailActions(
  BuildContext pageContext,
  BuildContext sheetContext,
  TmdbMovieResult result,
) {
  return [
    FilledButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('Add to my list'),
      onPressed: () {
        Navigator.pop(sheetContext);
        setTmdbResultInList(pageContext, result, true);
      },
    ),
    OutlinedButton.icon(
      icon: const Icon(Icons.visibility),
      label: const Text('Mark as watched'),
      onPressed: () {
        Navigator.pop(sheetContext);
        markTmdbResultWatched(pageContext, result);
      },
    ),
  ];
}

/// Marks a TMDB result watched (importing/adding it to the list first if
/// needed), showing a SnackBar on failure.
Future<void> markTmdbResultWatched(BuildContext context, TmdbMovieResult result) async {
  final controller = context.read<UserFilmsController>();
  final error = await controller.markWatchedFromTmdb(result);
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update your list: ${friendlyMessage(error)}')),
    );
  }
}
