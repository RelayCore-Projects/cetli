import 'package:flutter/material.dart';

import 'app.dart';
import 'data/sqlite_repository.dart';
import 'state/list_store.dart';
import 'state/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SqliteRepository.open();
  final store = ListStore(repository);
  final settings = SettingsStore(repository);
  await Future.wait([store.load(), settings.load()]);
  runApp(CetliApp(store: store, settings: settings));
}
