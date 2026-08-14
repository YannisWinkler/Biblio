import 'package:flutter/material.dart';

/// Two-column grid of poster-forward tiles (see [MovieCard]) — each column
/// is about half the screen width. Sizing/spacing shared by every page
/// that lists movies, so they stay visually consistent.
class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.52,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
