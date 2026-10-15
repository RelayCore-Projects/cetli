import 'package:flutter/widgets.dart';

import 'catalog_store.dart';

/// Makes the [CatalogStore] available to every screen.
class CatalogScope extends InheritedNotifier<CatalogStore> {
  const CatalogScope({
    super.key,
    required CatalogStore catalog,
    required super.child,
  }) : super(notifier: catalog);

  static CatalogStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CatalogScope>()!.notifier!;

  static CatalogStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CatalogScope>()!.notifier!;
}
