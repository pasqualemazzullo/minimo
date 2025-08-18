import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/exceptions.dart' as exceptions;
import '../../../core/utils/logger.dart';
import '../../models/inventory_model.dart';
import '../../models/food_item_model.dart';
import '../../models/shopping_list_item_model.dart';
import '../../models/user_model.dart';

abstract class SupabaseDataSource {
  // Auth
  Future<UserModel> signUp({required String email, required String password, required String fullName});
  Future<UserModel> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> resetPassword(String email);
  UserModel? getCurrentUser();
  bool isAuthenticated();
  Stream<UserModel?> get authStateChanges;

  // Inventories
  Future<List<InventoryModel>> getUserInventories();
  Future<InventoryModel> createInventory(String name);
  Future<void> deleteInventory(String inventoryId);

  // Food Items
  Future<List<FoodItemModel>> getInventoryFoodItems(String inventoryId);
  Future<FoodItemModel> addFoodItem(FoodItemModel foodItem);
  Future<FoodItemModel> updateFoodItem(FoodItemModel foodItem);
  Future<void> deleteFoodItem(String foodItemId);

  // Shopping List
  Future<List<ShoppingListItemModel>> getShoppingListItems(String inventoryId);
  Future<ShoppingListItemModel> addShoppingListItem(ShoppingListItemModel item);
  Future<ShoppingListItemModel> updateShoppingListItem(ShoppingListItemModel item);
  Future<void> deleteShoppingListItem(String itemId);
  Future<void> restockAllItems(String inventoryId);
  Future<void> restockSelectedItems(String inventoryId, List<String> selectedItemIds);
}

class SupabaseDataSourceImpl implements SupabaseDataSource {
  final SupabaseClient _supabase;

  const SupabaseDataSourceImpl(this._supabase);

  @override
  Future<UserModel> signUp({required String email, required String password, required String fullName}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        emailRedirectTo: 'com.minimo.minimo://signup-callback/',
      );

      if (response.user == null) {
        throw const exceptions.AuthException('Registrazione fallita');
      }

      return UserModel.fromJson(response.user!.toJson());
    } on exceptions.AuthException {
      rethrow;
    } catch (e) {
      Logger.error('Errore registrazione', error: e);
      throw exceptions.AuthException('Errore durante la registrazione: $e');
    }
  }

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const exceptions.AuthException('Login fallito');
      }

      return UserModel.fromJson(response.user!.toJson());
    } on exceptions.AuthException {
      rethrow;
    } catch (e) {
      Logger.error('Errore login', error: e);
      throw exceptions.AuthException('Errore durante il login: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      Logger.error('Errore logout', error: e);
      throw exceptions.AuthException('Errore durante il logout: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.minimo.minimo://reset-password/',
      );
    } catch (e) {
      Logger.error('Errore reset password', error: e);
      throw exceptions.AuthException('Errore durante il reset password: $e');
    }
  }

  @override
  UserModel? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    return user != null ? UserModel.fromJson(user.toJson()) : null;
  }

  @override
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      return data.session?.user != null 
          ? UserModel.fromJson(data.session!.user.toJson())
          : null;
    });
  }

  @override
  Future<List<InventoryModel>> getUserInventories() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw const exceptions.AuthException('User not authenticated');

      final response = await _supabase
          .from('inventories')
          .select()
          .eq('user_id', userId)
          .order('created_at');

      return (response as List)
          .map((json) => InventoryModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Errore caricamento inventari', error: e);
      throw exceptions.ServerException('Errore nel caricamento degli inventari: $e');
    }
  }

  @override
  Future<InventoryModel> createInventory(String name) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw const exceptions.AuthException('User not authenticated');

      final inventory = InventoryModel(
        id: '',
        userId: userId,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _supabase
          .from('inventories')
          .insert(inventory.toInsert())
          .select()
          .single();

      return InventoryModel.fromJson(response);
    } catch (e) {
      Logger.error('Errore creazione inventario', error: e);
      throw exceptions.ServerException('Errore nella creazione dell\'inventario: $e');
    }
  }

  @override
  Future<void> deleteInventory(String inventoryId) async {
    try {
      await _supabase
          .from('inventories')
          .delete()
          .eq('id', inventoryId);
    } catch (e) {
      Logger.error('Errore eliminazione inventario', error: e);
      throw exceptions.ServerException('Errore nell\'eliminazione dell\'inventario: $e');
    }
  }

  // Simplified implementations for other methods...
  @override
  Future<List<FoodItemModel>> getInventoryFoodItems(String inventoryId) async {
    try {
      final response = await _supabase
          .from('food_items')
          .select()
          .eq('inventory_id', inventoryId)
          .order('created_at');

      return (response as List)
          .map((json) => FoodItemModel.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Errore caricamento alimenti', error: e);
      throw exceptions.ServerException('Errore nel caricamento degli alimenti: $e');
    }
  }

  // Other methods follow the same pattern...
  @override
  Future<FoodItemModel> addFoodItem(FoodItemModel foodItem) async {
    try {
      final response = await _supabase
          .from('food_items')
          .insert(foodItem.toInsert())
          .select()
          .single();

      return FoodItemModel.fromJson(response);
    } catch (e) {
      Logger.error('Errore aggiunta alimento', error: e);
      throw exceptions.ServerException('Errore nell\'aggiunta dell\'alimento: $e');
    }
  }

  @override
  Future<FoodItemModel> updateFoodItem(FoodItemModel foodItem) async {
    try {
      final response = await _supabase
          .from('food_items')
          .update(foodItem.toUpdate())
          .eq('id', foodItem.id)
          .select()
          .single();

      return FoodItemModel.fromJson(response);
    } catch (e) {
      Logger.error('Errore aggiornamento alimento', error: e);
      throw exceptions.ServerException('Errore nell\'aggiornamento dell\'alimento: $e');
    }
  }

  @override
  Future<void> deleteFoodItem(String foodItemId) async {
    try {
      await _supabase
          .from('food_items')
          .delete()
          .eq('id', foodItemId);
    } catch (e) {
      Logger.error('Errore eliminazione alimento', error: e);
      throw exceptions.ServerException('Errore nell\'eliminazione dell\'alimento: $e');
    }
  }

  @override
  Future<List<ShoppingListItemModel>> getShoppingListItems(String inventoryId) {
    // Implementation here
    throw UnimplementedError();
  }

  @override
  Future<ShoppingListItemModel> addShoppingListItem(ShoppingListItemModel item) {
    // Implementation here
    throw UnimplementedError();
  }

  @override
  Future<ShoppingListItemModel> updateShoppingListItem(ShoppingListItemModel item) {
    // Implementation here
    throw UnimplementedError();
  }

  @override
  Future<void> deleteShoppingListItem(String itemId) {
    // Implementation here
    throw UnimplementedError();
  }

  @override
  Future<void> restockAllItems(String inventoryId) {
    // Implementation here
    throw UnimplementedError();
  }

  @override
  Future<void> restockSelectedItems(String inventoryId, List<String> selectedItemIds) {
    // Implementation here
    throw UnimplementedError();
  }
}