import '../domain/text_rules.dart' as rules;

/// A catalog entry (FR-10). Built-in entries come from the app's asset file and
/// are read-only; the user's own entries are stored in the database.
class CatalogItem {
  CatalogItem({
    required this.id,
    required this.name,
    String? nameKey,
    this.builtin = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  }) : nameKey = nameKey ?? rules.nameKey(name);

  /// A built-in entry; its id is derived from the name key.
  factory CatalogItem.fromBuiltin(String name) {
    final epoch = DateTime.utc(2026);
    final key = rules.nameKey(name);
    return CatalogItem(
      id: 'builtin:$key',
      name: name,
      nameKey: key,
      builtin: true,
      createdAt: epoch,
      updatedAt: epoch,
    );
  }

  final String id;
  final String name;

  /// Normalised name; unique in the catalog.
  final String nameKey;

  /// Built-in entries are never stored, edited or deleted.
  final bool builtin;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  static const _unset = Object();

  CatalogItem copyWith({
    String? name,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) {
    final newName = name ?? this.name;
    return CatalogItem(
      id: id,
      name: newName,
      nameKey: name == null ? nameKey : rules.nameKey(newName),
      builtin: builtin,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt:
          identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'name_key': nameKey,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'deleted_at': deletedAt?.toUtc().toIso8601String(),
      };

  factory CatalogItem.fromMap(Map<String, Object?> map) {
    final deleted = map['deleted_at'] as String?;
    return CatalogItem(
      id: map['id']! as String,
      name: map['name']! as String,
      nameKey: map['name_key']! as String,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
      deletedAt: deleted == null ? null : DateTime.parse(deleted),
    );
  }

  @override
  String toString() => 'CatalogItem($name${builtin ? ', built-in' : ''})';
}

/// Parses the built-in catalog asset: one name per line, `#` starts a comment.
List<String> parseBuiltinCatalog(String text) => [
      for (final line in text.split('\n'))
        if (line.trim().isNotEmpty && !line.trimLeft().startsWith('#')) line.trim(),
    ];
