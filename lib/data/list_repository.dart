import '../models/list_item.dart';
import '../models/shopping_list.dart';

/// Storage abstraction: the app uses SQLite, the tests keep data in memory.
abstract class ListRepository {
  /// All lists that are not deleted.
  Future<List<ShoppingList>> loadLists();

  /// All items that are not deleted, from every list that is not deleted.
  Future<List<ListItem>> loadItems();

  Future<void> insertList(ShoppingList list);

  /// Overwrites the whole row (edits and soft delete as well).
  Future<void> updateList(ShoppingList list);

  Future<void> insertItem(ListItem item);

  Future<void> updateItem(ListItem item);

  /// Updates several items in one step (one transaction in SQLite).
  Future<void> updateItems(List<ListItem> items);
}
