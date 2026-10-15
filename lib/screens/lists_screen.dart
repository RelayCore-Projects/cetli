import 'package:flutter/material.dart';

import '../models/shopping_list.dart';
import '../state/store_scope.dart';
import '../widgets/dialogs.dart';
import 'list_screen.dart';
import 'settings_screen.dart';

/// FR-01: the home screen – all lists, the most recently changed first.
/// FR-20: a long press starts selection mode (rename one, delete several).
class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final _selected = <String>{};

  bool get _selecting => _selected.isNotEmpty;

  void _toggle(String id) => setState(() {
        if (!_selected.remove(id)) _selected.add(id);
      });

  void _clearSelection() => setState(_selected.clear);

  Future<void> _create() async {
    final store = StoreScope.read(context);
    final name = await showNameDialog(
      context,
      title: 'New list',
      initial: store.defaultListName(),
      confirmLabel: 'Create',
    );
    if (name == null || !mounted) return;
    final list = await store.createList(name);
    if (!mounted) return;
    // FR-02: a new list opens in edit mode
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ListScreen(listId: list.id, startEditing: true),
    ));
  }

  Future<void> _renameSelected(ShoppingList list) async {
    final store = StoreScope.read(context);
    final name = await showNameDialog(
      context,
      title: 'Rename list',
      initial: list.name,
      confirmLabel: 'Save',
    );
    if (name == null) return;
    await store.renameList(list.id, name);
    if (mounted) _clearSelection();
  }

  Future<void> _deleteSelected(List<ShoppingList> selected) async {
    final store = StoreScope.read(context);
    final ok = await confirm(
      context,
      title: selected.length == 1 ? 'Delete list?' : 'Delete ${selected.length} lists?',
      message: selected.length == 1
          ? '"${selected.single.name}" and all its items will be deleted.'
          : 'The selected lists and all their items will be deleted.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    await store.deleteLists(selected.map((l) => l.id));
    if (mounted) _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final lists = store.lists;
    final theme = Theme.of(context);
    // lists deleted elsewhere drop out of the selection
    _selected.removeWhere((id) => store.listById(id) == null);
    final selected = [for (final l in lists) if (_selected.contains(l.id)) l];

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: _selecting ? _selectionBar(selected, lists) : _normalBar(),
        body: lists.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No lists yet.\nTap + to create one.',
                    key: const Key('empty-lists'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: lists.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final list = lists[index];
                  final progress = store.progressOf(list.id);
                  final isSelected = _selected.contains(list.id);
                  return ListTile(
                    key: Key('list-${list.id}'),
                    selected: isSelected,
                    selectedTileColor: theme.colorScheme.secondaryContainer,
                    leading: _selecting
                        ? Icon(isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked)
                        : null,
                    title: Text(list.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      '${progress.checked} / ${progress.total}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    onLongPress: () => _toggle(list.id),
                    // FR-01: an existing list opens in shopping mode
                    onTap: _selecting
                        ? () => _toggle(list.id)
                        : () => Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => ListScreen(listId: list.id),
                            )),
                  );
                },
              ),
        floatingActionButton: _selecting
            ? null
            : FloatingActionButton(
                key: const Key('new-list'),
                tooltip: 'New list',
                onPressed: _create,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  AppBar _normalBar() => AppBar(
        title: const Text('Cetli'),
        actions: [
          PopupMenuButton<String>(
            key: const Key('home-menu'),
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      );

  AppBar _selectionBar(List<ShoppingList> selected, List<ShoppingList> all) => AppBar(
        leading: IconButton(
          key: const Key('clear-selection'),
          tooltip: 'Cancel selection',
          icon: const Icon(Icons.close),
          onPressed: _clearSelection,
        ),
        title: Text('${selected.length} selected', key: const Key('selection-count')),
        actions: [
          if (selected.length < all.length)
            IconButton(
              key: const Key('select-all'),
              tooltip: 'Select all',
              icon: const Icon(Icons.select_all),
              onPressed: () => setState(() => _selected.addAll(all.map((l) => l.id))),
            ),
          if (selected.length == 1)
            IconButton(
              key: const Key('rename-selected'),
              tooltip: 'Rename',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _renameSelected(selected.single),
            ),
          IconButton(
            key: const Key('delete-selected'),
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteSelected(selected),
          ),
        ],
      );
}
