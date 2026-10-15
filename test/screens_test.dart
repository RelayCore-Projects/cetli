import 'package:cetli/app.dart';
import 'package:cetli/data/in_memory_list_repository.dart';
import 'package:cetli/domain/settings.dart';
import 'package:cetli/domain/sorting.dart';
import 'package:cetli/state/list_store.dart';
import 'package:cetli/state/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/factory.dart';

/// Builds the app on a phone-sized screen (432×960 logical pixels).
Future<ListStore> _pump(
  WidgetTester tester, {
  ListStore? store,
  AppSettings settings = const AppSettings(),
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final s = store ?? _newStore();
  await tester.pumpWidget(
    CetliApp(store: s, settings: SettingsStore.inMemory(settings)),
  );
  await tester.pumpAndSettle();
  return s;
}

ListStore _newStore() => ListStore(
      InMemoryListRepository(),
      clock: steppingClock(),
      newId: sequentialIds(),
    );

/// A store with one list "Weekly": Bread, Milk, Apples (in this order).
Future<(ListStore, String)> _weekly() async {
  final store = _newStore();
  final list = await store.createList('Weekly');
  for (final n in ['Bread', 'Milk', 'Apples']) {
    await store.addItem(list.id, n);
  }
  return (store, list.id);
}

Future<void> _openList(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

Future<void> _menu(WidgetTester tester, String key, String item) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('add-item-field')), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

bool _inputFocused(WidgetTester tester) => tester
    .widget<EditableText>(find.descendant(
      of: find.byKey(const Key('add-item-field')),
      matching: find.byType(EditableText),
    ))
    .focusNode
    .hasFocus;

String _status(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('list-status'))).data!;

double _top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text)).dy;

TextStyle? _style(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style;

void main() {
  testWidgets('FR-01/02: empty home, a new list opens in edit mode', (tester) async {
    await _pump(tester);
    expect(find.byKey(const Key('empty-lists')), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-list')));
    await tester.pumpAndSettle();
    expect(find.text('New list'), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const Key('name-field')));
    expect(field.controller!.text, 'List 16/10/2026');

    await tester.enterText(find.byKey(const Key('name-field')), 'Weekly shop');
    await tester.tap(find.byKey(const Key('name-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Weekly shop'), findsOneWidget);
    expect(_status(tester), 'Editing');
    expect(find.byKey(const Key('add-item-field')), findsOneWidget);
  });

  testWidgets('FR-03/05: Enter adds, the keyboard stays, duplicates are refused',
      (tester) async {
    final store = _newStore();
    final list = await store.createList('Weekly');
    await _pump(tester, store: store);
    await _openList(tester, 'Weekly');
    await tester.tap(find.byKey(const Key('start-editing')));
    await tester.pumpAndSettle();

    await _type(tester, 'Milk');
    expect(find.text('Milk'), findsOneWidget);
    expect(_inputFocused(tester), isTrue);

    await _type(tester, 'Bread');
    expect(find.text('Bread'), findsOneWidget);
    expect(_inputFocused(tester), isTrue);

    // re-entering a checked item unchecks it
    await store.toggleChecked(store.itemsOf(list.id).last.id);
    await tester.pumpAndSettle();
    await _type(tester, 'BREAD');
    expect(find.text('"Bread" is back on the list'), findsOneWidget);
    expect(store.progressOf(list.id).checked, 0);

    await _type(tester, ' milk ');
    expect(find.text('"Milk" is already on the list'), findsOneWidget);
    expect(store.itemsOf(list.id).map((i) => i.name), ['Milk', 'Bread']);
    expect(_inputFocused(tester), isTrue);

    // the message disappears when typing; the add button works too
    await tester.enterText(find.byKey(const Key('add-item-field')), 'Apples');
    await tester.pump();
    expect(find.text('"Milk" is already on the list'), findsNothing);
    await tester.tap(find.byKey(const Key('add-item')));
    await tester.pumpAndSettle();
    expect(store.itemsOf(list.id), hasLength(3));
  });

  testWidgets('FR-04/08: shopping mode ticks, strikes through, moves to the bottom',
      (tester) async {
    final (store, listId) = await _weekly();
    await _pump(tester, store: store);
    await _openList(tester, 'Weekly');
    expect(_status(tester), '0 / 3');
    expect(find.byKey(const Key('add-item-field')), findsNothing);

    await tester.tap(find.text('Bread'));
    await tester.pumpAndSettle();
    expect(_status(tester), '1 / 3');
    expect(_style(tester, 'Bread')!.decoration, TextDecoration.lineThrough);
    expect(_top(tester, 'Bread'), greaterThan(_top(tester, 'Apples')));

    await tester.tap(find.text('Bread'));
    await tester.pumpAndSettle();
    expect(_status(tester), '0 / 3');
    expect(_style(tester, 'Bread')?.decoration, isNot(TextDecoration.lineThrough));
    expect(_top(tester, 'Bread'), lessThan(_top(tester, 'Milk')));
    expect(store.progressOf(listId).checked, 0);
  });

  testWidgets('FR-08: with "Keep in place" a checked item stays where it was',
      (tester) async {
    final (store, _) = await _weekly();
    await _pump(tester,
        store: store,
        settings: const AppSettings(checkedPosition: CheckedPosition.inPlace));
    await _openList(tester, 'Weekly');
    await tester.tap(find.text('Bread'));
    await tester.pumpAndSettle();
    expect(_top(tester, 'Bread'), lessThan(_top(tester, 'Milk')));
  });

  testWidgets('FR-19: the setting is changed on the settings screen', (tester) async {
    await _pump(tester);
    await _menu(tester, 'home-menu', 'Settings');
    expect(find.text('Move to bottom'), findsOneWidget);
    await tester.tap(find.byKey(const Key('setting-checked-position')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('checked-in_place')));
    await tester.pumpAndSettle();
    expect(find.text('Keep in place'), findsOneWidget);
  });

  testWidgets('FR-07: sorting by name', (tester) async {
    final (store, listId) = await _weekly();
    await _pump(tester, store: store);
    await _openList(tester, 'Weekly');

    await _menu(tester, 'list-menu', 'Sort by…');
    await tester.tap(find.byKey(const Key('sort-name_desc')));
    await tester.pumpAndSettle();
    expect(_top(tester, 'Milk'), lessThan(_top(tester, 'Bread')));
    expect(_top(tester, 'Bread'), lessThan(_top(tester, 'Apples')));
    expect(store.listById(listId)!.sortMode, SortMode.nameDesc);

    await _menu(tester, 'list-menu', 'Sort by…');
    await tester.tap(find.byKey(const Key('sort-name_asc')));
    await tester.pumpAndSettle();
    expect(_top(tester, 'Apples'), lessThan(_top(tester, 'Bread')));
  });

  testWidgets('FR-03/06: edit an item, add a note, a clashing name is refused',
      (tester) async {
    final (store, listId) = await _weekly();
    await _pump(tester, store: store);
    await _openList(tester, 'Weekly');
    await tester.tap(find.byKey(const Key('edit')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bread'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('item-note-field')), 'whole grain');
    await tester.tap(find.byKey(const Key('item-save')));
    await tester.pumpAndSettle();
    expect(find.text('whole grain'), findsOneWidget);

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('item-name-field')), 'bread');
    await tester.tap(find.byKey(const Key('item-save')));
    await tester.pumpAndSettle();
    expect(find.text('Already on the list'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.itemsOf(listId).map((i) => i.name), ['Bread', 'Milk', 'Apples']);

    // the note is shown in shopping mode as well
    await tester.tap(find.byKey(const Key('done')));
    await tester.pumpAndSettle();
    expect(find.text('whole grain'), findsOneWidget);
    expect(find.byKey(const Key('add-item-field')), findsNothing);
  });

  testWidgets('FR-03: delete an item and undo', (tester) async {
    final (store, listId) = await _weekly();
    await _pump(tester, store: store);
    await _openList(tester, 'Weekly');
    await tester.tap(find.byKey(const Key('edit')));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Milk'),
      matching: find.byTooltip('Delete'),
    ));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Milk'), findsNothing);
    expect(find.text('"Milk" deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Milk'), findsOneWidget);
    expect(store.itemsOf(listId), hasLength(3));
  });

  testWidgets('FR-09: uncheck all and remove checked items', (tester) async {
    final (store, listId) = await _weekly();
    await store.toggleChecked(store.itemsOf(listId)[0].id); // Bread
    await store.toggleChecked(store.itemsOf(listId)[1].id); // Milk
    await _pump(tester, store: store);
    await _openList(tester, 'Weekly');
    expect(_status(tester), '2 / 3');

    await _menu(tester, 'list-menu', 'Uncheck all');
    expect(_status(tester), '0 / 3');

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();
    await _menu(tester, 'list-menu', 'Remove checked items');
    expect(find.text('1 checked item will be removed from the list.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm')));
    await tester.pumpAndSettle();
    expect(_status(tester), '0 / 2');
    expect(find.text('Milk'), findsNothing);
  });

  testWidgets('FR-02: rename and delete a list', (tester) async {
    final (store, _) = await _weekly();
    await _pump(tester, store: store);
    await _openList(tester, 'Weekly');

    await _menu(tester, 'list-menu', 'Rename list');
    await tester.enterText(find.byKey(const Key('name-field')), 'Party');
    await tester.tap(find.byKey(const Key('name-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Party'), findsOneWidget);

    await _menu(tester, 'list-menu', 'Delete list');
    await tester.tap(find.byKey(const Key('confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('empty-lists')), findsOneWidget);
    expect(store.lists, isEmpty);
  });

  testWidgets('FR-01: the home screen shows the progress of each list', (tester) async {
    final (store, listId) = await _weekly();
    await store.toggleChecked(store.itemsOf(listId).first.id);
    await _pump(tester, store: store);
    expect(find.text('1 / 3'), findsOneWidget);
  });
}
