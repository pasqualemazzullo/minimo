import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/validators.dart';
import '../../entities/inventory_entity.dart';
import '../../repositories/inventory_repository.dart';

class CreateInventoryUseCase {
  final InventoryRepository _inventoryRepository;

  const CreateInventoryUseCase(this._inventoryRepository);

  Future<Result<InventoryEntity>> call(String name) async {
    final validationError = Validators.required(name, fieldName: 'Nome inventario');
    if (validationError != null) {
      return Error(ValidationFailure(validationError));
    }

    if (name.length > 50) {
      return Error(ValidationFailure('Il nome dell\'inventario non può superare i 50 caratteri'));
    }

    if (name.trim().length < 2) {
      return Error(ValidationFailure('Il nome dell\'inventario deve contenere almeno 2 caratteri'));
    }

    return await _inventoryRepository.createInventory(name.trim());
  }
}