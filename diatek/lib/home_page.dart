import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/external/tmdb_client.dart';
import 'data/external/tmdb_models.dart';
import 'utils/error_messages.dart';
import 'utils/tmdb_list_actions.dart';
import 'widgets/movie_card.dart';
import 'widgets/movie_grid.dart';

/// Landing tab: movies currently in theaters (TMDB's "now playing").
/// Tapping a poster opens its synopsis, with "add to my list" and "mark as
/// watched" actions.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List<TmdbMovieResult>> _nowPlayingFuture;

  @override
  void initState() {
    super.initState();
    _nowPlayingFuture = context.read<TmdbClient>().nowPlaying();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TmdbMovieResult>>(
      future: _nowPlayingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load now playing: ${friendlyMessage(snapshot.error!)}'));
        }

        final results = snapshot.data!;
        if (results.isEmpty) {
          return const Center(child: Text('Nothing currently playing.'));
        }
        return MovieGrid(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return MovieCard(
              key: ValueKey(result.tmdbId),
              title: result.title,
              posterUrl: result.posterUrl,
              overview: result.overview,
              tmdbId: result.tmdbId,
              detailActionsBuilder: (sheetContext) =>
                  buildTmdbResultDetailActions(context, sheetContext, result),
            );
          },
        );
      },
    );
  }
}
