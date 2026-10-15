/// Settings stored as key–value pairs (SQLite `settings` table; in memory for tests).
abstract class SettingsRepository {
  Future<Map<String, String>> loadSettings();

  /// Replaces all settings in one step.
  Future<void> saveSettings(Map<String, String> values);
}

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([Map<String, String> initial = const {}])
      : values = Map.of(initial);

  Map<String, String> values;

  @override
  Future<Map<String, String>> loadSettings() async => Map.of(values);

  @override
  Future<void> saveSettings(Map<String, String> values) async {
    this.values = Map.of(values);
  }
}
