import 'package:flutter/widgets.dart';

import '../domain/settings.dart';
import 'settings_store.dart';

/// Makes the [SettingsStore] available to every screen.
class SettingsScope extends InheritedNotifier<SettingsStore> {
  const SettingsScope({
    super.key,
    required SettingsStore settings,
    required super.child,
  }) : super(notifier: settings);

  static SettingsStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;

  static SettingsStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SettingsScope>()!.notifier!;

  /// Shortcut: the current settings, listening.
  static AppSettings valueOf(BuildContext context) => of(context).value;
}
