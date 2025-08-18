import 'package:flutter/foundation.dart';

import '../../data/models/inventory_model.dart';
import '../../data/datasources/remote/database_service.dart';
import '../../core/services/preferences_service.dart';
import '../../core/utils/logger.dart';

class InventorySelectionController extends ChangeNotifier {
  List<InventoryModel> _inventories = [];
  InventoryModel? _selectedInventory;
  bool _isLoading = false;
  String? _errorMessage;
  PreferencesService? _prefsService;

  // Getters
  List<InventoryModel> get inventories => List.unmodifiable(_inventories);
  InventoryModel? get selectedInventory => _selectedInventory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize the controller
  Future<void> initialize() async {
    _prefsService = await PreferencesService.getInstance();
    await loadInventories();
  }

  /// Load all inventories and restore selected inventory from preferences
  Future<void> loadInventories() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      final loadedInventories = await DatabaseService.getUserInventories();
      _inventories = loadedInventories;

      // Restore selected inventory from preferences
      await _restoreSelectedInventory();

      Logger.info('Loaded ${_inventories.length} inventories');
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Failed to load inventories: $error';
      Logger.error('Error loading inventories', error: error);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Select an inventory and persist the choice
  Future<void> selectInventory(InventoryModel inventory) async {
    if (_selectedInventory?.id == inventory.id) return;

    _selectedInventory = inventory;
    
    // Save to preferences
    if (_prefsService != null) {
      await _prefsService!.setSelectedInventoryId(inventory.id);
      Logger.info('Selected inventory saved: ${inventory.name}');
    }
    
    notifyListeners();
  }

  /// Select inventory by ID
  Future<void> selectInventoryById(String inventoryId) async {
    final inventory = _inventories.firstWhere(
      (inv) => inv.id == inventoryId,
      orElse: () => _inventories.isNotEmpty ? _inventories.first : throw Exception('No inventories available'),
    );
    await selectInventory(inventory);
  }

  /// Restore selected inventory from preferences
  Future<void> _restoreSelectedInventory() async {
    if (_prefsService == null || _inventories.isEmpty) {
      // Select first inventory if no preferences or inventories are empty
      if (_inventories.isNotEmpty) {
        _selectedInventory = _inventories.first;
      }
      return;
    }

    final savedInventoryId = _prefsService!.getSelectedInventoryId();
    
    if (savedInventoryId != null) {
      try {
        // Try to find the saved inventory
        final savedInventory = _inventories.firstWhere(
          (inv) => inv.id == savedInventoryId,
        );
        _selectedInventory = savedInventory;
        Logger.info('Restored selected inventory: ${savedInventory.name}');
      } catch (e) {
        // If saved inventory not found, select first available and clear preferences
        Logger.warning('Saved inventory not found, selecting first available');
        if (_inventories.isNotEmpty) {
          _selectedInventory = _inventories.first;
          await _prefsService!.setSelectedInventoryId(_inventories.first.id);
        }
      }
    } else {
      // No saved preference, select first inventory
      if (_inventories.isNotEmpty) {
        _selectedInventory = _inventories.first;
        await _prefsService!.setSelectedInventoryId(_inventories.first.id);
      }
    }
  }

  /// Clear selected inventory
  Future<void> clearSelection() async {
    _selectedInventory = null;
    if (_prefsService != null) {
      await _prefsService!.clearSelectedInventoryId();
    }
    notifyListeners();
  }

  /// Get the index of the selected inventory in the list
  int get selectedInventoryIndex {
    if (_selectedInventory == null || _inventories.isEmpty) return 0;
    return _inventories.indexWhere((inv) => inv.id == _selectedInventory!.id).clamp(0, _inventories.length - 1);
  }

  /// Update the inventories list and sync selected inventory
  void updateInventories(List<InventoryModel> inventories) {
    _inventories = inventories;
    
    // Sync selected inventory
    if (_selectedInventory != null && inventories.isNotEmpty) {
      try {
        // Try to find the selected inventory in the new list
        final updatedInventory = inventories.firstWhere(
          (inv) => inv.id == _selectedInventory!.id,
        );
        _selectedInventory = updatedInventory;
      } catch (e) {
        // Selected inventory not found, select first available
        _selectedInventory = inventories.first;
        if (_prefsService != null) {
          _prefsService!.setSelectedInventoryId(inventories.first.id);
        }
      }
    } else if (inventories.isNotEmpty && _selectedInventory == null) {
      // No selected inventory but inventories available, select first
      _selectedInventory = inventories.first;
      if (_prefsService != null) {
        _prefsService!.setSelectedInventoryId(inventories.first.id);
      }
    }
    
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}