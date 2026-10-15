import 'sorting.dart';

/// FR-19: the user's general settings.
class AppSettings {
  const AppSettings({this.checkedPosition = CheckedPosition.bottom});

  final CheckedPosition checkedPosition;

  AppSettings copyWith({CheckedPosition? checkedPosition}) =>
      AppSettings(checkedPosition: checkedPosition ?? this.checkedPosition);

  // ----- storage: key–value pairs (SQLite settings table) -----

  static const _kCheckedPosition = 'checked_position';

  Map<String, String> toMap() => {_kCheckedPosition: checkedPosition.key};

  /// Missing or unknown values fall back to the defaults.
  factory AppSettings.fromMap(Map<String, String> map) => AppSettings(
        checkedPosition: CheckedPosition.fromKey(map[_kCheckedPosition]),
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings && other.checkedPosition == checkedPosition;

  @override
  int get hashCode => checkedPosition.hashCode;
}
