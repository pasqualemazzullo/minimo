import 'package:flutter/material.dart';
import '../../data/models/inventory_invitation_model.dart';
import '../../data/models/inventory_share_model.dart';
import '../../data/datasources/remote/database_service.dart';
import '../../core/utils/logger.dart';

class InvitationsController extends ChangeNotifier {
  List<InventoryInvitationModel> _pendingInvitations = [];
  bool _isLoading = false;
  String? _error;
  int _pendingCount = 0;

  // Getters
  List<InventoryInvitationModel> get pendingInvitations => _pendingInvitations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingCount => _pendingCount;
  bool get hasNotifications => _pendingCount > 0;

  /// Initialize and load pending invitations
  Future<void> initialize() async {
    await loadPendingInvitations();
  }

  /// Load pending invitations for the current user
  Future<void> loadPendingInvitations() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _pendingInvitations = await DatabaseService.getPendingInvitations();
      _pendingCount = _pendingInvitations.length;
      
      Logger.info('Loaded ${_pendingInvitations.length} pending invitations');
    } catch (error) {
      _error = 'Errore nel caricamento degli inviti: $error';
      Logger.error('Error loading pending invitations', error: error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get count of pending invitations
  Future<void> loadPendingCount() async {
    try {
      _pendingCount = await DatabaseService.getPendingInvitationsCount();
      notifyListeners();
    } catch (error) {
      Logger.error('Error loading pending invitations count', error: error);
      _pendingCount = 0;
    }
  }

  /// Accept an invitation
  Future<bool> acceptInvitation(String invitationId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await DatabaseService.acceptInvitation(invitationId);
      
      if (success) {
        // Remove the accepted invitation from the list
        _pendingInvitations.removeWhere((inv) => inv.id == invitationId);
        _pendingCount = _pendingInvitations.length;
        Logger.info('Successfully accepted invitation: $invitationId');
      }

      return success;
    } catch (error) {
      _error = 'Errore nell\'accettazione dell\'invito: $error';
      Logger.error('Error accepting invitation', error: error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reject an invitation
  Future<bool> rejectInvitation(String invitationId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await DatabaseService.rejectInvitation(invitationId);
      
      if (success) {
        // Remove the rejected invitation from the list
        _pendingInvitations.removeWhere((inv) => inv.id == invitationId);
        _pendingCount = _pendingInvitations.length;
        Logger.info('Successfully rejected invitation: $invitationId');
      }

      return success;
    } catch (error) {
      _error = 'Errore nel rifiuto dell\'invito: $error';
      Logger.error('Error rejecting invitation', error: error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Invite a user to an inventory
  Future<Map<String, dynamic>> inviteUser({
    required String inventoryId,
    required String email,
    String role = 'member',
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await DatabaseService.inviteUserToInventory(
        inventoryId: inventoryId,
        invitedEmail: email,
        role: role,
      );

      if (result['success'] == false) {
        _error = result['message'] as String?;
      }

      return result;
    } catch (error) {
      _error = 'Errore nell\'invio dell\'invito: $error';
      Logger.error('Error inviting user', error: error);
      return {
        'success': false,
        'error': 'NETWORK_ERROR',
        'message': 'Errore di connessione. Riprova più tardi.',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get shares for an inventory
  Future<List<InventoryShareModel>> getInventoryShares(String inventoryId) async {
    try {
      return await DatabaseService.getInventoryShares(inventoryId);
    } catch (error) {
      Logger.error('Error getting inventory shares', error: error);
      return [];
    }
  }

  /// Remove a user from an inventory
  Future<bool> removeUserFromInventory({
    required String inventoryId,
    required String userId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await DatabaseService.removeUserFromInventory(
        inventoryId: inventoryId,
        userId: userId,
      );

      Logger.info('Successfully removed user from inventory');
      return success;
    } catch (error) {
      _error = 'Errore nella rimozione dell\'utente: $error';
      Logger.error('Error removing user from inventory', error: error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadPendingInvitations();
  }
}