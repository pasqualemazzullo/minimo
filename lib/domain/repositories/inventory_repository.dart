import '../../core/utils/result.dart';
import '../entities/inventory_entity.dart';

abstract class InventoryRepository {
  Future<Result<List<InventoryEntity>>> getUserInventories();

  Future<Result<InventoryEntity>> createInventory(String name);

  Future<Result<InventoryEntity>> updateInventory(InventoryEntity inventory);

  Future<Result<void>> deleteInventory(String inventoryId);

  Future<Result<InventoryEntity?>> getInventoryById(String inventoryId);
}