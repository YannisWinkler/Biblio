import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/external/tmdb_models.dart';
import '../state/user_films_controller.dart';
import 'confirm_dialog.dart';
import 'error_messages.dart';

/// Adds or removes a TMDB result from the signed-in user's list (importing
/// it into the catalogue first if needed), asking for confirmation before a
/// removal, and showing a SnackBar confirming what happened either way.
/// Shared by every page that lets the user check/uncheck a TMDB result.
Future<void> setTmdbResultInList(BuildContext context, TmdbMovieResult result, bool selected) async {
  final controller = context.read<UserFilmsController>();

  if (!selected) {
    final localId = controller.localFilmIdForTmdbId(result.tmdbId);
    if (localId == null) return;
    final confirmed = await confirmDialog(
      context,
      title: 'Remove from list?',
      content: '"${result.title}" will be removed from your list.',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) return;
    final error = await controller.setInList(localId, false);
    if (!context.mounted) return;
    _showResultSnackBar(context, error, successMessage: 'Removed from your list');
    return;
  }

  final error = await controller.addFromTmdb(result);
  if (!context.mounted) return;
  _showResultSnackBar(context, error, successMessage: 'Added to your list');
}

void _showResultSnackBar(BuildContext context, Object? error, {required String successMessage}) {
  final message = error == null ? successMessage : 'Failed to update your list: ${friendlyMessage(error)}';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
/// needed), showing a SnackBar confirming what happened.
Future<void> markTmdbResultWatched(BuildContext context, TmdbMovieResult result) async {
  final controller = context.read<UserFilmsController>();
  final error = await controller.markWatchedFromTmdb(result);
  if (!context.mounted) return;
  _showResultSnackBar(context, error, successMessage: 'Marked as watched');
}
