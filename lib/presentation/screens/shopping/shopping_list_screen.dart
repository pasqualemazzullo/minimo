import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/inventory_model.dart';
import '../../../data/models/shopping_list_item_model.dart';
import '../../../data/models/shopping_list_item_with_creator_model.dart';
import '../../../data/datasources/remote/database_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/inventory_dropdown.dart';
import '../../controllers/inventory_selection_controller.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _formKey = GlobalKey<FormState>();
  InventoryModel? _selectedInventory;
  List<ShoppingListItemModel> shoppingListItems = [];
  bool isLoading = true;
  bool _isInventoryShared = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      final inventoryController = context.read<InventorySelectionController>();

      // Initialize if not already done
      if (inventoryController.selectedInventory == null) {
        await inventoryController.initialize();
      }

      // Load shopping list items for selected inventory
      if (inventoryController.selectedInventory != null) {
        await _loadShoppingListItems(inventoryController.selectedInventory!.id);
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore nel caricamento dei dati: $e',
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
    } finally {
      if (context.mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadShoppingListItems(String inventoryId) async {
    // Check if inventory is shared
    final isShared = await DatabaseService.isInventoryShared(inventoryId);

    List<ShoppingListItemModel> loadedItems;
    if (isShared) {
      // Load items with creator information
      final itemsWithCreator =
          await DatabaseService.getShoppingListItemsWithCreator(inventoryId);
      loadedItems = itemsWithCreator.cast<ShoppingListItemModel>();
    } else {
      // Load regular items
      loadedItems = await DatabaseService.getShoppingListItems(inventoryId);
    }

    if (mounted) {
      setState(() {
        shoppingListItems = loadedItems;
        _isInventoryShared = isShared;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista della Spesa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        elevation: 0,
        actions: [InventoryDropdown()],
      ),
      body: Consumer<InventorySelectionController>(
        builder: (context, inventoryController, child) {
          final selectedInventory = inventoryController.selectedInventory;

          // Update shopping list items when inventory changes
          if (selectedInventory != null &&
              (selectedInventory != _selectedInventory ||
                  shoppingListItems.isEmpty)) {
            _selectedInventory = selectedInventory;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadShoppingListItems(selectedInventory.id);
            });
          }

          return isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
              : selectedInventory == null
              ? Center(
                child: Text(
                  'Nessun inventario trovato.\nCreane uno nuovo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.grey, fontSize: 16),
                ),
              )
              : Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Form(
                  key: _formKey,
                  child:
                      shoppingListItems.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/shopping_list_empty.png',
                                  width: 300,
                                  height: 300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Mmmmh di che cosa avrai voglia oggi?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.grey600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView(
                            children: [
                              // Card dinamiche in base all'inventario selezionato
                              ...shoppingListItems.asMap().entries.map((entry) {
                                final item = entry.value;
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Dismissible(
                                    key: ValueKey(item.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.alertRedBackground,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Icon(
                                            UniconsLine.trash,
                                            color: AppTheme.alertRedText,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Elimina alimento',
                                            style: TextStyle(
                                              color: AppTheme.alertRedText,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onDismissed: (direction) async {
                                      try {
                                        await DatabaseService.deleteShoppingListItem(
                                          item.id,
                                        );
                                        setState(() {
                                          shoppingListItems.removeAt(entry.key);
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${item.name} eliminato',
                                                style: const TextStyle(
                                                  color: AppTheme.white,
                                                ),
                                              ),
                                              backgroundColor:
                                                  AppTheme.successColor,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Errore nell\'eliminazione: $e',
                                                style: const TextStyle(
                                                  color: AppTheme.white,
                                                ),
                                              ),
                                              backgroundColor:
                                                  AppTheme.errorColor,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              duration: const Duration(
                                                seconds: 4,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Card(
                                      margin: EdgeInsets.zero,
                                      color: AppTheme.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color:
                                              item.isChecked
                                                  ? AppTheme.primaryColor
                                                  : AppTheme.cardBorder,
                                        ),
                                      ),
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          splashColor: AppTheme.transparent,
                                          highlightColor: AppTheme.transparent,
                                        ),
                                        child: ListTile(
                                          leading: Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: AppTheme.grey200,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                item.emoji,
                                                style: TextStyle(fontSize: 24),
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            item.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                item.quantity,
                                                style: TextStyle(
                                                  color: AppTheme.grey700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (_isInventoryShared &&
                                                  item
                                                      is ShoppingListItemWithCreatorModel) ...[
                                                const SizedBox(height: 2),
                                                Builder(
                                                  builder: (context) {
                                                    final currentUserId =
                                                        Supabase
                                                            .instance
                                                            .client
                                                            .auth
                                                            .currentUser
                                                            ?.id;
                                                    final creatorItem = item;
                                                    return Text(
                                                      'Aggiunto da ${creatorItem.getCreatorDisplayName(currentUserId)}',
                                                      style: const TextStyle(
                                                        color: AppTheme.grey,
                                                        fontSize: 10,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                          trailing: CustomCheckbox(
                                            value: item.isChecked,
                                            onChanged: (bool? value) async {
                                              try {
                                                final updatedItem = item
                                                    .copyWith(
                                                      isChecked: value ?? false,
                                                    );
                                                await DatabaseService.updateShoppingListItem(
                                                  updatedItem,
                                                );
                                                setState(() {
                                                  final index =
                                                      shoppingListItems
                                                          .indexWhere(
                                                            (i) =>
                                                                i.id == item.id,
                                                          );
                                                  if (index != -1) {
                                                    shoppingListItems[index] =
                                                        updatedItem;
                                                  }
                                                });
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Errore nell\'aggiornamento: $e',
                                                        style: const TextStyle(
                                                          color: AppTheme.white,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          AppTheme.errorColor,
                                                      behavior:
                                                          SnackBarBehavior
                                                              .floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 4,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                          onTap: () async {
                                            try {
                                              final updatedItem = item.copyWith(
                                                isChecked: !item.isChecked,
                                              );
                                              await DatabaseService.updateShoppingListItem(
                                                updatedItem,
                                              );
                                              setState(() {
                                                final index = shoppingListItems
                                                    .indexWhere(
                                                      (i) => i.id == item.id,
                                                    );
                                                if (index != -1) {
                                                  shoppingListItems[index] =
                                                      updatedItem;
                                                }
                                              });
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Errore nell\'aggiornamento: $e',
                                                      style: const TextStyle(
                                                        color: AppTheme.white,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        AppTheme.errorColor,
                                                    behavior:
                                                        SnackBarBehavior
                                                            .floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 4,
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          splashColor: AppTheme.transparent,
                                          selectedTileColor:
                                              AppTheme.transparent,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  if (_selectedInventory != null) {
                                    try {
                                      final selectedItems =
                                          shoppingListItems
                                              .where((item) => item.isChecked)
                                              .toList();

                                      if (selectedItems.isNotEmpty) {
                                        // Restock only selected items
                                        final selectedItemIds =
                                            selectedItems
                                                .map((item) => item.id)
                                                .toList();
                                        await DatabaseService.restockSelectedShoppingListItems(
                                          _selectedInventory!.id,
                                          selectedItemIds,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${selectedItems.length} articoli selezionati sono stati aggiunti all\'inventario!',
                                                style: const TextStyle(
                                                  color: AppTheme.white,
                                                ),
                                              ),
                                              backgroundColor:
                                                  AppTheme.successColor,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        // Restock all items
                                        await DatabaseService.restockAllShoppingListItems(
                                          _selectedInventory!.id,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Tutti gli articoli sono stati aggiunti all\'inventario!',
                                                style: const TextStyle(
                                                  color: AppTheme.white,
                                                ),
                                              ),
                                              backgroundColor:
                                                  AppTheme.successColor,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        }
                                      }

                                      await _loadShoppingListItems(
                                        _selectedInventory!.id,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Errore: $e',
                                              style: const TextStyle(
                                                color: AppTheme.white,
                                              ),
                                            ),
                                            backgroundColor:
                                                AppTheme.errorColor,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            duration: const Duration(
                                              seconds: 4,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: AppTheme.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      99,
                                    ), // completamente tondo
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 24,
                                  ),
                                ),
                                child: Text(
                                  shoppingListItems.any(
                                        (item) => item.isChecked,
                                      )
                                      ? 'Rifornisci selezionati'
                                      : 'Rifornisci tutto',
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontFamily: AppConstants.fontFamily,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                ),
              );
        },
      ),
    );
  }
}

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: AppTheme.unselectedBorder,
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99),
          ),
          side: BorderSide(
            color: value ? AppTheme.primaryColor : AppTheme.unselectedBorder,
            width: 1.0,
          ),
          // Riduci la dimensione del check
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          splashRadius: 0,
        ),
      ),
      child: Transform.scale(
        scale: 1.2,
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          checkColor: AppTheme.white,
          activeColor: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
