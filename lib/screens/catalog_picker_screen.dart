import 'package:flutter/material.dart';

import '../state/catalog_scope.dart';
import '../state/store_scope.dart';

/// FR-12: pick several catalog entries for a list. Returns the chosen names.
class CatalogPickerScreen extends StatefulWidget {
  const CatalogPickerScreen({super.key, required this.listId});

  final String listId;

  @override
  State<CatalogPickerScreen> createState() => _CatalogPickerScreenState();
}

class _CatalogPickerScreenState extends State<CatalogPickerScreen> {
  final _query = TextEditingController();

  /// Chosen entries: name key → name. Kept while the search changes.
  final _chosen = <String, String>{};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.of(context);
    final onList = {
      for (final i in StoreScope.of(context).itemsOf(widget.listId)) i.nameKey,
    };
    final items = catalog.search(_query.text);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('From catalog')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const Key('picker-search'),
              controller: _query,
              decoration: const InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
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
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];
                      final already = onList.contains(item.nameKey);
                      return CheckboxListTile(
                        key: Key('pick-${item.nameKey}'),
                        controlAffinity: ListTileControlAffinity.leading,
                        value: already || _chosen.containsKey(item.nameKey),
                        onChanged: already
                            ? null
                            : (v) => setState(() {
                                  if (v == true) {
                                    _chosen[item.nameKey] = item.name;
                                  } else {
                                    _chosen.remove(item.nameKey);
                                  }
                                }),
                        title: Text(item.name),
                        subtitle: already ? const Text('On the list') : null,
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('add-selected'),
                  onPressed: _chosen.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_chosen.values.toList()),
                  child: Text(_chosen.isEmpty ? 'Add' : 'Add (${_chosen.length})'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
