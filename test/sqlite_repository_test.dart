import 'dart:io';

import 'package:cetli/data/sqlite_repository.dart';
import 'package:cetli/models/catalog_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/factory.dart';

/// NFR-05: the stored data and the schema rules.
void main() {
  late Directory dir;
  late SqliteRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cetli_db_test');
    repo = await SqliteRepository.open(path: p.join(dir.path, 'cetli.db'));
  });

  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  test('a fresh database has the current schema version', () async {
    await repo.close();
    final raw = await databaseFactoryFfi.openDatabase(p.join(dir.path, 'cetli.db'));
    expect(await raw.getVersion(), SqliteRepository.schemaVersion);
    await raw.close();
    repo = await SqliteRepository.open(path: p.join(dir.path, 'cetli.db'));
  });

  test('lists and items survive reopening', () async {
    await repo.insertList(shoppingList('l1'));
    await repo.insertItem(listItem('i1', 'l1', 'Milk', note: '2 l', checked: true));
    await repo.insertItem(listItem('i2', 'l1', 'Bread', minute: 1));
    await repo.close();

    repo = await SqliteRepository.open(path: p.join(dir.path, 'cetli.db'));
    final lists = await repo.loadLists();
    expect(lists.single.name, 'Weekly shop');
    final items = await repo.loadItems();
    expect(items.map((i) => i.name), unorderedEquals(['Milk', 'Bread']));
    final milk = items.firstWhere((i) => i.id == 'i1');
    expect(milk.note, '2 l');
    expect(milk.checked, isTrue);
    expect(milk.nameKey, 'milk');
    expect(milk.createdAt, stamp);
  });

  test('FR-05: a name is unique among the active items of a list', () async {
    await repo.insertList(shoppingList('l1'));
    await repo.insertList(shoppingList('l2'));
    await repo.insertItem(listItem('i1', 'l1', 'Milk'));

    await expectLater(repo.insertItem(listItem('i2', 'l1', 'milk')),
        throwsA(isA<DatabaseException>()));
    // another list is fine
    await repo.insertItem(listItem('i3', 'l2', 'Milk'));
    // a deleted item does not block the name
    await repo.updateItem(
        listItem('i1', 'l1', 'Milk', deletedAt: DateTime.utc(2026, 10, 2)));
    await repo.insertItem(listItem('i4', 'l1', 'Milk'));
    expect((await repo.loadItems()).map((i) => i.id), unorderedEquals(['i3', 'i4']));
  });

  test('an item must belong to an existing list', () async {
    await expectLater(repo.insertItem(listItem('i1', 'missing', 'Milk')),
        throwsA(isA<DatabaseException>()));
  });

  test('soft-deleted lists and items are not loaded, but kept', () async {
    await repo.insertList(shoppingList('l1'));
    await repo.insertList(shoppingList('l2', name: 'Gone'));
    await repo.insertItem(listItem('i1', 'l1', 'Milk'));
    await repo.insertItem(listItem('i2', 'l2', 'Cake'));
    await repo.updateList(shoppingList('l2', name: 'Gone', deletedAt: DateTime.utc(2026, 10, 2)));
    await repo.updateItems([
      listItem('i1', 'l1', 'Milk', deletedAt: DateTime.utc(2026, 10, 2)),
    ]);

    expect((await repo.loadLists()).map((l) => l.id), ['l1']);
    expect(await repo.loadItems(), isEmpty);
    await repo.close();

    final raw = await databaseFactoryFfi.openDatabase(p.join(dir.path, 'cetli.db'));
    expect((await raw.query('lists')).length, 2);
    expect((await raw.query('list_items')).length, 2);
    await raw.close();
    repo = await SqliteRepository.open(path: p.join(dir.path, 'cetli.db'));
  });

  test('settings are replaced as a whole', () async {
    expect(await repo.loadSettings(), isEmpty);
    await repo.saveSettings({'checked_position': 'in_place', 'x': '1'});
    expect(await repo.loadSettings(), {'checked_position': 'in_place', 'x': '1'});
    await repo.saveSettings({'checked_position': 'bottom'});
    expect(await repo.loadSettings(), {'checked_position': 'bottom'});
  });

  test('catalog: own entries, unique among the active ones', () async {
    CatalogItem entry(String id, String name, {DateTime? deletedAt}) =>
        CatalogItem(id: id, name: name, createdAt: stamp, updatedAt: stamp, deletedAt: deletedAt);
    await repo.insertCatalogItem(entry('c1', 'Kefir'));
    await expectLater(repo.insertCatalogItem(entry('c2', 'kefir')),
        throwsA(isA<DatabaseException>()));
    await repo.updateCatalogItem(entry('c1', 'Kefir', deletedAt: DateTime.utc(2026, 10, 2)));
    await repo.insertCatalogItem(entry('c3', 'Kefir'));
    final loaded = await repo.loadCatalog();
    expect(loaded.map((i) => i.id), ['c3']);
    expect(loaded.single.builtin, isFalse);
  });

  group('migrations (NFR-05)', () {
    /// The v0.2.0 schema exactly as it was created on the phones.
    Future<void> createV1Database(String path) async {
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE lists (
                id TEXT PRIMARY KEY, name TEXT NOT NULL,
                sort_mode TEXT NOT NULL DEFAULT 'added',
                created_at TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT)''');
            await db.execute('''
              CREATE TABLE list_items (
                id TEXT PRIMARY KEY, list_id TEXT NOT NULL REFERENCES lists (id),
                name TEXT NOT NULL, name_key TEXT NOT NULL, note TEXT,
                checked INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT)''');
            await db.execute('CREATE INDEX idx_items_list ON list_items (list_id)');
            await db.execute('CREATE UNIQUE INDEX idx_items_list_name ON list_items '
                '(list_id, name_key) WHERE deleted_at IS NULL');
            await db.execute(
                'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
          },
        ),
      );
      await db.insert('lists', shoppingList('l1').toMap());
      await db.insert('list_items', listItem('i1', 'l1', 'Milk', note: '2 l').toMap());
      await db.insert('list_items',
          listItem('i2', 'l1', 'Bread', deletedAt: DateTime.utc(2026, 10, 2)).toMap());
      await db.insert('settings', {'key': 'checked_position', 'value': 'in_place'});
      await db.close();
    }

    test('v1 → v2 adds the catalog table and keeps every row', () async {
      final path = p.join(dir.path, 'v1.db');
      await createV1Database(path);

      final migrated = await SqliteRepository.open(path: path);
      expect((await migrated.loadLists()).single.id, 'l1');
      expect((await migrated.loadItems()).map((i) => (i.name, i.note)), [('Milk', '2 l')]);
      expect(await migrated.loadSettings(), {'checked_position': 'in_place'});
      expect(await migrated.loadCatalog(), isEmpty);
      await migrated.insertCatalogItem(
          CatalogItem(id: 'c1', name: 'Kefir', createdAt: stamp, updatedAt: stamp));
      await migrated.close();

      final raw = await databaseFactoryFfi.openDatabase(path);
      expect(await raw.getVersion(), SqliteRepository.schemaVersion);
      expect((await raw.query('list_items')).length, 2); // the deleted row is kept
      expect((await raw.query('catalog_items')).length, 1);
      await raw.close();
    });
  });
}
