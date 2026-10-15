import 'package:cetli/domain/sorting.dart';
import 'package:cetli/models/list_item.dart';
import 'package:cetli/models/shopping_list.dart';

/// Invented test data – real shopping lists never go into the repository.
final stamp = DateTime.utc(2026, 10, 1, 8);

ShoppingList shoppingList(
  String id, {
  String name = 'Weekly shop',
  SortMode sortMode = SortMode.added,
  DateTime? updatedAt,
  DateTime? deletedAt,
}) =>
    ShoppingList(
      id: id,
      name: name,
      sortMode: sortMode,
      createdAt: stamp,
      updatedAt: updatedAt ?? stamp,
      deletedAt: deletedAt,
    );

/// [minute] sets createdAt, i.e. the "order added".
ListItem listItem(
  String id,
  String listId,
  String name, {
  int minute = 0,
  bool checked = false,
  String? note,
  DateTime? deletedAt,
}) {
  final created = stamp.add(Duration(minutes: minute));
  return ListItem(
    id: id,
    listId: listId,
    name: name,
    note: note,
    checked: checked,
    createdAt: created,
    updatedAt: created,
    deletedAt: deletedAt,
  );
}

/// A clock that moves one second forward on every call, from 16 October 2026.
DateTime Function() steppingClock([DateTime? start]) {
  var t = start ?? DateTime.utc(2026, 10, 16, 8);
  return () => t = t.add(const Duration(seconds: 1));
}

/// Predictable ids: id1, id2, …
String Function() sequentialIds([String prefix = 'id']) {
  var n = 0;
  return () => '$prefix${++n}';
}
