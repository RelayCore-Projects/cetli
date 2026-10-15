import 'package:flutter/material.dart';

import '../domain/sorting.dart';
import '../domain/text_rules.dart';
import '../models/list_item.dart';
import '../models/shopping_list.dart';
import '../state/list_store.dart';
import '../state/settings_scope.dart';
import '../state/store_scope.dart';
import '../widgets/dialogs.dart';

/// One list in two modes: shopping (FR-04) and edit (FR-03).
class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.listId, this.startEditing = false});

  final String listId;
  final bool startEditing;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

enum _MenuAction { sort, uncheckAll, removeChecked, rename, delete }

class _ListScreenState extends State<ListScreen> {
  late bool _editing = widget.startEditing;
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();

  /// The item that was re-entered (FR-05) – highlighted until the next action.
  String? _highlightId;

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  ListStore get _store => StoreScope.read(context);

  void _setEditing(bool editing) {
    setState(() {
      _editing = editing;
      _highlightId = null;
    });
    if (!editing) {
      _input.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _showMessage(String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  /// FR-03: Enter adds the item and keeps the keyboard open for the next one.
  Future<void> _submit() async {
    final name = cleanName(_input.text, TextRules.itemNameMaxLength);
    _inputFocus.requestFocus();
    if (name == null) return;
    final result = await _store.addItem(widget.listId, name);
    if (!mounted) return;
    _input.clear();
    switch (result.outcome) {
      case AddOutcome.added:
        setState(() => _highlightId = null);
        _scrollToEndIfAddedOrder();
      case AddOutcome.alreadyOnList:
        setState(() => _highlightId = result.item.id);
        _showMessage('"${result.item.name}" is already on the list');
      case AddOutcome.unchecked:
        setState(() => _highlightId = result.item.id);
        _showMessage('"${result.item.name}" is back on the list');
    }
  }

  void _scrollToEndIfAddedOrder() {
    if (_store.listById(widget.listId)?.sortMode != SortMode.added) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _editItem(ListItem item) async {
    final store = _store;
    final edit = await showItemDialog(
      context,
      name: item.name,
      note: item.note,
      validateName: (name) =>
          store.findByName(item.listId, name, excludeId: item.id) != null
              ? 'Already on the list'
              : null,
    );
    if (edit == null) return;
    await store.updateItem(item.id, name: edit.name, note: edit.note);
  }

  Future<void> _deleteItem(ListItem item) async {
    final store = _store;
    final deleted = await store.deleteItem(item.id);
    if (!mounted) return;
    _showMessage(
      '"${item.name}" deleted',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          final restored = await store.restoreItem(deleted);
          if (!restored && mounted) {
            _showMessage('Cannot undo: "${item.name}" is on the list again');
          }
        },
      ),
    );
  }

  Future<void> _onMenu(_MenuAction action, ShoppingList list) async {
    final store = _store;
    switch (action) {
      case _MenuAction.sort:
        final mode = await showChoiceDialog<SortMode>(
          context,
          title: 'Sort items',
          options: SortMode.values,
          selected: list.sortMode,
          label: (m) => m.label,
          id: (m) => m.key,
          keyPrefix: 'sort',
        );
        if (mode != null) await store.setSortMode(list.id, mode);
      case _MenuAction.uncheckAll:
        await store.uncheckAll(list.id);
      case _MenuAction.removeChecked:
        final count = store.progressOf(list.id).checked;
        if (count == 0) {
          _showMessage('There are no checked items');
          return;
        }
        final ok = await confirm(
          context,
          title: 'Remove checked items?',
          message: count == 1
              ? '1 checked item will be removed from the list.'
              : '$count checked items will be removed from the list.',
          confirmLabel: 'Remove',
        );
        if (ok) await store.removeChecked(list.id);
      case _MenuAction.rename:
        final name = await showNameDialog(
          context,
          title: 'Rename list',
          initial: list.name,
          confirmLabel: 'Save',
        );
        if (name != null) await store.renameList(list.id, name);
      case _MenuAction.delete:
        final navigator = Navigator.of(context);
        final ok = await confirm(
          context,
          title: 'Delete list?',
          message: '"${list.name}" and all its items will be deleted.',
          confirmLabel: 'Delete',
        );
        if (!ok) return;
        await store.deleteList(list.id);
        navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final settings = SettingsScope.valueOf(context);
    final list = store.listById(widget.listId);
    if (list == null) return const Scaffold(body: SizedBox.shrink());

    final items =
        sortItems(store.itemsOf(list.id), list.sortMode, settings.checkedPosition);
    final progress = store.progressOf(list.id);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(list.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              _editing ? 'Editing' : '${progress.checked} / ${progress.total}',
              key: const Key('list-status'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (_editing)
            TextButton(
              key: const Key('done'),
              onPressed: () => _setEditing(false),
              child: const Text('Done'),
            )
          else
            IconButton(
              key: const Key('edit'),
              tooltip: 'Edit list',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _setEditing(true),
            ),
          PopupMenuButton<_MenuAction>(
            key: const Key('list-menu'),
            onSelected: (a) => _onMenu(a, list),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _MenuAction.sort, child: Text('Sort by…')),
              PopupMenuItem(value: _MenuAction.uncheckAll, child: Text('Uncheck all')),
              PopupMenuItem(
                  value: _MenuAction.removeChecked, child: Text('Remove checked items')),
              PopupMenuItem(value: _MenuAction.rename, child: Text('Rename list')),
              PopupMenuItem(value: _MenuAction.delete, child: Text('Delete list')),
            ],
          ),
        ],
      ),
      body: _editing ? _editBody(items, theme) : _shoppingBody(items, theme),
    );
  }

  Widget _shoppingBody(List<ListItem> items, ThemeData theme) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This list is empty.', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              key: const Key('start-editing'),
              onPressed: () => _setEditing(true),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Add items'),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      itemCount: items.length,
      itemBuilder: (_, i) => _itemTile(items[i], theme),
    );
  }

  Widget _editBody(List<ListItem> items, ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'Type an item and press Enter.',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  itemCount: items.length,
                  itemBuilder: (_, i) => _itemTile(items[i], theme),
                ),
        ),
        Material(
          color: theme.colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('add-item-field'),
                      controller: _input,
                      focusNode: _inputFocus,
                      autofocus: true,
                      maxLength: TextRules.itemNameMaxLength,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Add item',
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      // Handling onEditingComplete ourselves keeps the keyboard open (NFR-04)
                      onEditingComplete: _submit,
                    ),
                  ),
                  IconButton(
                    key: const Key('add-item'),
                    tooltip: 'Add',
                    icon: const Icon(Icons.add),
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemTile(ListItem item, ThemeData theme) {
    final scheme = theme.colorScheme;
    // NFR-06: a checked item is faded and struck through, but stays readable
    final faded = scheme.onSurface.withValues(alpha: 0.55);
    final titleStyle = item.checked
        ? TextStyle(
            color: faded,
            decoration: TextDecoration.lineThrough,
            decorationColor: faded,
          )
        : null;
    final note = item.note;

    return ListTile(
      key: Key('item-${item.id}'),
      tileColor: item.id == _highlightId ? scheme.secondaryContainer : null,
      leading: _editing
          ? null
          : Icon(
              item.checked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: item.checked ? faded : scheme.primary,
            ),
      title: Text(item.name, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: note == null
          ? null
          : Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: item.checked ? faded : scheme.onSurfaceVariant),
            ),
      trailing: _editing
          ? IconButton(
              key: Key('delete-${item.id}'),
              tooltip: 'Delete',
              icon: const Icon(Icons.close),
              onPressed: () => _deleteItem(item),
            )
          : null,
      onTap: _editing ? () => _editItem(item) : () => _store.toggleChecked(item.id),
    );
  }
}
