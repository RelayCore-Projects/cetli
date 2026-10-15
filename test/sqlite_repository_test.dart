import 'dart:io';

import 'package:cetli/data/sqlite_repository.dart';
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
}
