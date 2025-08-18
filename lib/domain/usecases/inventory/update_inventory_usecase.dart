import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/inventory_entity.dart';
import '../../repositories/inventory_repository.dart';

class UpdateInventoryUseCase {
  final InventoryRepository _inventoryRepository;

  const UpdateInventoryUseCase(this._inventoryRepository);

  Future<Result<InventoryEntity>> call(InventoryEntity inventory) async {
    if (inventory.id.isEmpty) {
      return Error(ValidationFailure('ID inventario non valido'));
    }

    if (inventory.name.trim().isEmpty) {
      return Error(ValidationFailure('Il nome dell\'inventario non può essere vuoto'));
    }

    if (inventory.name.length > 50) {
      return Error(ValidationFailure('Il nome dell\'inventario non può superare i 50 caratteri'));
    }

    return await _inventoryRepository.updateInventory(inventory);
  }
}