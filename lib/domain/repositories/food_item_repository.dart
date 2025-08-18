import '../../core/utils/result.dart';
import '../entities/food_item_entity.dart';

abstract class FoodItemRepository {
  Future<Result<List<FoodItemEntity>>> getInventoryFoodItems(String inventoryId);

  Future<Result<FoodItemEntity>> addFoodItem({
    required String inventoryId,
    required String name,
    required String category,
    required String quantity,
    DateTime? expiryDate,
    String? imageUrl,
    bool? isOutOfStock,
  });

  Future<Result<FoodItemEntity>> updateFoodItem(FoodItemEntity foodItem);

  Future<Result<void>> deleteFoodItem(String foodItemId);

  Future<Result<FoodItemEntity?>> getFoodItemById(String foodItemId);

  Future<Result<List<FoodItemEntity>>> getExpiredItems(String inventoryId);

  Future<Result<List<FoodItemEntity>>> getExpiringSoonItems(String inventoryId);

  Future<Result<List<FoodItemEntity>>> getOutOfStockItems(String inventoryId);
}