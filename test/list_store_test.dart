import 'package:cetli/data/in_memory_list_repository.dart';
import 'package:cetli/domain/sorting.dart';
import 'package:cetli/state/list_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/factory.dart';

void main() {
  late InMemoryListRepository repo;
  late ListStore store;

  setUp(() {
    repo = InMemoryListRepository();
    store = ListStore(repo, clock: steppingClock(), newId: sequentialIds());
  });

  List<String> namesOf(String listId) =>
      store.itemsOf(listId).map((i) => i.name).toList();

  group('lists (FR-01, FR-02)', () {
    test('default name uses today\'s date', () {
      expect(store.defaultListName(), 'List 16/10/2026');
    });

    test('create, rename and delete', () async {
      final list = await store.createList('  Weekly   shop ');
      expect(list.name, 'Weekly shop');
      expect(store.lists.map((l) => l.id), [list.id]);

      await store.renameList(list.id, 'Party');
      expect(store.listById(list.id)!.name, 'Party');

      await store.deleteList(list.id);
      expect(store.lists, isEmpty);
      // soft delete: the row stays
      expect(repo.listRows[list.id]!.isDeleted, isTrue);
    });

    test('an empty name is rejected', () async {
      await expectLater(store.createList('   '), throwsArgumentError);
    });

    test('the most recently changed list comes first', () async {
      final a = await store.createList('A');
      final b = await store.createList('B');
      expect(store.lists.map((l) => l.name), ['B', 'A']);
      await store.addItem(a.id, 'Milk');
      expect(store.lists.map((l) => l.name), ['A', 'B']);
      await store.toggleChecked(store.itemsOf(a.id).single.id);
      await store.addItem(b.id, 'Bread');
      expect(store.lists.map((l) => l.name), ['B', 'A']);
    });

    test('sort mode is stored per list (FR-07)', () async {
      final a = await store.createList('A');
      final b = await store.createList('B');
      await store.setSortMode(a.id, SortMode.nameDesc);
      expect(store.listById(a.id)!.sortMode, SortMode.nameDesc);
      expect(store.listById(b.id)!.sortMode, SortMode.added);
      expect(repo.listRows[a.id]!.sortMode, SortMode.nameDesc);
    });
  });

  group('items (FR-03, FR-05, FR-06)', () {
    late String listId;
    setUp(() async => listId = (await store.createList('Weekly')).id);

    test('adds a cleaned item', () async {
      final r = await store.addItem(listId, '  Sour   cream ', note: ' 2 cups ');
      expect(r.outcome, AddOutcome.added);
      expect(r.item.name, 'Sour cream');
      expect(r.item.nameKey, 'sour cream');
      expect(r.item.note, '2 cups');
      expect(r.item.checked, isFalse);
      expect(namesOf(listId), ['Sour cream']);
    });

    test('a name already on the list is not added again', () async {
      await store.addItem(listId, 'Bread');
      final r = await store.addItem(listId, ' bread ');
      expect(r.outcome, AddOutcome.alreadyOnList);
      expect(r.item.name, 'Bread');
      expect(namesOf(listId), ['Bread']);
    });

    test('re-entering a checked item unchecks it', () async {
      final added = await store.addItem(listId, 'Milk');
      await store.toggleChecked(added.item.id);
      final r = await store.addItem(listId, 'MILK');
      expect(r.outcome, AddOutcome.unchecked);
      expect(store.itemsOf(listId).single.checked, isFalse);
      expect(store.itemsOf(listId), hasLength(1));
    });

    test('the same name may appear on different lists', () async {
      final other = await store.createList('Other');
      await store.addItem(listId, 'Milk');
      final r = await store.addItem(other.id, 'Milk');
      expect(r.outcome, AddOutcome.added);
    });

    test('editing name and note; a clashing name is refused', () async {
      final milk = (await store.addItem(listId, 'Milk')).item;
      await store.addItem(listId, 'Bread');

      expect(await store.updateItem(milk.id, name: 'bread'), isFalse);
      expect(namesOf(listId), ['Milk', 'Bread']);

      expect(await store.updateItem(milk.id, name: 'Oat milk', note: 'Happy Day'),
          isTrue);
      final edited = store.itemsOf(listId).first;
      expect(edited.name, 'Oat milk');
      expect(edited.nameKey, 'oat milk');
      expect(edited.note, 'Happy Day');

      expect(await store.updateItem(milk.id, name: 'Oat milk', note: '  '), isTrue);
      expect(store.itemsOf(listId).first.note, isNull);
    });

    test('toggling a tick (FR-04)', () async {
      final milk = (await store.addItem(listId, 'Milk')).item;
      await store.toggleChecked(milk.id);
      expect(store.progressOf(listId), (checked: 1, total: 1));
      await store.toggleChecked(milk.id);
      expect(store.progressOf(listId), (checked: 0, total: 1));
    });

    test('delete and undo', () async {
      final milk = (await store.addItem(listId, 'Milk')).item;
      final deleted = await store.deleteItem(milk.id);
      expect(namesOf(listId), isEmpty);
      expect(repo.itemRows[milk.id]!.isDeleted, isTrue);

      expect(await store.restoreItem(deleted), isTrue);
      expect(namesOf(listId), ['Milk']);
      expect(repo.itemRows[milk.id]!.isDeleted, isFalse);
    });

    test('undo is refused when the name was added again meanwhile', () async {
      final milk = (await store.addItem(listId, 'Milk')).item;
      final deleted = await store.deleteItem(milk.id);
      await store.addItem(listId, 'milk');
      expect(await store.restoreItem(deleted), isFalse);
      expect(store.itemsOf(listId), hasLength(1));
    });

    test('a deleted name can be added again as a new item', () async {
      final milk = (await store.addItem(listId, 'Milk')).item;
      await store.deleteItem(milk.id);
      final r = await store.addItem(listId, 'Milk');
      expect(r.outcome, AddOutcome.added);
      expect(r.item.id, isNot(milk.id));
    });
  });

  group('after shopping (FR-09)', () {
    late String listId;
    setUp(() async {
      listId = (await store.createList('Weekly')).id;
      for (final n in ['Milk', 'Bread', 'Apples']) {
        await store.addItem(listId, n);
      }
      await store.toggleChecked(store.itemsOf(listId)[0].id);
      await store.toggleChecked(store.itemsOf(listId)[2].id);
    });

    test('uncheck all', () async {
      await store.uncheckAll(listId);
      expect(store.progressOf(listId), (checked: 0, total: 3));
      expect(repo.itemRows.values.where((i) => i.checked), isEmpty);
    });

    test('remove checked items (soft delete)', () async {
      expect(await store.removeChecked(listId), 2);
      expect(namesOf(listId), ['Bread']);
      expect(repo.itemRows.values.where((i) => i.isDeleted).map((i) => i.name),
          unorderedEquals(['Milk', 'Apples']));
    });
  });

  test('load() restores the state from the repository', () async {
    final list = await store.createList('Weekly');
    await store.addItem(list.id, 'Milk', note: '2 l');
    await store.addItem(list.id, 'Bread');
    await store.deleteItem(store.itemsOf(list.id).last.id);
    final gone = await store.createList('Gone');
    await store.addItem(gone.id, 'Cake');
    await store.deleteList(gone.id);

    final reloaded = ListStore(repo);
    await reloaded.load();
    expect(reloaded.lists.map((l) => l.name), ['Weekly']);
    expect(reloaded.itemsOf(list.id).map((i) => (i.name, i.note)), [('Milk', '2 l')]);
  });
}
