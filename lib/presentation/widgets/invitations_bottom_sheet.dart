import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import '../../data/models/inventory_invitation_model.dart';
import '../../shared/theme/app_theme.dart';
import '../controllers/invitations_controller.dart';
import '../controllers/food_controller.dart';

class InvitationsBottomSheet extends StatelessWidget {
  const InvitationsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Inviti',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Flexible(
            child: Consumer<InvitationsController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                  );
                }

                if (controller.error != null) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorColor,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.error!,
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            controller.clearError();
                            controller.refresh();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.white,
                          ),
                          child: const Text('Riprova'),
                        ),
                      ],
                    ),
                  );
                }

                if (controller.pendingInvitations.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          UniconsLine.bell_slash,
                          color: AppTheme.grey,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nessun invito',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Non hai inviti in sospeso',
                          style: TextStyle(
                            color: AppTheme.grey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: controller.pendingInvitations.length,
                  itemBuilder: (context, index) {
                    final invitation = controller.pendingInvitations[index];
                    return _InvitationCard(invitation: invitation);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final InventoryInvitationModel invitation;

  const _InvitationCard({required this.invitation});

  @override
  Widget build(BuildContext context) {
    final isExpired = invitation.isExpired;
    final daysLeft = invitation.expiresAt.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with inventory name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.chipBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor),
                  ),
                  child: Text(
                    invitation.inventoryName ?? 'Inventario',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.alertRedBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.alertRedBorder),
                    ),
                    child: const Text(
                      'Scaduto',
                      style: TextStyle(
                        color: AppTheme.alertRedText,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    'Scade in $daysLeft giorni',
                    style: const TextStyle(
                      color: AppTheme.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Invitation details
            Row(
              children: [
                const Icon(
                  Icons.favorite,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Unisciti all\'inventario',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${invitation.inviterEmail ?? 'Qualcuno'} ti ha invitato a far parte del ${invitation.inventoryName != null ? 'suo' : ''} inventario${invitation.inventoryName != null ? ' "${invitation.inventoryName}"' : ''}',
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ruolo: ${_getRoleText(invitation.role)}',
              style: const TextStyle(
                color: AppTheme.grey,
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            if (!isExpired && invitation.isActive) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectInvitation(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Rifiuta'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptInvitation(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Accetta'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.grey200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Invito non più valido',
                  style: TextStyle(
                    color: AppTheme.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Amministratore';
      case 'member':
        return 'Membro';
      default:
        return role;
    }
  }

  void _acceptInvitation(BuildContext context) async {
    final controller = context.read<InvitationsController>();
    final foodController = context.read<FoodController>();
    
    final success = await controller.acceptInvitation(invitation.id);
    
    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Invito accettato! L\'inventario è ora disponibile.',
              style: TextStyle(color: AppTheme.white),
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        // Close the bottom sheet if no more invitations
        if (controller.pendingInvitations.isEmpty) {
          Navigator.of(context).pop();
        }
        
        // Force refresh the inventories list to include the new shared inventory
        // Add a small delay to ensure the database transaction is complete
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            foodController.loadAllData();
          }
        });
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.error ?? 'Errore nell\'accettazione dell\'invito',
            style: const TextStyle(color: AppTheme.white),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _rejectInvitation(BuildContext context) async {
    final controller = context.read<InvitationsController>();
    
    final success = await controller.rejectInvitation(invitation.id);
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Invito rifiutato',
            style: TextStyle(color: AppTheme.white),
          ),
          backgroundColor: AppTheme.grey,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      // Close the bottom sheet if no more invitations
      if (controller.pendingInvitations.isEmpty) {
        Navigator.of(context).pop();
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.error ?? 'Errore nel rifiuto dell\'invito',
            style: const TextStyle(color: AppTheme.white),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}