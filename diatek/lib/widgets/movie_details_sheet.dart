import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/external/tmdb_client.dart';
import '../data/external/tmdb_models.dart';

/// Shows a movie's title, synopsis, streaming availability, and optional
/// actions in a bottom sheet. Shared by [MovieCard] and `MovieListTile` so
/// tapping either one (poster, title, or synopsis) opens the exact same
/// detail view.
///
/// Actions are laid out in a single row (evenly split), not stacked.
void showMovieDetailsSheet(
  BuildContext context, {
  required String title,
  required String? overview,
  int? tmdbId,
  List<Widget> Function(BuildContext context)? actionsBuilder,
}) {
  final hasOverview = overview != null && overview.isNotEmpty;
  final providersFuture = tmdbId == null ? null : context.read<TmdbClient>().watchProviders(tmdbId);
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    // Lets the sheet grow up to the full screen height instead of being
    // capped at roughly half of it, and — combined with the
    // SingleChildScrollView below — makes long content (overview, several
    // streaming providers, actions) scroll instead of overflowing on
    // smaller screens.
    isScrollControlled: true,
    builder: (sheetContext) {
      final actions = actionsBuilder?.call(sheetContext);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
            if (hasOverview) ...[
              const SizedBox(height: 8),
              _ExpandableOverview(text: overview),
            ],
            if (providersFuture != null) ...[
              const SizedBox(height: 12),
              _WatchProvidersSection(future: providersFuture),
            ],
            if (actions != null && actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: actions[i]),
                  ],
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}

/// A synopsis collapsed to [_collapsedMaxLines], with a trailing "…" when
/// it's too long to fit — tapping it (there's nothing else to tap in a
/// truncated synopsis) reveals the rest. Never collapses if it already
/// fits, so there's no dead tap target on a short synopsis.
class _ExpandableOverview extends StatefulWidget {
  const _ExpandableOverview({required this.text});

  final String text;

  @override
  State<_ExpandableOverview> createState() => _ExpandableOverviewState();
}

class _ExpandableOverviewState extends State<_ExpandableOverview> {
  static const _collapsedMaxLines = 4;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (_expanded) return Text(widget.text);

    return LayoutBuilder(
      builder: (context, constraints) {
        final overflows = (TextPainter(
          text: TextSpan(text: widget.text, style: DefaultTextStyle.of(context).style),
          maxLines: _collapsedMaxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth))
            .didExceedMaxLines;

        return GestureDetector(
          onTap: overflows ? () => setState(() => _expanded = true) : null,
          child: Text(
            widget.text,
            maxLines: _collapsedMaxLines,
            overflow: overflows ? TextOverflow.ellipsis : TextOverflow.clip,
          ),
        );
      },
    );
  }
}

/// The "Available on" row of streaming provider logos, once
/// [WatchProviders] loads. Renders nothing (rather than an empty-state
/// message) when TMDB has no streaming data for this movie/region, since
/// that's the common case for anything not yet on a subscription service.
class _WatchProvidersSection extends StatelessWidget {
  const _WatchProvidersSection({required this.future});

  final Future<WatchProviders?> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WatchProviders?>(
      future: future,
      builder: (context, snapshot) {
        final providers = snapshot.data?.flatrate ?? const [];
        if (providers.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available on', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final provider in providers)
                  Tooltip(
                    message: provider.name,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        provider.logoUrl,
                        width: 36,
                        height: 36,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Streaming data by JustWatch', style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      },
    );
  }
}
