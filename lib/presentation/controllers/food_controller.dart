import 'package:flutter/foundation.dart';

import '../../data/models/food_item_model.dart';
import '../../data/models/inventory_model.dart';
import '../../data/datasources/remote/database_service.dart';
import '../../core/utils/logger.dart';

class FoodController extends ChangeNotifier {
  final List<FoodItemModel> _allFoodItems = [];
  List<InventoryModel> _inventories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<FoodItemModel> get allFoodItems => List.unmodifiable(_allFoodItems);
  List<InventoryModel> get inventories => List.unmodifiable(_inventories);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get food items for specific inventory
  List<FoodItemModel> getFoodItemsForInventory(String inventoryId) {
    return _allFoodItems
        .where((item) => item.inventoryId == inventoryId)
        .toList();
  }

  // Get statistics
  int get expiredItemsCount {
    return _allFoodItems
        .where((item) => item.status == FoodStatus.expired)
        .length;
  }

  int get expiringSoonItemsCount {
    return _allFoodItems
        .where((item) => item.status == FoodStatus.expiringSoon)
        .length;
  }

  int get outOfStockItemsCount {
    return _allFoodItems
        .where((item) => item.status == FoodStatus.outOfStock)
        .length;
  }

  FoodItemModel? get nextExpiringItem {
    final validItems =
        _allFoodItems
            .where(
              (item) =>
                  item.status == FoodStatus.fresh ||
                  item.status == FoodStatus.expiringSoon,
            )
            .where((item) => item.expiryDate != null)
            .toList();

    if (validItems.isEmpty) return null;

    validItems.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
    return validItems.first;
  }

  String? getInventoryNameForItem(FoodItemModel item) {
    try {
      final inventory = _inventories.firstWhere(
        (inv) => inv.id == item.inventoryId,
      );
      return inventory.name;
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load all data
  Future<void> loadAllData() async {
    _setLoading(true);
    _setError(null);

    try {
      // Load inventories first
      _inventories = await DatabaseService.getUserInventories();

      // Load all food items from all inventories
      _allFoodItems.clear();
      for (final inventory in _inventories) {
        final items = await DatabaseService.getInventoryFoodItems(inventory.id);
        _allFoodItems.addAll(items);
      }

      Logger.info(
        'Loaded ${_allFoodItems.length} food items from ${_inventories.length} inventories',
      );
    } catch (e) {
      Logger.error('Failed to load food data', error: e);
      _setError('Errore nel caricamento dei dati: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update a food item
  Future<void> updateFoodItem(FoodItemModel updatedItem) async {
    try {
      await DatabaseService.updateFoodItem(updatedItem);

      // Update local state
      final index = _allFoodItems.indexWhere(
        (item) => item.id == updatedItem.id,
      );
      if (index != -1) {
        _allFoodItems[index] = updatedItem;
        notifyListeners();
        Logger.info('Updated food item: ${updatedItem.name}');
      }
    } catch (e) {
      Logger.error('Failed to update food item', error: e);
      rethrow;
    }
  }

  // Delete a food item
  Future<void> deleteFoodItem(String itemId) async {
    try {
      await DatabaseService.deleteFoodItem(itemId);

      // Update local state
      _allFoodItems.removeWhere((item) => item.id == itemId);
      notifyListeners();
      Logger.info('Deleted food item with id: $itemId');
    } catch (e) {
      Logger.error('Failed to delete food item', error: e);
      rethrow;
    }
  }

  // Add a new food item
  Future<void> addFoodItem(FoodItemModel newItem) async {
    try {
      final addedItem = await DatabaseService.addFoodItem(
        inventoryId: newItem.inventoryId,
        name: newItem.name,
        category: newItem.category,
        quantity: newItem.quantity,
        expiryDate: newItem.expiryDate,
        imageUrl: newItem.imageUrl,
      );

      // Update local state
      _allFoodItems.add(addedItem);
      notifyListeners();
      Logger.info('Added new food item: ${newItem.name}');
    } catch (e) {
      Logger.error('Failed to add food item', error: e);
      rethrow;
    }
  }

  // Refresh data (useful for pull-to-refresh)
  Future<void> refresh() async {
    await loadAllData();
  }

  // Search food items by name
  List<FoodItemModel> searchFoodItems(String query) {
    if (query.isEmpty) return [];

    return _allFoodItems
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
