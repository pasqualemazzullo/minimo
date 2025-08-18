import '../../../core/utils/result.dart';
import '../../entities/inventory_entity.dart';
import '../../repositories/inventory_repository.dart';

class GetUserInventoriesUseCase {
  final InventoryRepository _inventoryRepository;

  const GetUserInventoriesUseCase(this._inventoryRepository);

  Future<Result<List<InventoryEntity>>> call() async {
    return await _inventoryRepository.getUserInventories();
  }
}