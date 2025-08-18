import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/inventory_model.dart';
import '../../models/food_item_model.dart';
import '../../models/shopping_list_item_model.dart';
import '../../models/inventory_invitation_model.dart';
import '../../models/inventory_share_model.dart';
import '../../models/inventory_share_with_email_model.dart';
import '../../models/shopping_list_item_with_creator_model.dart';
import '../../../core/errors/exceptions.dart' as exceptions;
import '../../../core/utils/logger.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/food_categories.dart';

class DatabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // === INVENTORIES ===
  
  static Future<List<InventoryModel>> getUserInventories() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const exceptions.AuthException('User not authenticated');
      }

      Logger.info('Getting inventories for user: $userId');

      // Use the function that gets all inventories (owned + shared) in one call
      final response = await _supabase.rpc('get_shared_inventories_for_user', 
        params: {'p_user_id': userId});

      Logger.info('Found ${(response as List).length} total inventories (owned + shared)');

      final allInventories = response
          .map<InventoryModel>((json) => InventoryModel(
            id: json['id'] as String,
            userId: json['user_id'] as String,
            name: json['name'] as String,
            createdAt: DateTime.parse(json['created_at'] as String),
            updatedAt: DateTime.parse(json['updated_at'] as String),
          ))
          .toList();

      Logger.info('Total inventories returned: ${allInventories.length}');
      return allInventories;
    } on exceptions.AuthException {
      rethrow;
    } catch (error) {
      Logger.error('Error fetching inventories', error: error);
      throw exceptions.ServerException('Failed to fetch inventories: $error');
    }
  }

  static Future<InventoryModel> createInventory(String name) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const exceptions.AuthException('User not authenticated');
      }

      if (name.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory name cannot be empty');
      }

      final inventory = InventoryModel(
        id: '',
        userId: userId,
        name: name.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _supabase
          .from('inventories')
          .insert(inventory.toInsert())
          .select()
          .single();

      Logger.info('Created inventory: ${inventory.name}');
      return InventoryModel.fromJson(response);
    } on exceptions.AuthException {
      rethrow;
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error creating inventory', error: error);
      throw exceptions.ServerException('Failed to create inventory: $error');
    }
  }

  static Future<InventoryModel> updateInventory(InventoryModel inventory) async {
    try {
      if (inventory.id.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }
      if (inventory.name.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory name cannot be empty');
      }

      final response = await _supabase
          .from('inventories')
          .update({
            'name': inventory.name.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', inventory.id)
          .select()
          .single();

      Logger.info('Updated inventory: ${inventory.name}');
      return InventoryModel.fromJson(response);
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error updating inventory', error: error);
      throw exceptions.ServerException('Failed to update inventory: $error');
    }
  }

  static Future<void> deleteInventory(String inventoryId) async {
    try {
      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }

      await _supabase
          .from('inventories')
          .delete()
          .eq('id', inventoryId);

      Logger.info('Deleted inventory: $inventoryId');
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error deleting inventory', error: error);
      throw exceptions.ServerException('Failed to delete inventory: $error');
    }
  }

  // === FOOD ITEMS ===

  static Future<List<FoodItemModel>> getInventoryFoodItems(String inventoryId) async {
    try {
      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }

      final response = await _supabase
          .from('food_items')
          .select()
          .eq('inventory_id', inventoryId)
          .order('created_at');

      return (response as List)
          .map((json) => FoodItemModel.fromJson(json))
          .toList();
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error fetching food items', error: error);
      throw exceptions.ServerException('Failed to fetch food items: $error');
    }
  }

  static Future<FoodItemModel> addFoodItem({
    required String inventoryId,
    required String name,
    required String category,
    required String quantity,
    DateTime? expiryDate,
    String imageUrl = AppConstants.defaultEmoji,
    bool isOutOfStock = false,
  }) async {
    try {
      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }
      if (name.trim().isEmpty) {
        throw const exceptions.ValidationException('Food item name cannot be empty');
      }
      if (quantity.trim().isEmpty) {
        throw const exceptions.ValidationException('Quantity cannot be empty');
      }

      final foodItem = FoodItemModel(
        id: '',
        inventoryId: inventoryId,
        name: name.trim(),
        category: FoodCategories.getValidCategoryOrDefault(category),
        quantity: quantity.trim(),
        expiryDate: expiryDate,
        imageUrl: imageUrl.isEmpty ? AppConstants.defaultEmoji : imageUrl,
        isOutOfStock: isOutOfStock,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _supabase
          .from('food_items')
          .insert(foodItem.toInsert())
          .select()
          .single();

      Logger.info('Added food item: ${foodItem.name}');
      return FoodItemModel.fromJson(response);
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error adding food item', error: error);
      throw exceptions.ServerException('Failed to add food item: $error');
    }
  }

  static Future<FoodItemModel> updateFoodItem(FoodItemModel foodItem) async {
    try {
      if (foodItem.id.trim().isEmpty) {
        throw const exceptions.ValidationException('Food item ID cannot be empty');
      }
      if (foodItem.name.trim().isEmpty) {
        throw const exceptions.ValidationException('Food item name cannot be empty');
      }

      final response = await _supabase
          .from('food_items')
          .update({
            'name': foodItem.name.trim(),
            'category': foodItem.category.trim(),
            'quantity': foodItem.quantity.trim(),
            'expiry_date': foodItem.expiryDate?.toIso8601String(),
            'image_url': foodItem.imageUrl,
            'is_out_of_stock': foodItem.isOutOfStock,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', foodItem.id)
          .select()
          .single();

      Logger.info('Updated food item: ${foodItem.name}');
      return FoodItemModel.fromJson(response);
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error updating food item', error: error);
      throw exceptions.ServerException('Failed to update food item: $error');
    }
  }

  static Future<void> deleteFoodItem(String foodItemId) async {
    try {
      if (foodItemId.trim().isEmpty) {
        throw const exceptions.ValidationException('Food item ID cannot be empty');
      }

      await _supabase
          .from('food_items')
          .delete()
          .eq('id', foodItemId);

      Logger.info('Deleted food item: $foodItemId');
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error deleting food item', error: error);
      throw exceptions.ServerException('Failed to delete food item: $error');
    }
  }

  // === SHOPPING LIST ITEMS ===

  static Future<List<ShoppingListItemModel>> getShoppingListItems(String inventoryId) async {
    try {
      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }

      final response = await _supabase
          .from('shopping_list_items')
          .select()
          .eq('inventory_id', inventoryId)
          .order('created_at');

      return (response as List)
          .map((json) => ShoppingListItemModel.fromJson(json))
          .toList();
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error fetching shopping list items', error: error);
      throw exceptions.ServerException('Failed to fetch shopping list items: $error');
    }
  }

  /// Get shopping list items with creator information for shared inventories
  static Future<List<ShoppingListItemWithCreatorModel>> getShoppingListItemsWithCreator(String inventoryId) async {
    try {
      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }

      final response = await _supabase.rpc('get_shopping_items_with_creator',
        params: {'p_inventory_id': inventoryId});

      return (response as List)
          .map((json) => ShoppingListItemWithCreatorModel.fromJson(json))
          .toList();
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error fetching shopping list items with creator', error: error);
      throw exceptions.ServerException('Failed to fetch shopping list items with creator: $error');
    }
  }

  static Future<ShoppingListItemModel> addShoppingListItem({
    required String inventoryId,
    required String name,
    required String quantity,
    String emoji = AppConstants.defaultEmoji,
    bool isChecked = false,
  }) async {
    try {
      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }
      if (name.trim().isEmpty) {
        throw const exceptions.ValidationException('Shopping list item name cannot be empty');
      }
      if (quantity.trim().isEmpty) {
        throw const exceptions.ValidationException('Quantity cannot be empty');
      }

      final item = ShoppingListItemModel(
        id: '',
        inventoryId: inventoryId,
        name: name.trim(),
        quantity: quantity.trim(),
        emoji: emoji.isEmpty ? AppConstants.defaultEmoji : emoji,
        isChecked: isChecked,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final itemData = item.toInsert();
      // Add created_by field
      itemData['created_by'] = _supabase.auth.currentUser?.id;

      final response = await _supabase
          .from('shopping_list_items')
          .insert(itemData)
          .select()
          .single();

      Logger.info('Added shopping list item: ${item.name}');
      return ShoppingListItemModel.fromJson(response);
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error adding shopping list item', error: error);
      throw exceptions.ServerException('Failed to add shopping list item: $error');
    }
  }

  static Future<ShoppingListItemModel> updateShoppingListItem(ShoppingListItemModel item) async {
    try {
      if (item.id.trim().isEmpty) {
        throw const exceptions.ValidationException('Shopping list item ID cannot be empty');
      }
      if (item.name.trim().isEmpty) {
        throw const exceptions.ValidationException('Shopping list item name cannot be empty');
      }

      final response = await _supabase
          .from('shopping_list_items')
          .update({
            'name': item.name.trim(),
            'quantity': item.quantity.trim(),
            'emoji': item.emoji,
            'is_checked': item.isChecked,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', item.id)
          .select()
          .single();

      Logger.info('Updated shopping list item: ${item.name}');
      return ShoppingListItemModel.fromJson(response);
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error updating shopping list item', error: error);
      throw exceptions.ServerException('Failed to update shopping list item: $error');
    }
  }

  static Future<void> deleteShoppingListItem(String itemId) async {
    try {
      if (itemId.trim().isEmpty) {
        throw const exceptions.ValidationException('Shopping list item ID cannot be empty');
      }

      await _supabase
          .from('shopping_list_items')
          .delete()
          .eq('id', itemId);

      Logger.info('Deleted shopping list item: $itemId');
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error deleting shopping list item', error: error);
      throw exceptions.ServerException('Failed to delete shopping list item: $error');
    }
  }

  // === UTILITY METHODS ===

  static Future<void> addOutOfStockItemToShoppingList(FoodItemModel foodItem) async {
    try {
      await addShoppingListItem(
        inventoryId: foodItem.inventoryId,
        name: foodItem.name,
        quantity: foodItem.quantity,
        emoji: foodItem.imageUrl,
      );
      Logger.info('Added out of stock item to shopping list: ${foodItem.name}');
    } catch (error) {
      Logger.error('Error adding out of stock item to shopping list', error: error);
      rethrow;
    }
  }

  static Future<void> markAllShoppingListItemsAsCompleted(String inventoryId) async {
    try {
      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }

      final result = await _supabase
          .from('shopping_list_items')
          .update({
            'is_checked': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('inventory_id', inventoryId)
          .select();

      Logger.info('Marked ${(result as List).length} shopping list items as completed');
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error marking all shopping list items as completed', error: error);
      throw exceptions.ServerException('Failed to mark items as completed: $error');
    }
  }

  static Future<void> restockAllShoppingListItems(String inventoryId) async {
    try {
      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }

      // Get all shopping list items for this inventory
      final shoppingListItems = await getShoppingListItems(inventoryId);
      
      if (shoppingListItems.isEmpty) {
        Logger.info('No shopping list items to restock for inventory: $inventoryId');
        return;
      }

      // For each shopping list item, add it to the food items inventory
      int restockedCount = 0;
      for (final item in shoppingListItems) {
        try {
          await addFoodItem(
            inventoryId: inventoryId,
            name: item.name,
            category: FoodCategories.defaultCategory,
            quantity: item.quantity,
            imageUrl: item.emoji,
            isOutOfStock: false,
          );
          restockedCount++;
        } catch (e) {
          Logger.warning('Failed to restock item ${item.name}', error: e);
          // Continue with next item instead of failing entire operation
        }
      }
      
      // Delete all shopping list items after moving them to inventory
      if (restockedCount > 0) {
        await _supabase
            .from('shopping_list_items')
            .delete()
            .eq('inventory_id', inventoryId);
        
        Logger.info('Restocked $restockedCount items and cleared shopping list');
      }
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error restocking shopping list items', error: error);
      throw exceptions.ServerException('Failed to restock shopping list items: $error');
    }
  }

  static Future<void> restockSelectedShoppingListItems(String inventoryId, List<String> selectedItemIds) async {
    try {
      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }
      if (selectedItemIds.isEmpty) {
        throw const exceptions.ValidationException('No items selected for restocking');
      }

      // Get all shopping list items for this inventory
      final allShoppingListItems = await getShoppingListItems(inventoryId);
      
      // Filter only the selected items
      final selectedItems = allShoppingListItems
          .where((item) => selectedItemIds.contains(item.id))
          .toList();
      
      if (selectedItems.isEmpty) {
        Logger.warning('No valid selected items found for restocking');
        return;
      }

      // For each selected shopping list item, add it to the food items inventory
      int restockedCount = 0;
      final failedItems = <String>[];
      
      for (final item in selectedItems) {
        try {
          await addFoodItem(
            inventoryId: inventoryId,
            name: item.name,
            category: FoodCategories.defaultCategory,
            quantity: item.quantity,
            imageUrl: item.emoji,
            isOutOfStock: false,
          );
          restockedCount++;
        } catch (e) {
          Logger.warning('Failed to restock item ${item.name}', error: e);
          failedItems.add(item.name);
        }
      }
      
      // Delete only the successfully restocked shopping list items
      final successfulItemIds = selectedItems
          .where((item) => !failedItems.contains(item.name))
          .map((item) => item.id)
          .toList();
          
      for (final itemId in successfulItemIds) {
        try {
          await _supabase
              .from('shopping_list_items')
              .delete()
              .eq('id', itemId);
        } catch (e) {
          Logger.warning('Failed to delete shopping list item $itemId after restocking', error: e);
        }
      }
      
      Logger.info('Restocked $restockedCount out of ${selectedItems.length} selected items');
      
      if (failedItems.isNotEmpty) {
        Logger.warning('Failed to restock items: ${failedItems.join(', ')}');
      }
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error restocking selected shopping list items', error: error);
      throw exceptions.ServerException('Failed to restock selected items: $error');
    }
  }

  // === ADDITIONAL UTILITY METHODS ===

  /// Get food items that are expired
  static Future<List<FoodItemModel>> getExpiredFoodItems(String inventoryId) async {
    try {
      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }

      final allItems = await getInventoryFoodItems(inventoryId);
      final now = DateTime.now();
      
      return allItems.where((item) {
        return item.expiryDate != null && item.expiryDate!.isBefore(now);
      }).toList();
    } catch (error) {
      Logger.error('Error fetching expired food items', error: error);
      rethrow;
    }
  }

  /// Get food items that are expiring soon (within 3 days)
  static Future<List<FoodItemModel>> getExpiringSoonFoodItems(String inventoryId) async {
    try {
      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }

      final allItems = await getInventoryFoodItems(inventoryId);
      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));
      
      return allItems.where((item) {
        return item.expiryDate != null && 
               item.expiryDate!.isAfter(now) && 
               item.expiryDate!.isBefore(threeDaysFromNow);
      }).toList();
    } catch (error) {
      Logger.error('Error fetching expiring soon food items', error: error);
      rethrow;
    }
  }

  /// Get food items that are out of stock
  static Future<List<FoodItemModel>> getOutOfStockFoodItems(String inventoryId) async {
    try {
      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }

      final allItems = await getInventoryFoodItems(inventoryId);
      return allItems.where((item) => item.isOutOfStock).toList();
    } catch (error) {
      Logger.error('Error fetching out of stock food items', error: error);
      rethrow;
    }
  }

  // === INVENTORY INVITATIONS & SHARING ===

  /// Get pending invitations for the current user
  static Future<List<InventoryInvitationModel>> getPendingInvitations() async {
    try {
      final userEmail = _supabase.auth.currentUser?.email;
      final userId = _supabase.auth.currentUser?.id;
      
      if (userEmail == null || userId == null) {
        throw const exceptions.AuthException('User not authenticated');
      }

      // Get invitations for the current user (without join to avoid RLS issues)
      final response = await _supabase
          .from('inventory_invitations')
          .select('*')
          .or('invited_email.eq.$userEmail,invited_user_id.eq.$userId')
          .eq('status', 'pending')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      final invitations = <InventoryInvitationModel>[];
      
      for (final json in response as List) {
        // Get inventory name separately using our function
        String? inventoryName;
        try {
          final nameResponse = await _supabase.rpc('get_inventory_name_for_invitation', 
            params: {'inventory_id': json['inventory_id']});
          inventoryName = nameResponse as String?;
        } catch (e) {
          Logger.warning('Could not fetch inventory name: $e');
        }
        
        // Get inviter email separately using a simple query
        String? inviterEmail;
        try {
          final inviterResponse = await _supabase.rpc('get_user_email_by_id', 
            params: {'user_id': json['invited_by']});
          inviterEmail = inviterResponse as String?;
        } catch (e) {
          // If we can't get the email, it's not critical
          Logger.warning('Could not fetch inviter email: $e');
        }
        
        invitations.add(InventoryInvitationModel(
          id: json['id'] as String,
          inventoryId: json['inventory_id'] as String,
          invitedBy: json['invited_by'] as String,
          invitedEmail: json['invited_email'] as String,
          invitedUserId: json['invited_user_id'] as String?,
          role: json['role'] as String,
          status: json['status'] as String,
          expiresAt: DateTime.parse(json['expires_at'] as String),
          createdAt: DateTime.parse(json['created_at'] as String),
          updatedAt: DateTime.parse(json['updated_at'] as String),
          inventoryName: inventoryName,
          inviterEmail: inviterEmail,
        ));
      }
      
      return invitations;
    } on exceptions.AuthException {
      rethrow;
    } catch (error) {
      Logger.error('Error fetching pending invitations', error: error);
      throw exceptions.ServerException('Failed to fetch invitations: $error');
    }
  }

  /// Get count of pending invitations for the current user
  static Future<int> getPendingInvitationsCount() async {
    try {
      final invitations = await getPendingInvitations();
      return invitations.length;
    } catch (error) {
      Logger.error('Error fetching pending invitations count', error: error);
      return 0;
    }
  }

  /// Invite a user to an inventory
  static Future<Map<String, dynamic>> inviteUserToInventory({
    required String inventoryId,
    required String invitedEmail,
    String role = 'member',
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const exceptions.AuthException('User not authenticated');
      }

      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }
      if (invitedEmail.trim().isEmpty) {
        throw const exceptions.ValidationException('Email cannot be empty');
      }

      final response = await _supabase.rpc(
        'invite_user_to_inventory',
        params: {
          'p_inventory_id': inventoryId,
          'p_invited_email': invitedEmail.trim(),
          'p_role': role,
        },
      );

      final result = response as Map<String, dynamic>;
      
      if (result['success'] == true) {
        Logger.info('Invited user $invitedEmail to inventory $inventoryId');
      } else {
        Logger.warning('Failed to invite user: ${result['error']} - ${result['message']}');
      }
      
      return result;
    } on exceptions.AuthException {
      rethrow;
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error inviting user to inventory', error: error);
      throw exceptions.ServerException('Failed to invite user: $error');
    }
  }

  /// Accept an inventory invitation
  static Future<bool> acceptInvitation(String invitationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const exceptions.AuthException('User not authenticated');
      }

      if (invitationId.trim().isEmpty) {
        throw const exceptions.ValidationException('Invitation ID cannot be empty');
      }

      await _supabase.rpc(
        'accept_inventory_invitation',
        params: {'p_invitation_id': invitationId},
      );

      Logger.info('Accepted invitation: $invitationId');
      return true;
    } on exceptions.AuthException {
      rethrow;
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error accepting invitation', error: error);
      throw exceptions.ServerException('Failed to accept invitation: $error');
    }
  }

  /// Reject an inventory invitation
  static Future<bool> rejectInvitation(String invitationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const exceptions.AuthException('User not authenticated');
      }

      if (invitationId.trim().isEmpty) {
        throw const exceptions.ValidationException('Invitation ID cannot be empty');
      }

      await _supabase.rpc(
        'reject_inventory_invitation',
        params: {'p_invitation_id': invitationId},
      );

      Logger.info('Rejected invitation: $invitationId');
      return true;
    } on exceptions.AuthException {
      rethrow;
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error rejecting invitation', error: error);
      throw exceptions.ServerException('Failed to reject invitation: $error');
    }
  }

  /// Get shared users for an inventory with email information
  static Future<List<InventoryShareWithEmailModel>> getInventorySharesWithEmails(String inventoryId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const exceptions.AuthException('User not authenticated');
      }

      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }

      final response = await _supabase.rpc('get_inventory_shares_with_emails',
        params: {'p_inventory_id': inventoryId});

      return (response as List)
          .map((json) => InventoryShareWithEmailModel.fromJson(json))
          .toList();
    } on exceptions.AuthException {
      rethrow;
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error fetching inventory shares with emails', error: error);
      throw exceptions.ServerException('Failed to fetch inventory shares with emails: $error');
    }
  }

  /// Get shared users for an inventory
  static Future<List<InventoryShareModel>> getInventoryShares(String inventoryId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const exceptions.AuthException('User not authenticated');
      }

      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }

      final response = await _supabase
          .from('inventory_shares')
          .select('*')
          .eq('inventory_id', inventoryId)
          .order('created_at');

      return (response as List)
          .map((json) => InventoryShareModel.fromJson(json))
          .toList();
    } on exceptions.AuthException {
      rethrow;
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error fetching inventory shares', error: error);
      throw exceptions.ServerException('Failed to fetch inventory shares: $error');
    }
  }

  /// Remove a user from an inventory
  static Future<bool> removeUserFromInventory({
    required String inventoryId,
    required String userId,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw const exceptions.AuthException('User not authenticated');
      }

      if (inventoryId.trim().isEmpty) {
        throw const exceptions.ValidationException('Inventory ID cannot be empty');
      }
      if (userId.trim().isEmpty) {
        throw const exceptions.ValidationException('User ID cannot be empty');
      }

      await _supabase.rpc(
        'remove_user_from_inventory',
        params: {
          'p_inventory_id': inventoryId,
          'p_user_id': userId,
        },
      );

      Logger.info('Removed user $userId from inventory $inventoryId');
      return true;
    } on exceptions.AuthException {
      rethrow;
    } on exceptions.ValidationException {
      rethrow;
    } catch (error) {
      Logger.error('Error removing user from inventory', error: error);
      throw exceptions.ServerException('Failed to remove user: $error');
    }
  }

  /// Check if an inventory is shared (has more than one user)
  static Future<bool> isInventoryShared(String inventoryId) async {
    try {
      final response = await _supabase
          .from('inventory_shares')
          .select('id')
          .eq('inventory_id', inventoryId);

      // If more than 1 share (including owner), it's shared
      return (response as List).length > 1;
    } catch (error) {
      Logger.error('Error checking if inventory is shared', error: error);
      return false; // Default to false if error
    }
  }

  // === LEAVE INVENTORY ===

  static Future<void> leaveInventory(String inventoryId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const exceptions.AuthException('User not authenticated');
      }

      Logger.info('User $userId leaving inventory $inventoryId');

      await _supabase
          .from('inventory_shares')
          .delete()
          .eq('inventory_id', inventoryId)
          .eq('user_id', userId);

      Logger.info('User successfully left inventory');
    } on exceptions.AuthException {
      rethrow;
    } catch (error) {
      Logger.error('Error leaving inventory', error: error);
      throw exceptions.ServerException('Failed to leave inventory: $error');
    }
  }

  // === TRANSFER OWNERSHIP AND LEAVE ===

  static Future<void> transferOwnershipAndLeave(String inventoryId, String newOwnerId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const exceptions.AuthException('User not authenticated');
      }

      Logger.info('Transferring ownership of inventory $inventoryId from $userId to $newOwnerId');

      // First, update the inventory owner
      await _supabase
          .from('inventories')
          .update({'user_id': newOwnerId, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', inventoryId)
          .eq('user_id', userId); // Ensure only owner can do this

      // Update the new owner's role in inventory_shares
      await _supabase
          .from('inventory_shares')
          .update({'role': 'owner'})
          .eq('inventory_id', inventoryId)
          .eq('user_id', newOwnerId);

      // Remove the current user from inventory_shares
      await _supabase
          .from('inventory_shares')
          .delete()
          .eq('inventory_id', inventoryId)
          .eq('user_id', userId);

      Logger.info('Ownership transferred and user left inventory successfully');
    } on exceptions.AuthException {
      rethrow;
    } catch (error) {
      Logger.error('Error transferring ownership and leaving inventory', error: error);
      throw exceptions.ServerException('Failed to transfer ownership and leave inventory: $error');
    }
  }

  // === REMOVE MEMBER FROM INVENTORY ===

  static Future<void> removeMemberFromInventory(String inventoryId, String memberUserId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw const exceptions.AuthException('User not authenticated');
      }

      Logger.info('Owner $userId removing member $memberUserId from inventory $inventoryId');

      // Check if current user is owner of the inventory
      final inventoryResponse = await _supabase
          .from('inventories')
          .select('user_id')
          .eq('id', inventoryId)
          .eq('user_id', userId)
          .single();

      if (inventoryResponse.isEmpty) {
        throw const exceptions.AuthorizationException('Only inventory owners can remove members');
      }

      // Remove the member from inventory_shares
      await _supabase
          .from('inventory_shares')
          .delete()
          .eq('inventory_id', inventoryId)
          .eq('user_id', memberUserId);

      Logger.info('Member successfully removed from inventory');
    } on exceptions.AuthException {
      rethrow;
    } on exceptions.AuthorizationException {
      rethrow;
    } catch (error) {
      Logger.error('Error removing member from inventory', error: error);
      throw exceptions.ServerException('Failed to remove member from inventory: $error');
    }
  }
}