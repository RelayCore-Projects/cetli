import '../domain/text_rules.dart' as rules;

/// One line of a shopping list (data model: docs/01 Specifikáció, section 6).
class ListItem {
  ListItem({
    required this.id,
    required this.listId,
    required this.name,
    String? nameKey,
    this.note,
    this.checked = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  }) : nameKey = nameKey ?? computeNameKey(name);

  static String computeNameKey(String name) => rules.nameKey(name);

  final String id;
  final String listId;
  final String name;

  /// Normalised name; unique among the non-deleted items of a list (FR-05).
  final String nameKey;

  /// Optional free text: quantity, variety, brand (FR-06).
  final String? note;
  final bool checked;

  /// UTC timestamps; [createdAt] gives the "order added".
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soft delete (tombstone).
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  static const _unset = Object();

  ListItem copyWith({
    String? name,
    Object? note = _unset,
    bool? checked,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) {
    final newName = name ?? this.name;
    return ListItem(
      id: id,
      listId: listId,
      name: newName,
      nameKey: name == null ? nameKey : computeNameKey(newName),
      note: identical(note, _unset) ? this.note : note as String?,
      checked: checked ?? this.checked,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt:
          identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'list_id': listId,
        'name': name,
        'name_key': nameKey,
        'note': note,
        'checked': checked ? 1 : 0,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'deleted_at': deletedAt?.toUtc().toIso8601String(),
      };

  factory ListItem.fromMap(Map<String, Object?> map) {
    final deleted = map['deleted_at'] as String?;
    return ListItem(
      id: map['id']! as String,
      listId: map['list_id']! as String,
      name: map['name']! as String,
      nameKey: map['name_key']! as String,
      note: map['note'] as String?,
      checked: (map['checked'] as int? ?? 0) != 0,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
      deletedAt: deleted == null ? null : DateTime.parse(deleted),
    );
  }

  @override
  String toString() => 'ListItem($id, $name${checked ? ', checked' : ''})';
}
