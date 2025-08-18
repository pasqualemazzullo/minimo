import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';
import '../../repositories/shopping_list_repository.dart';

class RestockSelectedItemsUseCase {
  final ShoppingListRepository _shoppingListRepository;

  const RestockSelectedItemsUseCase(this._shoppingListRepository);

  Future<Result<void>> call({
    required String inventoryId,
    required List<String> selectedItemIds,
  }) async {
    if (inventoryId.trim().isEmpty) {
      return const Error(ValidationFailure('ID inventario non valido'));
    }

    if (selectedItemIds.isEmpty) {
      return const Error(ValidationFailure('Nessun elemento selezionato'));
    }

    return await _shoppingListRepository.restockSelectedItems(
      inventoryId,
      selectedItemIds,
    );
  }
}