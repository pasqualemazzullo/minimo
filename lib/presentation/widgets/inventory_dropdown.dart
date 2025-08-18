import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import '../../data/models/inventory_model.dart';
import '../../data/datasources/remote/database_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../controllers/food_controller.dart';
import '../controllers/inventory_selection_controller.dart';
import 'inventory_edit_sheet.dart';
import 'invite_user_bottom_sheet.dart';

class InventoryDropdown extends StatelessWidget {
  final Function(InventoryModel? inventory)? onInventoryChanged;

  const InventoryDropdown({super.key, this.onInventoryChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Consumer2<FoodController, InventorySelectionController>(
        builder: (context, foodController, inventoryController, child) {
          final currentInventories = foodController.inventories;
          final selectedInventory = inventoryController.selectedInventory;
          final selectedIndex = inventoryController.selectedInventoryIndex;
          final hasInventories =
              currentInventories.isNotEmpty && selectedInventory != null;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasInventories)
                IconButton(
                  icon: const Icon(
                    UniconsLine.user_plus,
                    color: AppTheme.black,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder:
                          (context) => InviteUserBottomSheet(
                            inventory: selectedInventory,
                          ),
                    );
                  },
                ),
              PopupMenuButton<int>(
                initialValue: selectedIndex,
                onSelected: (value) async {
                  if (value == currentInventories.length) {
                    // Crea nuovo inventario
                    final String? newName = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        String tempName = '';
                        return SimpleDialog(
                          title: Text('Che nome avrà il tuo inventario?'),
                          backgroundColor: AppTheme.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppTheme.cardBorder),
                          ),
                          contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
                          children: [
                            TextField(
                              autofocus: true,
                              cursorColor: AppTheme.primaryColor,
                              decoration: InputDecoration(
                                hintText: 'Esempio: 🏡 Casetta',
                                hintStyle: TextStyle(
                                  color: AppTheme.unselectedText,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: AppTheme.grey50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppTheme.cardBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppTheme.cardBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppTheme.cardBorder,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (val) => tempName = val,
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    textStyle: TextStyle(
                                      fontFamily: AppConstants.fontFamily,
                                      fontSize: 14,
                                    ),
                                  ),
                                  child: Text('Annulla'),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed:
                                      () => Navigator.pop(context, tempName),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: AppTheme.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    textStyle: TextStyle(
                                      fontFamily: AppConstants.fontFamily,
                                      fontSize: 14,
                                    ),
                                  ),
                                  child: Text('Aggiungi'),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                          ],
                        );
                      },
                    );

                    if (newName != null && newName.trim().isNotEmpty) {
                      try {
                        final newInventory =
                            await DatabaseService.createInventory(
                              newName.trim(),
                            );

                        // Aggiorna il FoodController
                        await foodController.loadAllData();

                        // Seleziona il nuovo inventario tramite il controller
                        await inventoryController.selectInventory(newInventory);

                        // Aggiorna la lista inventari nel controller
                        inventoryController.updateInventories(
                          foodController.inventories,
                        );

                        // Callback opzionale
                        if (onInventoryChanged != null) {
                          onInventoryChanged!(newInventory);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Errore nella creazione dell\'inventario: $e',
                                style: const TextStyle(color: AppTheme.white),
                              ),
                              backgroundColor: AppTheme.errorColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    }
                  } else {
                    // Seleziona inventario esistente
                    if (value < currentInventories.length) {
                      final newSelectedInventory = currentInventories[value];
                      await inventoryController.selectInventory(
                        newSelectedInventory,
                      );

                      // Callback opzionale
                      if (onInventoryChanged != null) {
                        onInventoryChanged!(newSelectedInventory);
                      }
                    }
                  }
                },
                itemBuilder:
                    (context) => [
                      ...List.generate(
                        currentInventories.length,
                        (index) => PopupMenuItem(
                          value: index,
                          child: Row(
                            children: [
                              Icon(
                                UniconsLine.receipt_alt,
                                color: AppTheme.primaryColor,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentInventories[index].name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context); // Chiudi il dropdown
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder:
                                        (context) => InventoryEditSheet(
                                          inventory: currentInventories[index],
                                        ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    UniconsLine.edit_alt,
                                    color: AppTheme.primaryColor,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: currentInventories.length,
                        child: Row(
                          children: [
                            Icon(
                              UniconsLine.plus,
                              color: AppTheme.primaryColor,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Aggiungi un nuovo inventario',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                color: AppTheme.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedInventory?.name ?? 'Nessun inventario',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(UniconsLine.angle_down, color: AppTheme.black),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
