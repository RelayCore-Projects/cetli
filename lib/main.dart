import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/sqlite_repository.dart';
import 'models/catalog_item.dart';
import 'state/catalog_store.dart';
import 'state/list_store.dart';
import 'state/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SqliteRepository.open();
  final builtin = parseBuiltinCatalog(
      await rootBundle.loadString('assets/catalog/builtin_items.txt'));
  final catalog = CatalogStore(repository, builtinNames: builtin);
  final store = ListStore(repository, catalog: catalog);
  final settings = SettingsStore(repository);
  await Future.wait([store.load(), settings.load(), catalog.load()]);
  runApp(CetliApp(store: store, settings: settings, catalog: catalog));
}
