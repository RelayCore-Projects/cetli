import 'package:flutter/foundation.dart';

import '../data/settings_repository.dart';
import '../domain/settings.dart';

/// The general settings (FR-19) in memory, written through to the repository.
class SettingsStore extends ChangeNotifier {
  SettingsStore(this._repository);

  /// For tests and as a default: keeps the settings in memory.
  factory SettingsStore.inMemory([AppSettings initial = const AppSettings()]) =>
      SettingsStore(InMemorySettingsRepository(initial.toMap())).._value = initial;

  final SettingsRepository _repository;

  AppSettings _value = const AppSettings();

  AppSettings get value => _value;

  Future<void> load() async {
    _value = AppSettings.fromMap(await _repository.loadSettings());
    notifyListeners();
  }

  Future<void> update(AppSettings next) async {
    if (next == _value) return;
    await _repository.saveSettings(next.toMap());
    _value = next;
    notifyListeners();
  }
}
