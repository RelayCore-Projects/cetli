import '../domain/sorting.dart';

/// A shopping list (data model: docs/01 Specifikáció, section 6).
class ShoppingList {
  const ShoppingList({
    required this.id,
    required this.name,
    this.sortMode = SortMode.added,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final SortMode sortMode;

  /// UTC timestamps.
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soft delete: a deleted list is hidden but stays in the database.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  ShoppingList copyWith({
    String? name,
    SortMode? sortMode,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      ShoppingList(
        id: id,
        name: name ?? this.name,
        sortMode: sortMode ?? this.sortMode,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'sort_mode': sortMode.key,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'deleted_at': deletedAt?.toUtc().toIso8601String(),
      };

  factory ShoppingList.fromMap(Map<String, Object?> map) {
    final deleted = map['deleted_at'] as String?;
    return ShoppingList(
      id: map['id']! as String,
      name: map['name']! as String,
      sortMode: SortMode.fromKey(map['sort_mode'] as String?),
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
      deletedAt: deleted == null ? null : DateTime.parse(deleted),
    );
  }

  @override
  String toString() => 'ShoppingList($id, $name)';
}
