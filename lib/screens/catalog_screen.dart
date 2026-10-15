import 'package:flutter/material.dart';

import '../domain/text_rules.dart';
import '../models/catalog_item.dart';
import '../state/catalog_scope.dart';
import '../widgets/dialogs.dart';

/// FR-10: the catalog – built-in entries are read-only, the user's own entries
/// can be added, renamed and deleted.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _query = TextEditingController();
  bool _onlyMine = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _showMessage(String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  Future<void> _add() async {
    final catalog = CatalogScope.read(context);
    final name = await showNameDialog(
      context,
      title: 'New item',
      initial: '',
      confirmLabel: 'Add',
      label: 'Item',
      maxLength: TextRules.itemNameMaxLength,
    );
    if (name == null) return;
    final added = await catalog.addCustom(name);
    if (added == null && mounted) _showMessage('"$name" is already in the catalog');
  }

  Future<void> _rename(CatalogItem item) async {
    final catalog = CatalogScope.read(context);
    final name = await showNameDialog(
      context,
      title: 'Rename item',
      initial: item.name,
      confirmLabel: 'Save',
      label: 'Item',
      maxLength: TextRules.itemNameMaxLength,
    );
    if (name == null) return;
    final ok = await catalog.renameCustom(item.id, name);
    if (!ok && mounted) _showMessage('"$name" is already in the catalog');
  }

  Future<void> _delete(CatalogItem item) async {
    final catalog = CatalogScope.read(context);
    final deleted = await catalog.deleteCustom(item.id);
    if (!mounted) return;
    _showMessage(
      '"${item.name}" deleted',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => catalog.restoreCustom(deleted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.of(context);
    final theme = Theme.of(context);
    final items = [
      for (final i in catalog.search(_query.text))
        if (!_onlyMine || !i.builtin) i,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Catalog')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              key: const Key('catalog-search'),
              controller: _query,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(_query.clear),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                FilterChip(
                  key: const Key('only-mine'),
                  label: const Text('My items'),
                  selected: _onlyMine,
                  onSelected: (v) => setState(() => _onlyMine = v),
                ),
                const Spacer(),
                Text(
                  items.length == 1 ? '1 item' : '${items.length} items',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No matching items',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return ListTile(
                        key: Key('catalog-${item.nameKey}'),
                        title: Text(item.name),
                        subtitle: item.builtin ? null : const Text('My item'),
                        trailing: item.builtin
                            ? null
                            : IconButton(
                                key: Key('catalog-delete-${item.nameKey}'),
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(item),
                              ),
                        // built-in entries are read-only (ADR-007)
                        onTap: item.builtin ? null : () => _rename(item),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add-catalog-item'),
        tooltip: 'Add item',
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
