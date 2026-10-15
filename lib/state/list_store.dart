import 'package:flutter/foundation.dart';

import '../data/list_repository.dart';
import '../domain/sorting.dart';
import '../domain/text_rules.dart';
import '../models/list_item.dart';
import '../models/shopping_list.dart';
import '../util/format.dart';
import '../util/uuid.dart';
import 'catalog_store.dart';

/// What happened when an item was added (FR-05).
enum AddOutcome {
  /// A new item was created.
  added,

  /// The name was already on the list and unchecked – nothing changed.
  alreadyOnList,

  /// The name was on the list but checked – it was unchecked.
  unchecked,
}

class AddResult {
  const AddResult(this.outcome, this.item);

  final AddOutcome outcome;
  final ListItem item;
}

/// Progress of a list: checked / total.
typedef Progress = ({int checked, int total});

/// The lists and items in memory, written through to the repository.
class ListStore extends ChangeNotifier {
  ListStore(
    this._repository, {
    CatalogStore? catalog,
    DateTime Function()? clock,
    String Function()? newId,
  })  : _catalog = catalog,
        _clock = clock ?? DateTime.now,
        _newId = newId ?? generateUuidV4;

  final ListRepository _repository;

  /// FR-13: names put on a list are learned by the catalog.
  final CatalogStore? _catalog;
  final DateTime Function() _clock;
  final String Function() _newId;

  final _lists = <String, ShoppingList>{};

  /// Non-deleted items per list id.
  final _items = <String, List<ListItem>>{};

  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    final lists = await _repository.loadLists();
    final items = await _repository.loadItems();
    _lists
      ..clear()
      ..addEntries(lists.map((l) => MapEntry(l.id, l)));
    _items.clear();
    for (final i in items) {
      _items.putIfAbsent(i.listId, () => []).add(i);
    }
    _loaded = true;
    notifyListeners();
  }

  // ----- lists -----

  /// FR-01: the most recently changed list first.
  List<ShoppingList> get lists => _lists.values.toList()
    ..sort((a, b) {
      final c = b.updatedAt.compareTo(a.updatedAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    });

  ShoppingList? listById(String id) => _lists[id];

  /// FR-02: the suggested name of a new list, e.g. "List 16/10/2026".
  String defaultListName() => 'List ${formatDate(_clock())}';

  Future<ShoppingList> createList(String name) async {
    final now = _now();
    final list = ShoppingList(
      id: _newId(),
      name: _listName(name),
      createdAt: now,
      updatedAt: now,
    );
    await _repository.insertList(list);
    _lists[list.id] = list;
    _items[list.id] = [];
    notifyListeners();
    return list;
  }

  Future<void> renameList(String listId, String name) =>
      _saveList(_list(listId).copyWith(name: _listName(name), updatedAt: _now()));

  Future<void> setSortMode(String listId, SortMode mode) async {
    final list = _list(listId);
    if (list.sortMode == mode) return;
    await _saveList(list.copyWith(sortMode: mode, updatedAt: _now()));
  }

  /// Soft delete; the items stay untouched in the database.
  Future<void> deleteList(String listId) => deleteLists([listId]);

  /// FR-20: deletes several lists at once (soft delete).
  Future<void> deleteLists(Iterable<String> listIds) async {
    final now = _now();
    for (final id in listIds.toList()) {
      await _repository.updateList(_list(id).copyWith(deletedAt: now, updatedAt: now));
      _lists.remove(id);
      _items.remove(id);
    }
    notifyListeners();
  }

  // ----- items -----

  /// The non-deleted items of a list, unsorted (see [sortItems]).
  List<ListItem> itemsOf(String listId) => List.unmodifiable(_items[listId] ?? const []);

  Progress progressOf(String listId) {
    final items = _items[listId] ?? const <ListItem>[];
    return (checked: items.where((i) => i.checked).length, total: items.length);
  }

  /// The non-deleted item with the same name key, if any.
  ListItem? findByName(String listId, String name, {String? excludeId}) {
    final key = nameKey(name);
    for (final i in _items[listId] ?? const <ListItem>[]) {
      if (i.nameKey == key && i.id != excludeId) return i;
    }
    return null;
  }

  /// FR-03 / FR-05: adds an item, or reports the existing one with the same name.
  Future<AddResult> addItem(String listId, String name, {String? note}) async {
    _list(listId);
    final clean = _itemName(name);
    final existing = findByName(listId, clean);
    if (existing != null) {
      if (!existing.checked) return AddResult(AddOutcome.alreadyOnList, existing);
      final unchecked = existing.copyWith(checked: false, updatedAt: _now());
      await _saveItem(unchecked);
      return AddResult(AddOutcome.unchecked, unchecked);
    }
    final now = _now();
    final item = ListItem(
      id: _newId(),
      listId: listId,
      name: clean,
      note: cleanNote(note),
      createdAt: now,
      updatedAt: now,
    );
    await _repository.insertItem(item);
    _items.putIfAbsent(listId, () => []).add(item);
    await _touch(listId, now);
    notifyListeners();
    await _catalog?.learn(clean);
    return AddResult(AddOutcome.added, item);
  }

  /// FR-12: adds several names (e.g. from the catalog). Returns how many were added.
  Future<int> addItems(String listId, Iterable<String> names) async {
    var added = 0;
    for (final name in names.toList()) {
      final r = await addItem(listId, name);
      if (r.outcome == AddOutcome.added) added++;
    }
    return added;
  }

  /// Edits name and note. Returns false (and changes nothing) if another item
  /// of the list already has this name.
  Future<bool> updateItem(String itemId, {required String name, String? note}) async {
    final item = _item(itemId);
    final clean = _itemName(name);
    if (findByName(item.listId, clean, excludeId: itemId) != null) return false;
    final newNote = cleanNote(note);
    if (clean == item.name && newNote == item.note) return true;
    await _saveItem(item.copyWith(name: clean, note: newNote, updatedAt: _now()));
    if (clean != item.name) await _catalog?.learn(clean);
    return true;
  }

  /// FR-04: tick or untick.
  Future<void> toggleChecked(String itemId) async {
    final item = _item(itemId);
    await _saveItem(item.copyWith(checked: !item.checked, updatedAt: _now()));
  }

  /// Soft delete. Returns the deleted item for [restoreItem] (undo).
  Future<ListItem> deleteItem(String itemId) async {
    final item = _item(itemId);
    final now = _now();
    final deleted = item.copyWith(deletedAt: now, updatedAt: now);
    await _repository.updateItem(deleted);
    _items[item.listId]!.removeWhere((i) => i.id == itemId);
    await _touch(item.listId, now);
    notifyListeners();
    return deleted;
  }

  /// Undo of [deleteItem]. Returns false if the list is gone or the name has
  /// been added again in the meantime.
  Future<bool> restoreItem(ListItem deleted) async {
    if (!_lists.containsKey(deleted.listId)) return false;
    if (findByName(deleted.listId, deleted.name) != null) return false;
    final now = _now();
    final restored = deleted.copyWith(deletedAt: null, updatedAt: now);
    await _repository.updateItem(restored);
    _items.putIfAbsent(deleted.listId, () => []).add(restored);
    await _touch(deleted.listId, now);
    notifyListeners();
    return true;
  }

  /// FR-09: removes every tick of the list.
  Future<void> uncheckAll(String listId) async {
    final now = _now();
    final changed = [
      for (final i in itemsOf(listId))
        if (i.checked) i.copyWith(checked: false, updatedAt: now),
    ];
    await _saveItems(listId, changed, now);
  }

  /// FR-09: deletes the checked items. Returns how many were removed.
  Future<int> removeChecked(String listId) async {
    final now = _now();
    final changed = [
      for (final i in itemsOf(listId))
        if (i.checked) i.copyWith(deletedAt: now, updatedAt: now),
    ];
    await _saveItems(listId, changed, now);
    return changed.length;
  }

  // ----- helpers -----

  DateTime _now() => _clock().toUtc();

  ShoppingList _list(String id) =>
      _lists[id] ?? (throw StateError('Unknown list: $id'));

  ListItem _item(String id) {
    for (final items in _items.values) {
      for (final i in items) {
        if (i.id == id) return i;
      }
    }
    throw StateError('Unknown item: $id');
  }

  String _listName(String raw) =>
      cleanName(raw, TextRules.listNameMaxLength) ??
      (throw ArgumentError('The list name must not be empty'));

  String _itemName(String raw) =>
      cleanName(raw, TextRules.itemNameMaxLength) ??
      (throw ArgumentError('The item name must not be empty'));

  Future<void> _saveList(ShoppingList list) async {
    await _repository.updateList(list);
    _lists[list.id] = list;
    notifyListeners();
  }

  /// Writes a changed (non-deleted) item and marks its list as changed.
  Future<void> _saveItem(ListItem item) async {
    await _repository.updateItem(item);
    final items = _items[item.listId]!;
    items[items.indexWhere((i) => i.id == item.id)] = item;
    await _touch(item.listId, item.updatedAt);
    notifyListeners();
  }

  Future<void> _saveItems(String listId, List<ListItem> changed, DateTime now) async {
    if (changed.isEmpty) return;
    await _repository.updateItems(changed);
    final byId = {for (final i in changed) i.id: i};
    _items[listId] = [
      for (final i in _items[listId] ?? const <ListItem>[])
        if (byId[i.id] == null)
          i
        else if (!byId[i.id]!.isDeleted)
          byId[i.id]!,
    ];
    await _touch(listId, now);
    notifyListeners();
  }

  /// The list's updatedAt follows its items (FR-01 order).
  Future<void> _touch(String listId, DateTime now) async {
    final list = _lists[listId];
    if (list == null) return;
    final touched = list.copyWith(updatedAt: now);
    await _repository.updateList(touched);
    _lists[listId] = touched;
  }
}
