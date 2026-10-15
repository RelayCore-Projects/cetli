import '../models/list_item.dart';
import '../models/shopping_list.dart';
import 'list_repository.dart';

/// In-memory storage for tests. Enforces the same rules as the SQLite schema.
class InMemoryListRepository implements ListRepository {
  InMemoryListRepository({
    Iterable<ShoppingList> lists = const [],
    Iterable<ListItem> items = const [],
  }) {
    for (final l in lists) {
      _lists[l.id] = l;
    }
    for (final i in items) {
      _items[i.id] = i;
    }
  }

  final _lists = <String, ShoppingList>{};
  final _items = <String, ListItem>{};

  /// Every row, soft-deleted ones included.
  Map<String, ShoppingList> get listRows => Map.unmodifiable(_lists);
  Map<String, ListItem> get itemRows => Map.unmodifiable(_items);

  @override
  Future<List<ShoppingList>> loadLists() async =>
      _lists.values.where((l) => !l.isDeleted).toList();

  @override
  Future<List<ListItem>> loadItems() async => _items.values
      .where((i) => !i.isDeleted && _lists[i.listId]?.isDeleted == false)
      .toList();

  @override
  Future<void> insertList(ShoppingList list) async {
    if (_lists.containsKey(list.id)) throw StateError('Duplicate id: ${list.id}');
    _lists[list.id] = list;
  }

  @override
  Future<void> updateList(ShoppingList list) async {
    if (!_lists.containsKey(list.id)) throw StateError('Unknown id: ${list.id}');
    _lists[list.id] = list;
  }

  @override
  Future<void> insertItem(ListItem item) async {
    if (_items.containsKey(item.id)) throw StateError('Duplicate id: ${item.id}');
    _checkUnique(item);
    _items[item.id] = item;
  }

  @override
  Future<void> updateItem(ListItem item) async {
    if (!_items.containsKey(item.id)) throw StateError('Unknown id: ${item.id}');
    _checkUnique(item);
    _items[item.id] = item;
  }

  @override
  Future<void> updateItems(List<ListItem> items) async {
    for (final i in items) {
      await updateItem(i);
    }
  }

  /// Mirrors the partial unique index of the SQLite schema.
  void _checkUnique(ListItem item) {
    if (item.isDeleted) return;
    final clash = _items.values.any((o) =>
        o.id != item.id &&
        !o.isDeleted &&
        o.listId == item.listId &&
        o.nameKey == item.nameKey);
    if (clash) throw StateError('Duplicate name in list: ${item.name}');
  }
}
