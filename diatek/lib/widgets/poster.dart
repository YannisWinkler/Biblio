import 'package:flutter/material.dart';

/// A movie poster image filling its parent's constraints, or a placeholder
/// icon if [url] is null or fails to load. Shared by every widget that
/// shows a film or TMDB result's poster.
class Poster extends StatelessWidget {
  const Poster({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) return const _PosterPlaceholder();
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _PosterPlaceholder(),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.movie_outlined, size: 40)),
    );
  }
}
