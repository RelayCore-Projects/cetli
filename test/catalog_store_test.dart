import 'dart:io';

import 'package:cetli/data/catalog_repository.dart';
import 'package:cetli/domain/text_rules.dart';
import 'package:cetli/models/catalog_item.dart';
import 'package:cetli/state/catalog_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/factory.dart';

const _builtin = [
  'Bread', 'Bread rolls', 'Breadcrumbs', 'Brown sugar', 'Milk', 'Oat milk',
  'Sour cream', 'Ice cream', 'Cream', 'Cream cheese', 'Apples',
];

void main() {
  late InMemoryCatalogRepository repo;
  late CatalogStore catalog;

  setUp(() {
    repo = InMemoryCatalogRepository();
    catalog = CatalogStore(repo,
        builtinNames: _builtin, clock: steppingClock(), newId: sequentialIds('c'));
  });

  List<String> names(Iterable<CatalogItem> items) => items.map((i) => i.name).toList();

  test('built-in entries are listed A–Z and flagged', () {
    expect(names(catalog.items).first, 'Apples');
    expect(catalog.items, hasLength(_builtin.length));
    expect(catalog.items.every((i) => i.builtin), isTrue);
  });

  group('FR-11 suggestions', () {
    test('names starting with the query come first, then the rest, at most 5', () {
      expect(names(catalog.suggestions('br')),
          ['Bread', 'Bread rolls', 'Breadcrumbs', 'Brown sugar']);
      expect(names(catalog.suggestions('cream')),
          ['Cream', 'Cream cheese', 'Ice cream', 'Sour cream']);
      expect(catalog.suggestions('e'), hasLength(5));
    });

    test('ignore case and whitespace; empty query gives nothing', () {
      expect(names(catalog.suggestions('  MILK ')), ['Milk', 'Oat milk']);
      expect(catalog.suggestions('   '), isEmpty);
    });

    test('names already on the list are excluded', () {
      expect(names(catalog.suggestions('br', exclude: {'bread', 'brown sugar'})),
          ['Bread rolls', 'Breadcrumbs']);
    });
  });

  group('FR-10 own entries', () {
    test('added, found and kept in the repository', () async {
      final item = await catalog.addCustom('  Tesco   Jaffa Cakes ');
      expect(item!.name, 'Tesco Jaffa Cakes');
      expect(item.builtin, isFalse);
      expect(catalog.findByName('tesco jaffa cakes')?.id, item.id);
      expect(repo.rows[item.id]!.name, 'Tesco Jaffa Cakes');
      expect(names(catalog.suggestions('jaffa')), ['Tesco Jaffa Cakes']);
    });

    test('a name already in the catalog is refused', () async {
      expect(await catalog.addCustom('bread'), isNull);
      await catalog.addCustom('Kefir');
      expect(await catalog.addCustom('KEFIR'), isNull);
    });

    test('rename, with clashes refused', () async {
      final kefir = (await catalog.addCustom('Kefir'))!;
      await catalog.addCustom('Quark');
      expect(await catalog.renameCustom(kefir.id, 'quark'), isFalse);
      expect(await catalog.renameCustom(kefir.id, 'Milk'), isFalse);
      expect(await catalog.renameCustom(kefir.id, 'Plain kefir'), isTrue);
      expect(catalog.findByName('plain kefir')?.id, kefir.id);
    });

    test('delete and undo', () async {
      final kefir = (await catalog.addCustom('Kefir'))!;
      final deleted = await catalog.deleteCustom(kefir.id);
      expect(catalog.findByName('Kefir'), isNull);
      expect(repo.rows[kefir.id]!.isDeleted, isTrue);
      expect(await catalog.restoreCustom(deleted), isTrue);
      expect(catalog.findByName('Kefir')?.id, kefir.id);
    });

    test('built-in entries are read-only', () async {
      final bread = catalog.findByName('Bread')!;
      await expectLater(catalog.renameCustom(bread.id, 'Loaf'), throwsStateError);
      await expectLater(catalog.deleteCustom(bread.id), throwsStateError);
    });

    test('FR-13: learn adds only unknown names', () async {
      await catalog.learn('bread');
      await catalog.learn('Tesco Jaffa Cakes');
      await catalog.learn('tesco jaffa cakes');
      expect(repo.rows.values.map((i) => i.name), ['Tesco Jaffa Cakes']);
    });

    test('own entries are loaded back; one that became built-in is shown once',
        () async {
      await catalog.addCustom('Kefir');
      await catalog.addCustom('Quark');
      final updated = CatalogStore(repo, builtinNames: [..._builtin, 'Quark']);
      await updated.load();
      expect(updated.findByName('Kefir')!.builtin, isFalse);
      expect(updated.items.where((i) => i.nameKey == 'quark'), hasLength(1));
      expect(updated.findByName('Quark')!.builtin, isTrue);
    });
  });

  test('the built-in asset is valid: no duplicates, no blank names', () {
    final names = parseBuiltinCatalog(
        File('assets/catalog/builtin_items.txt').readAsStringSync());
    expect(names.length, greaterThan(100));
    expect(names.map(nameKey).toSet(), hasLength(names.length));
    expect(names.every((n) => n.length <= TextRules.itemNameMaxLength), isTrue);
    expect(names, containsAll(['Bread rolls', 'Ground pork', 'Sour cream']));
  });
}
