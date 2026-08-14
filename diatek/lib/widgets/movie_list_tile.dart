import 'package:flutter/material.dart';

import 'movie_details_sheet.dart';
import 'poster.dart';

/// A compact, single-line-per-movie row: small poster, title, synopsis
/// preview, and a checkbox — trades the big poster of [MovieCard] for
/// density, so more results are visible at once (e.g. search results,
/// where scanning many options matters more than browsing posters).
///
/// Tapping the checkbox toggles [value] directly. Tapping anywhere else on
/// the row (poster, title, or synopsis) opens the same detail sheet as
/// [MovieCard] instead — the checkbox and the "open details" tap target
/// are deliberately separate, so browsing the synopsis never accidentally
/// toggles the checkbox.
class MovieListTile extends StatelessWidget {
  const MovieListTile({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.overview,
    required this.value,
    required this.onChanged,
    this.tmdbId,
    this.detailActionsBuilder,
  });

  final String title;
  final String? posterUrl;
  final String? overview;
  final bool value;
  final ValueChanged<bool?> onChanged;

  /// Used to look up streaming availability for the detail sheet. See
  /// [MovieCard.tmdbId].
  final int? tmdbId;

  final List<Widget> Function(BuildContext context)? detailActionsBuilder;

  @override
  Widget build(BuildContext context) {
    final hasOverview = overview != null && overview!.isNotEmpty;
    final canOpenDetails = hasOverview || detailActionsBuilder != null || tmdbId != null;
    return ListTile(
      onTap: canOpenDetails
          ? () => showMovieDetailsSheet(
                context,
                title: title,
                overview: overview,
                tmdbId: tmdbId,
                actionsBuilder: detailActionsBuilder,
              )
          : null,
      leading: SizedBox(
        width: 40,
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Poster(url: posterUrl),
        ),
      ),
      title: Text(title),
      subtitle: hasOverview
          ? Text(overview!, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Checkbox(value: value, onChanged: onChanged),
    );
  }
}
