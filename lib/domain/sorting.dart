import '../models/list_item.dart';

/// FR-07: item order, remembered per list.
enum SortMode {
  added('added', 'Order added'),
  nameAsc('name_asc', 'Name A–Z'),
  nameDesc('name_desc', 'Name Z–A');

  const SortMode(this.key, this.label);

  /// Stored value (database, files).
  final String key;
  final String label;

  static SortMode fromKey(String? key) =>
      values.firstWhere((m) => m.key == key, orElse: () => SortMode.added);
}

/// FR-08: where checked items go – a general setting.
enum CheckedPosition {
  bottom('bottom', 'Move to bottom'),
  inPlace('in_place', 'Keep in place');

  const CheckedPosition(this.key, this.label);

  final String key;
  final String label;

  static CheckedPosition fromKey(String? key) =>
      values.firstWhere((p) => p.key == key, orElse: () => CheckedPosition.bottom);
}

/// The items in display order. With [CheckedPosition.bottom] the unchecked items
/// come first and the sort order applies within both groups.
List<ListItem> sortItems(
  Iterable<ListItem> items,
  SortMode mode,
  CheckedPosition checkedPosition,
) {
  int byAdded(ListItem a, ListItem b) {
    final c = a.createdAt.compareTo(b.createdAt);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  int byName(ListItem a, ListItem b) {
    final c = a.nameKey.compareTo(b.nameKey);
    return c != 0 ? c : byAdded(a, b);
  }

  final compare = switch (mode) {
    SortMode.added => byAdded,
    SortMode.nameAsc => byName,
    SortMode.nameDesc => (ListItem a, ListItem b) => byName(b, a),
  };

  final sorted = items.toList()..sort(compare);
  if (checkedPosition == CheckedPosition.inPlace) return sorted;
  return [
    ...sorted.where((i) => !i.checked),
    ...sorted.where((i) => i.checked),
  ];
}
