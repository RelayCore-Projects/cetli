import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/lists_screen.dart';
import 'state/catalog_scope.dart';
import 'state/catalog_store.dart';
import 'state/list_store.dart';
import 'state/settings_scope.dart';
import 'state/settings_store.dart';
import 'state/store_scope.dart';

class CetliApp extends StatelessWidget {
  CetliApp({
    super.key,
    required this.store,
    SettingsStore? settings,
    CatalogStore? catalog,
  })  : settings = settings ?? SettingsStore.inMemory(),
        catalog = catalog ?? CatalogStore.inMemory();

  final ListStore store;
  final SettingsStore settings;

  /// Must be the catalog the [store] learns into (FR-13).
  final CatalogStore catalog;

  /// Brand colour (the icon uses the same green).
  static const seed = Color(0xFF2E7D5B);

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: settings,
      child: CatalogScope(
        catalog: catalog,
        child: StoreScope(
          store: store,
          child: MaterialApp(
            title: 'Cetli',
            debugShowCheckedModeBanner: false,
            // NFR-03: English UI with European formats (dd/MM/yyyy, 24-hour clock)
            locale: const Locale('en', 'GB'),
            supportedLocales: const [Locale('en', 'GB')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ThemeData(
              colorSchemeSeed: seed,
              brightness: Brightness.light,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorSchemeSeed: seed,
              brightness: Brightness.dark,
              useMaterial3: true,
            ),
            // NFR-07: follows the phone's theme
            themeMode: ThemeMode.system,
            home: const ListsScreen(),
          ),
        ),
      ),
    );
  }
}
