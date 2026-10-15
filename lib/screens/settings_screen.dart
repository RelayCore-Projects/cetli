import 'package:flutter/material.dart';

import '../app_info.dart';
import '../domain/sorting.dart';
import '../state/settings_scope.dart';
import '../widgets/dialogs.dart';

/// FR-19: general settings and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pickCheckedPosition(BuildContext context) async {
    final store = SettingsScope.read(context);
    final current = store.value;
    final position = await showChoiceDialog<CheckedPosition>(
      context,
      title: 'Checked items',
      options: CheckedPosition.values,
      selected: current.checkedPosition,
      label: (p) => p.label,
      id: (p) => p.key,
      keyPrefix: 'checked',
    );
    if (position != null) {
      await store.update(current.copyWith(checkedPosition: position));
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppInfo.name,
      applicationVersion: AppInfo.version,
      applicationIcon: const Icon(Icons.checklist, size: 40),
      applicationLegalese: AppInfo.legalese,
      children: const [
        SizedBox(height: 16),
        Text(AppInfo.privacy, key: Key('privacy')),
        SizedBox(height: 8),
        Text(AppInfo.repoUrl),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.valueOf(context);
    final theme = Theme.of(context);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          section('Shopping'),
          ListTile(
            key: const Key('setting-checked-position'),
            leading: const Icon(Icons.low_priority),
            title: const Text('Checked items'),
            subtitle: Text(settings.checkedPosition.label),
            onTap: () => _pickCheckedPosition(context),
          ),
          section('About'),
          ListTile(
            key: const Key('about'),
            leading: const Icon(Icons.info_outline),
            title: const Text('About Cetli'),
            subtitle: const Text(AppInfo.version),
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }
}
