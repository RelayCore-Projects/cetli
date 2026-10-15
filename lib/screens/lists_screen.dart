import 'package:flutter/material.dart';

import '../state/store_scope.dart';
import '../widgets/dialogs.dart';
import 'list_screen.dart';
import 'settings_screen.dart';

/// FR-01: the home screen – all lists, the most recently changed first.
class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final store = StoreScope.read(context);
    final name = await showNameDialog(
      context,
      title: 'New list',
      initial: store.defaultListName(),
      confirmLabel: 'Create',
    );
    if (name == null || !context.mounted) return;
    final list = await store.createList(name);
    if (!context.mounted) return;
    // FR-02: a new list opens in edit mode
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ListScreen(listId: list.id, startEditing: true),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final lists = store.lists;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
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
      ),
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
                return ListTile(
                  key: Key('list-${list.id}'),
                  title: Text(list.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    '${progress.checked} / ${progress.total}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  // FR-01: an existing list opens in shopping mode
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ListScreen(listId: list.id),
                  )),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        key: const Key('new-list'),
        tooltip: 'New list',
        onPressed: () => _create(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
