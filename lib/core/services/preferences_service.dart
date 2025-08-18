import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static PreferencesService? _instance;
  static SharedPreferences? _prefs;

  PreferencesService._();

  static Future<PreferencesService> getInstance() async {
    _instance ??= PreferencesService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Keys for preferences
  static const String _selectedInventoryIdKey = 'selected_inventory_id';

  /// Get the selected inventory ID
  String? getSelectedInventoryId() {
    return _prefs?.getString(_selectedInventoryIdKey);
  }

  /// Set the selected inventory ID
  Future<bool> setSelectedInventoryId(String inventoryId) async {
    return await _prefs?.setString(_selectedInventoryIdKey, inventoryId) ?? false;
  }

  /// Clear the selected inventory ID
  Future<bool> clearSelectedInventoryId() async {
    return await _prefs?.remove(_selectedInventoryIdKey) ?? false;
  }
}