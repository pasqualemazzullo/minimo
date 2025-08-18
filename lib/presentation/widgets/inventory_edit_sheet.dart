import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/inventory_model.dart';
import '../../data/models/inventory_share_with_email_model.dart';
import '../../data/datasources/remote/database_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../controllers/food_controller.dart';

class InventoryEditSheet extends StatefulWidget {
  final InventoryModel inventory;

  const InventoryEditSheet({super.key, required this.inventory});

  @override
  State<InventoryEditSheet> createState() => _InventoryEditSheetState();
}

class _InventoryEditSheetState extends State<InventoryEditSheet> {
  late TextEditingController _nameController;
  bool _isLoading = false;
  List<InventoryShareWithEmailModel> _members = [];
  bool _isLoadingMembers = true;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.inventory.name);
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;

    try {
      final members = await DatabaseService.getInventorySharesWithEmails(
        widget.inventory.id,
      );
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      if (!mounted) return;

      // Sort members: current user first, then others
      members.sort((a, b) {
        if (a.userId == currentUserId) return -1;
        if (b.userId == currentUserId) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });

      // Check if current user is owner
      final isOwner = members.any(
        (member) => member.userId == currentUserId && member.role == 'owner',
      );

      setState(() {
        _members = members;
        _isLoadingMembers = false;
        _isOwner = isOwner;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateInventory() async {
    if (!mounted) return;

    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Il nome dell\'inventario è obbligatorio');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedInventory = widget.inventory.copyWith(
        name: _nameController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await DatabaseService.updateInventory(updatedInventory);

      if (!mounted) return;

      // Salva il controller prima delle operazioni async
      final foodController = context.read<FoodController>();

      // Aggiorna il FoodController
      await foodController.loadAllData();

      if (!mounted) return;

      Navigator.pop(context);
      _showSuccessSnackBar('Inventario aggiornato con successo!');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Errore nell\'aggiornamento: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _leaveInventory() async {
    if (!mounted) return;

    // Se l'utente è il proprietario e ci sono altri membri, deve assegnare la proprietà
    if (_isOwner && _members.length > 1) {
      await _transferOwnershipAndLeave();
      return;
    }

    // Se l'utente è un membro normale, può abbandonare direttamente
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => SimpleDialog(
            title: const Text(
              'Abbandona inventario',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            backgroundColor: AppTheme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.cardBorder),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            children: [
              Text(
                'Sei sicuro di voler abbandonare l\'inventario "${widget.inventory.name}"? Non avrai più accesso a questo inventario.',
                style: const TextStyle(fontSize: 14, color: AppTheme.black),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      textStyle: const TextStyle(
                        fontFamily: AppConstants.fontFamily,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: AppTheme.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: AppConstants.fontFamily,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Abbandona'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Salva il controller prima delle operazioni async
        final foodController = context.read<FoodController>();

        await DatabaseService.leaveInventory(widget.inventory.id);

        if (!mounted) return;

        // Aggiorna il FoodController
        await foodController.loadAllData();

        if (!mounted) return;

        Navigator.pop(context);
        _showSuccessSnackBar('Hai abbandonato l\'inventario!');
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar('Errore: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _transferOwnershipAndLeave() async {
    if (!mounted) return;

    // Ottieni la lista dei membri che possono diventare proprietari (escluso l'utente corrente)
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final eligibleMembers =
        _members.where((member) => member.userId != currentUserId).toList();

    if (eligibleMembers.isEmpty) {
      _showErrorSnackBar(
        'Non è possibile abbandonare l\'inventario: non ci sono altri membri.',
      );
      return;
    }

    // Mostra dialog per selezionare il nuovo proprietario
    final String? newOwnerId = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => SimpleDialog(
            title: const Text(
              'Trasferisci proprietà',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            backgroundColor: AppTheme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.cardBorder),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            children: [
              const Text(
                'Seleziona chi diventerà il nuovo proprietario dell\'inventario:',
                style: TextStyle(fontSize: 14, color: AppTheme.black),
              ),
              const SizedBox(height: 20),
              ...eligibleMembers.map(
                (member) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, member.userId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            member.userEmail?.substring(0, 1).toUpperCase() ??
                                'U',
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.userEmail?.split('@')[0] ??
                                    'Utente sconosciuto',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                member.userEmail ?? '',
                                style: const TextStyle(
                                  color: AppTheme.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
    );

    if (newOwnerId != null && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Salva il controller prima delle operazioni async
        final foodController = context.read<FoodController>();

        await DatabaseService.transferOwnershipAndLeave(
          widget.inventory.id,
          newOwnerId,
        );

        if (!mounted) return;

        // Aggiorna il FoodController
        await foodController.loadAllData();

        if (!mounted) return;

        Navigator.pop(context);
        _showSuccessSnackBar('Proprietà trasferita e inventario abbandonato!');
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar('Errore: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _removeMember(String userId, String userEmail) async {
    if (!mounted) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => SimpleDialog(
            title: const Text(
              'Rimuovi membro',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            backgroundColor: AppTheme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.cardBorder),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            children: [
              Text(
                'Sei sicuro di voler rimuovere ${userEmail.split('@')[0]} dall\'inventario?',
                style: const TextStyle(fontSize: 14, color: AppTheme.black),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      textStyle: const TextStyle(
                        fontFamily: AppConstants.fontFamily,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: AppTheme.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: AppConstants.fontFamily,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Rimuovi'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        await DatabaseService.removeMemberFromInventory(
          widget.inventory.id,
          userId,
        );

        if (!mounted) return;

        // Ricarica i membri
        await _loadMembers();

        if (!mounted) return;

        _showSuccessSnackBar('Membro rimosso dall\'inventario!');
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar('Errore: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _deleteInventory() async {
    if (!mounted) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => SimpleDialog(
            title: const Text(
              'Elimina inventario',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            backgroundColor: AppTheme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.cardBorder),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            children: [
              Text(
                'Sei sicuro di voler eliminare l\'inventario "${widget.inventory.name}"? Tutti gli alimenti in questo inventario verranno eliminati. Questa azione non può essere annullata.',
                style: const TextStyle(fontSize: 14, color: AppTheme.black),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      textStyle: const TextStyle(
                        fontFamily: AppConstants.fontFamily,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: AppTheme.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: AppConstants.fontFamily,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Elimina'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
    );

    // Se l'utente ha confermato l'eliminazione
    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Salva il controller prima delle operazioni async
        final foodController = context.read<FoodController>();

        await DatabaseService.deleteInventory(widget.inventory.id);

        if (!mounted) return;

        // Aggiorna il FoodController
        await foodController.loadAllData();

        if (!mounted) return;

        Navigator.pop(context);
        _showSuccessSnackBar('Inventario eliminato con successo!');
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        _showErrorSnackBar('Errore nell\'eliminazione: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppTheme.white)),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppTheme.white)),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 50),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Modifica Inventario',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.chipBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor),
                  ),
                  child: Text(
                    '📦 Inventario',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome inventario *',
                labelStyle: const TextStyle(
                  color: AppTheme.unselectedText,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppTheme.grey50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.cardBorder,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Members section
            if (_members.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Membri',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_members.length}',
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _isLoadingMembers
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                  : Container(
                    decoration: BoxDecoration(
                      color: AppTheme.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _members.length,
                      separatorBuilder:
                          (context, index) => const Divider(
                            color: AppTheme.cardBorder,
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final currentUserId =
                            Supabase.instance.client.auth.currentUser?.id;
                        final isCurrentUser = member.userId == currentUserId;
                        final canRemove =
                            _isOwner &&
                            !isCurrentUser &&
                            member.role != 'owner';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              member.userEmail?.substring(0, 1).toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            () {
                              final name =
                                  member.userEmail?.split('@')[0] ??
                                  'Utente sconosciuto';
                              return isCurrentUser ? '$name (Tu)' : name;
                            }(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            member.userEmail ?? '',
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      member.role == 'owner'
                                          ? AppTheme.primaryColor
                                          : member.role == 'admin'
                                          ? AppTheme.warningColor
                                          : AppTheme.grey300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  member.role == 'owner'
                                      ? 'Proprietario'
                                      : member.role == 'admin'
                                      ? 'Admin'
                                      : 'Membro',
                                  style: TextStyle(
                                    color:
                                        member.role == 'owner'
                                            ? AppTheme.white
                                            : member.role == 'admin'
                                            ? AppTheme.white
                                            : AppTheme.grey700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (canRemove) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap:
                                      () => _removeMember(
                                        member.userId,
                                        member.userEmail ?? '',
                                      ),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      UniconsLine.times,
                                      color: AppTheme.errorColor,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            Column(
              children: [
                // Leave inventory button (only show if more than 1 member)
                if (_members.length > 1) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _leaveInventory,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warningColor,
                        side: const BorderSide(color: AppTheme.warningColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(
                        UniconsLine.sign_out_alt,
                        size: 18,
                        color: AppTheme.warningColor,
                      ),
                      label: const Text(
                        'Abbandona inventario',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    // Show delete button only for owners
                    if (_isOwner) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _deleteInventory,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: const BorderSide(color: AppTheme.errorColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(
                            UniconsLine.trash_alt,
                            size: 18,
                            color: AppTheme.errorColor,
                          ),
                          label: const Text(
                            'Elimina',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      flex: _isOwner ? 2 : 1,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _updateInventory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon:
                            _isLoading
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.white,
                                    ),
                                  ),
                                )
                                : const Icon(
                                  UniconsLine.check,
                                  size: 18,
                                  color: AppTheme.white,
                                ),
                        label: Text(
                          _isLoading ? 'Salvando...' : 'Salva modifiche',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
