import '../../core/utils/result.dart';
import '../entities/shopping_list_item_entity.dart';

abstract class ShoppingListRepository {
  Future<Result<List<ShoppingListItemEntity>>> getShoppingListItems(String inventoryId);

  Future<Result<ShoppingListItemEntity>> addShoppingListItem({
    required String inventoryId,
    required String name,
    required String quantity,
    String? emoji,
    bool? isChecked,
  });

  Future<Result<ShoppingListItemEntity>> updateShoppingListItem(ShoppingListItemEntity item);

  Future<Result<void>> deleteShoppingListItem(String itemId);

  Future<Result<void>> markAllAsCompleted(String inventoryId);

  Future<Result<void>> restockAllItems(String inventoryId);

  Future<Result<void>> restockSelectedItems(String inventoryId, List<String> selectedItemIds);

  Future<Result<void>> addOutOfStockItemToShoppingList(String inventoryId, String name, String quantity, String emoji);
}