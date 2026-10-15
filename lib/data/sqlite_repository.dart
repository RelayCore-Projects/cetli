import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/catalog_item.dart';
import '../models/list_item.dart';
import '../models/shopping_list.dart';
import 'catalog_repository.dart';
import 'list_repository.dart';
import 'settings_repository.dart';

/// SQLite storage on the phone (NFR-02, NFR-05, ADR-001): lists, items, settings
/// and the user's own catalog entries.
class SqliteRepository
    implements ListRepository, SettingsRepository, CatalogRepository {
  SqliteRepository._(this._db);

  final Database _db;

  static const _lists = 'lists';
  static const _items = 'list_items';
  static const _settings = 'settings';
  static const _catalog = 'catalog_items';

  /// Schema version. Increase it on every change and convert in [_migrate];
  /// every migration gets an automated test (NFR-05).
  ///  1 – v0.2.0: lists, items, settings
  ///  2 – v0.3.0: catalog_items (the user's own catalog entries)
  static const schemaVersion = 2;

  /// [path] is only needed in tests; by default the app's own database folder.
  static Future<SqliteRepository> open({String? path}) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'cetli.db');
    final db = await openDatabase(
      dbPath,
      version: schemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      // onCreate and onUpgrade run in a transaction: on error everything is rolled back.
      onCreate: (db, version) async {
        await _createSchemaV1(db);
        await _createCatalog(db);
      },
      onUpgrade: _migrate,
    );
    return SqliteRepository._(db);
  }

  Future<void> close() => _db.close();

  static Future<void> _createSchemaV1(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $_lists (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        sort_mode   TEXT NOT NULL DEFAULT 'added',
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
        deleted_at  TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_items (
        id          TEXT PRIMARY KEY,
        list_id     TEXT NOT NULL REFERENCES $_lists (id),
        name        TEXT NOT NULL,
        name_key    TEXT NOT NULL,
        note        TEXT,
        checked     INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
        deleted_at  TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_items_list ON $_items (list_id)');
    // FR-05: a name appears at most once among the non-deleted items of a list
    await db.execute('CREATE UNIQUE INDEX idx_items_list_name ON $_items '
        '(list_id, name_key) WHERE deleted_at IS NULL');
    await db.execute('''
      CREATE TABLE $_settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// v2: the user's own catalog entries (FR-10, FR-13). Built-in entries are not stored.
  static Future<void> _createCatalog(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $_catalog (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        name_key    TEXT NOT NULL,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
        deleted_at  TEXT
      )
    ''');
    await db.execute('CREATE UNIQUE INDEX idx_catalog_name ON $_catalog '
        '(name_key) WHERE deleted_at IS NULL');
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    if (from < 2) {
      // v1 → v2: new table, lists and items unchanged
      await _createCatalog(db);
    }
  }

  // ----- lists and items -----

  @override
  Future<List<ShoppingList>> loadLists() async {
    final rows = await _db.query(_lists, where: 'deleted_at IS NULL');
    return rows.map(ShoppingList.fromMap).toList();
  }

  @override
  Future<List<ListItem>> loadItems() async {
    final rows = await _db.rawQuery('''
      SELECT i.* FROM $_items i
      JOIN $_lists l ON l.id = i.list_id
      WHERE i.deleted_at IS NULL AND l.deleted_at IS NULL
    ''');
    return rows.map(ListItem.fromMap).toList();
  }

  @override
  Future<void> insertList(ShoppingList list) async {
    await _db.insert(_lists, list.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  @override
  Future<void> updateList(ShoppingList list) async {
    await _db.update(_lists, list.toMap(), where: 'id = ?', whereArgs: [list.id]);
  }

  @override
  Future<void> insertItem(ListItem item) async {
    await _db.insert(_items, item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  @override
  Future<void> updateItem(ListItem item) async {
    await _db.update(_items, item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  @override
  Future<void> updateItems(List<ListItem> items) async {
    await _db.transaction((txn) async {
      final batch = txn.batch();
      for (final i in items) {
        batch.update(_items, i.toMap(), where: 'id = ?', whereArgs: [i.id]);
      }
      await batch.commit(noResult: true);
    });
  }

  // ----- catalog -----

  @override
  Future<List<CatalogItem>> loadCatalog() async {
    final rows = await _db.query(_catalog, where: 'deleted_at IS NULL');
    return rows.map(CatalogItem.fromMap).toList();
  }

  @override
  Future<void> insertCatalogItem(CatalogItem item) async {
    await _db.insert(_catalog, item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  @override
  Future<void> updateCatalogItem(CatalogItem item) async {
    await _db.update(_catalog, item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  // ----- settings -----

  @override
  Future<Map<String, String>> loadSettings() async {
    final rows = await _db.query(_settings);
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  @override
  Future<void> saveSettings(Map<String, String> values) async {
    await _db.transaction((txn) async {
      await txn.delete(_settings);
      for (final e in values.entries) {
        await txn.insert(_settings, {'key': e.key, 'value': e.value});
      }
    });
  }
}
