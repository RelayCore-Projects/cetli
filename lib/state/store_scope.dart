import 'package:flutter/widgets.dart';

import 'list_store.dart';

/// Makes the [ListStore] available to every screen.
class StoreScope extends InheritedNotifier<ListStore> {
  const StoreScope({
    super.key,
    required ListStore store,
    required super.child,
  }) : super(notifier: store);

  /// Listens: rebuilds the caller when the lists change.
  static ListStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// Reads without listening (e.g. in button handlers).
  static ListStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
