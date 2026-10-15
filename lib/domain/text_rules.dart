/// Limits and normalisation of user-entered text (spec FR-02, FR-03, FR-06).
class TextRules {
  TextRules._();

  static const listNameMaxLength = 40;
  static const itemNameMaxLength = 60;
  static const noteMaxLength = 100;
}

final _whitespace = RegExp(r'\s+');

/// Trims the text and collapses inner whitespace to a single space.
String normalizeText(String raw) => raw.trim().replaceAll(_whitespace, ' ');

/// The name key used to compare item names: `Bread`, `bread` and ` bread ` are
/// the same item. Accents are significant (`kenyér` ≠ `kenyer`).
String nameKey(String name) => normalizeText(name).toLowerCase();

/// A cleaned item or list name, cut to [maxLength]; empty → null.
String? cleanName(String raw, int maxLength) {
  final text = normalizeText(raw);
  if (text.isEmpty) return null;
  return text.length > maxLength ? text.substring(0, maxLength) : text;
}

/// A cleaned note: trimmed, at most [TextRules.noteMaxLength] characters; empty → null.
String? cleanNote(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return null;
  return text.length > TextRules.noteMaxLength
      ? text.substring(0, TextRules.noteMaxLength)
      : text;
}
