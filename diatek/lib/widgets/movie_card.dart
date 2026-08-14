import 'package:flutter/material.dart';

import 'movie_details_sheet.dart';
import 'poster.dart';

/// A poster-forward movie tile: a large poster with the title (up to two
/// lines) below it. The synopsis is hidden until the card is tapped, so
/// browsing a grid of these stays compact.
///
/// Generic over title/poster/overview rather than a specific model, so it's
/// shared by TMDB "now playing" results and My List. [overlay] and
/// [onLongPress] are left to the caller (e.g. a watched badge and
/// long-press-to-remove for My List; nothing for Home, where actions live
/// in the detail sheet instead).
class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.overview,
    this.tmdbId,
    this.overlay,
    this.onLongPress,
    this.detailActionsBuilder,
  });

  final String title;
  final String? posterUrl;
  final String? overview;

  /// Used to look up streaming availability for the detail sheet. Null for
  /// films added before TMDB linking existed, or entered by hand — the
  /// sheet simply omits the "Available on" section for those.
  final int? tmdbId;

  /// Small widget positioned over the top-right of the poster (e.g. a
  /// watched-status badge). Omitted entirely if null.
  final Widget? overlay;

  /// Fired on a long press anywhere on the card. Omitted entirely if null.
  final VoidCallback? onLongPress;

  /// Extra actions (e.g. "mark as watched", "add to my list") shown below
  /// the synopsis in the detail bottom sheet. Built lazily, and passed the
  /// sheet's own context, so callers can `Navigator.pop` it after acting.
  final List<Widget> Function(BuildContext context)? detailActionsBuilder;

  @override
  Widget build(BuildContext context) {
    final hasOverview = overview != null && overview!.isNotEmpty;
    final canOpenDetails = hasOverview || detailActionsBuilder != null || tmdbId != null;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: canOpenDetails ? () => _showDetails(context) : null,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Poster(url: posterUrl),
                  ),
                ),
                if (overlay != null) Positioned(top: 4, right: 4, child: overlay!),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showMovieDetailsSheet(
      context,
      title: title,
      overview: overview,
      tmdbId: tmdbId,
      actionsBuilder: detailActionsBuilder,
    );
  }
}
