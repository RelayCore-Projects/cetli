import '../models/catalog_item.dart';

/// Storage of the user's own catalog entries (built-in entries are not stored).
abstract class CatalogRepository {
  /// The user's entries that are not deleted.
  Future<List<CatalogItem>> loadCatalog();

  Future<void> insertCatalogItem(CatalogItem item);

  /// Overwrites the whole row (edits and soft delete as well).
  Future<void> updateCatalogItem(CatalogItem item);
}

/// In-memory storage for tests. Enforces the same rules as the SQLite schema.
class InMemoryCatalogRepository implements CatalogRepository {
  InMemoryCatalogRepository([Iterable<CatalogItem> initial = const []]) {
    for (final i in initial) {
      _rows[i.id] = i;
    }
  }

  final _rows = <String, CatalogItem>{};

  /// Every row, soft-deleted ones included.
  Map<String, CatalogItem> get rows => Map.unmodifiable(_rows);

  @override
  Future<List<CatalogItem>> loadCatalog() async =>
      _rows.values.where((i) => !i.isDeleted).toList();

  @override
  Future<void> insertCatalogItem(CatalogItem item) async {
    if (_rows.containsKey(item.id)) throw StateError('Duplicate id: ${item.id}');
    _checkUnique(item);
    _rows[item.id] = item;
  }

  @override
  Future<void> updateCatalogItem(CatalogItem item) async {
    if (!_rows.containsKey(item.id)) throw StateError('Unknown id: ${item.id}');
    _checkUnique(item);
    _rows[item.id] = item;
  }

  void _checkUnique(CatalogItem item) {
    if (item.isDeleted) return;
    if (_rows.values.any((o) => o.id != item.id && !o.isDeleted && o.nameKey == item.nameKey)) {
      throw StateError('Duplicate name in catalog: ${item.name}');
    }
  }
}
