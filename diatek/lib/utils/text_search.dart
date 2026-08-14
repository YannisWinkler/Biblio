/// Generic, title-agnostic search ranking so any list of titled items
/// (films today, series/books/etc. later) can be filtered and sorted by
/// relevance without depending on a specific model.
library;

/// Filters [items] to those whose title (from [titleOf]) contains [query],
/// then sorts by similarity to the start of the title: exact match first,
/// then prefix matches, then word-boundary matches, then any other
/// substring match. Ties are broken by match position, then alphabetically.
///
/// Returns [items] unchanged (in original order) when [query] is blank.
List<T> searchByTitle<T>(
  Iterable<T> items,
  String query,
  String Function(T item) titleOf,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return items.toList();

  final matches = <_Match<T>>[];
  for (final item in items) {
    final title = titleOf(item).toLowerCase();
    final index = title.indexOf(normalizedQuery);
    if (index == -1) continue;
    matches.add(_Match(item, _rank(title, normalizedQuery, index), index, title));
  }

  matches.sort((a, b) {
    final rankCompare = a.rank.compareTo(b.rank);
    if (rankCompare != 0) return rankCompare;
    final indexCompare = a.index.compareTo(b.index);
    if (indexCompare != 0) return indexCompare;
    return a.title.compareTo(b.title);
  });

  return matches.map((m) => m.item).toList();
}

int _rank(String title, String query, int index) {
  if (title == query) return 0;
  if (index == 0) return 1;
  final precedingChar = title[index - 1];
  final isWordBoundary = precedingChar == ' ' || precedingChar == '-' || precedingChar == ':';
  if (isWordBoundary) return 2;
  return 3;
}

class _Match<T> {
  _Match(this.item, this.rank, this.index, this.title);

  final T item;
  final int rank;
  final int index;
  final String title;
}
