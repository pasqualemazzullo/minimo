import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/inventory_repository.dart';

class DeleteInventoryUseCase {
  final InventoryRepository _inventoryRepository;

  const DeleteInventoryUseCase(this._inventoryRepository);

  Future<Result<void>> call(String inventoryId) async {
    if (inventoryId.isEmpty) {
      return Error(ValidationFailure('ID inventario non valido'));
    }

    return await _inventoryRepository.deleteInventory(inventoryId);
  }
}