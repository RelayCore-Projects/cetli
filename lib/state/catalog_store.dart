import 'package:flutter/foundation.dart';

import '../data/catalog_repository.dart';
import '../domain/text_rules.dart';
import '../models/catalog_item.dart';
import '../util/uuid.dart';

/// The catalog (FR-10…13): read-only built-in entries plus the user's own ones.
class CatalogStore extends ChangeNotifier {
  CatalogStore(
    this._repository, {
    Iterable<String> builtinNames = const [],
    DateTime Function()? clock,
    String Function()? newId,
  })  : _clock = clock ?? DateTime.now,
        _newId = newId ?? generateUuidV4 {
    for (final name in builtinNames) {
      final clean = cleanName(name, TextRules.itemNameMaxLength);
      if (clean == null) continue;
      final item = CatalogItem.fromBuiltin(clean);
      _builtin.putIfAbsent(item.nameKey, () => item);
    }
  }

  /// For tests and as a default: no built-in entries, kept in memory.
  factory CatalogStore.inMemory({Iterable<String> builtinNames = const []}) =>
      CatalogStore(InMemoryCatalogRepository(), builtinNames: builtinNames);

  final CatalogRepository _repository;
  final DateTime Function() _clock;
  final String Function() _newId;

  /// Built-in entries by name key.
  final _builtin = <String, CatalogItem>{};

  /// The user's non-deleted entries by id.
  final _custom = <String, CatalogItem>{};

  Future<void> load() async {
    _custom
      ..clear()
      ..addEntries((await _repository.loadCatalog()).map((i) => MapEntry(i.id, i)));
    notifyListeners();
  }

  /// Every entry A–Z. A user entry whose name later became built-in is shown once.
  List<CatalogItem> get items {
    final all = [
      ..._builtin.values,
      ..._custom.values.where((c) => !_builtin.containsKey(c.nameKey)),
    ];
    all.sort(_compare);
    return all;
  }

  static int _compare(CatalogItem a, CatalogItem b) {
    final c = a.nameKey.compareTo(b.nameKey);
    return c != 0 ? c : a.name.compareTo(b.name);
  }

  /// The entry with this name (case-insensitive), if any.
  CatalogItem? findByName(String name, {String? excludeId}) {
    final key = nameKey(name);
    final builtin = _builtin[key];
    if (builtin != null) return builtin;
    for (final c in _custom.values) {
      if (c.nameKey == key && c.id != excludeId) return c;
    }
    return null;
  }

  /// Entries whose name contains [query] (case-insensitive), A–Z.
  List<CatalogItem> search(String query) {
    final q = nameKey(query);
    if (q.isEmpty) return items;
    return items.where((i) => i.nameKey.contains(q)).toList();
  }

  /// FR-11: at most [limit] suggestions – names starting with the query first,
  /// then names containing it; entries whose key is in [exclude] are left out.
  List<CatalogItem> suggestions(
    String query, {
    Set<String> exclude = const {},
    int limit = 5,
  }) {
    final q = nameKey(query);
    if (q.isEmpty) return const [];
    final candidates = items.where((i) => !exclude.contains(i.nameKey));
    return [
      ...candidates.where((i) => i.nameKey.startsWith(q)),
      ...candidates.where((i) => !i.nameKey.startsWith(q) && i.nameKey.contains(q)),
    ].take(limit).toList();
  }

  /// Adds a user entry. Returns null if the name is already in the catalog.
  Future<CatalogItem?> addCustom(String name) async {
    final clean = _name(name);
    if (findByName(clean) != null) return null;
    final now = _clock().toUtc();
    final item = CatalogItem(id: _newId(), name: clean, createdAt: now, updatedAt: now);
    await _repository.insertCatalogItem(item);
    _custom[item.id] = item;
    notifyListeners();
    return item;
  }

  /// FR-13: a name put on a list becomes a user entry if it is not known yet.
  Future<void> learn(String name) async {
    if (findByName(name) == null) await addCustom(name);
  }

  /// Renames a user entry. Returns false if another entry has this name.
  Future<bool> renameCustom(String id, String name) async {
    final item = _customItem(id);
    final clean = _name(name);
    if (findByName(clean, excludeId: id) != null) return false;
    if (clean == item.name) return true;
    final renamed = item.copyWith(name: clean, updatedAt: _clock().toUtc());
    await _repository.updateCatalogItem(renamed);
    _custom[id] = renamed;
    notifyListeners();
    return true;
  }

  /// Soft delete of a user entry. Returns the deleted entry for [restoreCustom].
  Future<CatalogItem> deleteCustom(String id) async {
    final now = _clock().toUtc();
    final deleted = _customItem(id).copyWith(deletedAt: now, updatedAt: now);
    await _repository.updateCatalogItem(deleted);
    _custom.remove(id);
    notifyListeners();
    return deleted;
  }

  /// Undo of [deleteCustom]; false if the name was added again meanwhile.
  Future<bool> restoreCustom(CatalogItem deleted) async {
    if (findByName(deleted.name) != null) return false;
    final restored = deleted.copyWith(deletedAt: null, updatedAt: _clock().toUtc());
    await _repository.updateCatalogItem(restored);
    _custom[restored.id] = restored;
    notifyListeners();
    return true;
  }

  CatalogItem _customItem(String id) {
    if (id.startsWith('builtin:')) {
      throw StateError('Built-in catalog entries are read-only');
    }
    return _custom[id] ?? (throw StateError('Unknown catalog entry: $id'));
  }

  String _name(String raw) =>
      cleanName(raw, TextRules.itemNameMaxLength) ??
      (throw ArgumentError('The name must not be empty'));
}
