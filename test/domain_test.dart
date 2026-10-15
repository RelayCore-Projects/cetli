import 'package:cetli/domain/settings.dart';
import 'package:cetli/domain/sorting.dart';
import 'package:cetli/domain/text_rules.dart';
import 'package:cetli/util/format.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/factory.dart';

void main() {
  group('name key (FR-05)', () {
    test('ignores case and surrounding / repeated whitespace', () {
      expect(nameKey('Bread'), 'bread');
      expect(nameKey('  bread '), 'bread');
      expect(nameKey('Sour   Cream'), 'sour cream');
      expect(nameKey('Bread'), nameKey(' BREAD'));
    });

    test('keeps accents significant', () {
      expect(nameKey('Kenyér'), 'kenyér');
      expect(nameKey('kenyér') == nameKey('kenyer'), isFalse);
    });

    test('cleanName trims, collapses and limits the length', () {
      expect(cleanName('  Tesco   Jaffa Cakes ', 60), 'Tesco Jaffa Cakes');
      expect(cleanName('   ', 60), isNull);
      expect(cleanName('a' * 70, 60), 'a' * 60);
    });

    test('cleanNote trims and turns empty into null', () {
      expect(cleanNote(' 2 l '), '2 l');
      expect(cleanNote(''), isNull);
      expect(cleanNote(null), isNull);
      expect(cleanNote('x' * 120)!.length, TextRules.noteMaxLength);
    });
  });

  group('sorting (FR-07, FR-08)', () {
    final items = [
      listItem('a', 'l', 'milk', minute: 1),
      listItem('b', 'l', 'Bread', minute: 2, checked: true),
      listItem('c', 'l', 'apples', minute: 3),
      listItem('d', 'l', 'Cheese', minute: 4),
    ];
    List<String> names(SortMode m, CheckedPosition p) =>
        sortItems(items, m, p).map((i) => i.name).toList();

    test('order added, checked kept in place', () {
      expect(names(SortMode.added, CheckedPosition.inPlace),
          ['milk', 'Bread', 'apples', 'Cheese']);
    });

    test('order added, checked moved to the bottom', () {
      expect(names(SortMode.added, CheckedPosition.bottom),
          ['milk', 'apples', 'Cheese', 'Bread']);
    });

    test('name A–Z and Z–A ignore case', () {
      expect(names(SortMode.nameAsc, CheckedPosition.inPlace),
          ['apples', 'Bread', 'Cheese', 'milk']);
      expect(names(SortMode.nameDesc, CheckedPosition.inPlace),
          ['milk', 'Cheese', 'Bread', 'apples']);
    });

    test('the sort order applies within both groups', () {
      expect(names(SortMode.nameAsc, CheckedPosition.bottom),
          ['apples', 'Cheese', 'milk', 'Bread']);
    });

    test('stored keys round-trip, unknown keys fall back to defaults', () {
      for (final m in SortMode.values) {
        expect(SortMode.fromKey(m.key), m);
      }
      expect(SortMode.fromKey('nonsense'), SortMode.added);
      expect(SortMode.fromKey(null), SortMode.added);
      expect(CheckedPosition.fromKey('in_place'), CheckedPosition.inPlace);
      expect(CheckedPosition.fromKey(null), CheckedPosition.bottom);
    });
  });

  group('settings (FR-19)', () {
    test('default: checked items move to the bottom', () {
      expect(const AppSettings().checkedPosition, CheckedPosition.bottom);
      expect(AppSettings.fromMap(const {}), const AppSettings());
    });

    test('round-trips through the key–value map', () {
      const s = AppSettings(checkedPosition: CheckedPosition.inPlace);
      expect(AppSettings.fromMap(s.toMap()), s);
    });
  });

  test('en_GB date format', () {
    expect(formatDate(DateTime(2026, 1, 5)), '05/01/2026');
  });
}
