/// Constant application data.
class AppInfo {
  AppInfo._();

  static const name = 'Cetli';

  /// Set by CI for released APKs: --dart-define=APP_VERSION=0.2.0
  static const version =
      String.fromEnvironment('APP_VERSION', defaultValue: 'development build');

  static const repoUrl = 'https://github.com/RelayCore-Projects/cetli';

  static const legalese = '© 2026 RelayCore-Projects · MIT License';

  static const privacy = 'Your data stays on this device.';
}
