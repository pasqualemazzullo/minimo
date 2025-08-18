import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

import '../../../data/models/inventory_model.dart';
import '../../../data/datasources/remote/database_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/inventory_dropdown.dart';
import '../../controllers/inventory_selection_controller.dart';
import '../../../core/constants/food_categories.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

enum AddToType { inventory, shoppingList }

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  String? _selectedCategory = FoodCategories.defaultCategory;
  InventoryModel? _selectedInventory;
  List<InventoryModel> inventories = [];
  bool isLoading = true;
  DateTime? _selectedExpiryDate;
  AddToType _selectedAddToType = AddToType.inventory;


  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      final inventoryController = InventorySelectionController();
      await inventoryController.initialize();
      
      setState(() {
        _selectedInventory = inventoryController.selectedInventory;
        inventories = inventoryController.inventories;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricamento degli inventari: $e', style: const TextStyle(color: AppTheme.white)),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aggiungi prodotto',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        elevation: 0,
        actions: [
          InventoryDropdown(
            onInventoryChanged: (inventory) {
              setState(() {
                _selectedInventory = inventory;
              });
            },
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : inventories.isEmpty
              ? Center(
                child: Text(
                  'Nessun inventario trovato.\nCreane uno nuovo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.grey, fontSize: 16),
                ),
              )
              : Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Selector per Inventario o Lista della Spesa
                      Container(
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedAddToType = AddToType.inventory;
                                  });
                                },
                                child: _buildAddToTypeFilter(
                                  'Inventario',
                                  AddToType.inventory,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedAddToType = AddToType.shoppingList;
                                  });
                                },
                                child: _buildAddToTypeFilter(
                                  'Lista della Spesa',
                                  AddToType.shoppingList,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        cursorColor: AppTheme.primaryColor,
                        decoration: InputDecoration(
                          labelText: 'Nome prodotto *',
                          labelStyle: TextStyle(
                            color: AppTheme.unselectedText,
                            fontSize: 14,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppTheme.grey50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppTheme.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppTheme.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppTheme.cardBorder,
                              width: 2,
                            ),
                          ),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Inserisci il nome'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        items:
                            FoodCategories.categories
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => _selectedCategory = val),
                        decoration: InputDecoration(
                          labelText: 'Categoria prodotto *',
                          labelStyle: TextStyle(
                            color: AppTheme.unselectedText,
                            fontSize: 14,
                          ),
                          floatingLabelStyle: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppTheme.grey50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppTheme.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppTheme.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppTheme.cardBorder,
                              width: 2,
                            ),
                          ),
                        ),
                        icon: Icon(UniconsLine.angle_down),
                        validator:
                            (value) =>
                                value == null
                                    ? 'Seleziona una categoria'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _quantityController,
                              cursorColor: AppTheme.primaryColor,
                              decoration: InputDecoration(
                                labelText: 'Quantità *',
                                labelStyle: TextStyle(
                                  color: AppTheme.unselectedText,
                                  fontSize: 14,
                                ),
                                floatingLabelStyle: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: AppTheme.grey50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppTheme.cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppTheme.cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppTheme.cardBorder,
                                    width: 2,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Inserisci la quantità'
                                          : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _unitController,
                              cursorColor: AppTheme.primaryColor,
                              decoration: InputDecoration(
                                labelText: 'Unità di misura *',
                                labelStyle: TextStyle(
                                  color: AppTheme.unselectedText,
                                  fontSize: 14,
                                ),
                                floatingLabelStyle: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: AppTheme.grey50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppTheme.cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: AppTheme.cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppTheme.cardBorder,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Inserisci l\'unità'
                                          : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Data di scadenza (solo per inventario)
                      if (_selectedAddToType == AddToType.inventory) ...[
                        GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  _selectedExpiryDate ??
                                  DateTime.now().add(Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                Duration(days: 365 * 10),
                              ), // 10 anni per prodotti a lunga conservazione
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppTheme.primaryColor,
                                      onPrimary: AppTheme.white,
                                      surface: AppTheme.white,
                                      onSurface: AppTheme.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedExpiryDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.grey50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  UniconsLine.calendar_alt,
                                  color: AppTheme.unselectedText,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedExpiryDate == null
                                        ? 'Data di scadenza (opzionale)'
                                        : 'Scadenza: ${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}',
                                    style: TextStyle(
                                      color:
                                          _selectedExpiryDate == null
                                              ? AppTheme.unselectedText
                                              : AppTheme.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (_selectedExpiryDate != null)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedExpiryDate = null;
                                      });
                                    },
                                    child: Icon(
                                      UniconsLine.times,
                                      color: AppTheme.unselectedText,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate() &&
                              _selectedInventory != null) {
                            try {
                              final quantity =
                                  '${_quantityController.text} ${_unitController.text}';

                              if (_selectedAddToType == AddToType.inventory) {
                                // Aggiungi all'inventario
                                await DatabaseService.addFoodItem(
                                  inventoryId: _selectedInventory!.id,
                                  name: _nameController.text,
                                  category: _selectedCategory!,
                                  quantity: quantity,
                                  expiryDate: _selectedExpiryDate,
                                  imageUrl: _getCategoryEmoji(
                                    _selectedCategory!,
                                  ),
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Prodotto aggiunto all\'inventario!',
                                        style: const TextStyle(color: AppTheme.white),
                                      ),
                                      backgroundColor: AppTheme.successColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } else {
                                // Aggiungi alla lista della spesa
                                await DatabaseService.addShoppingListItem(
                                  inventoryId: _selectedInventory!.id,
                                  name: _nameController.text,
                                  quantity: quantity,
                                  emoji: _getCategoryEmoji(_selectedCategory!),
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Prodotto aggiunto alla lista della spesa!',
                                        style: const TextStyle(color: AppTheme.white),
                                      ),
                                      backgroundColor: AppTheme.successColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }

                              _nameController.clear();
                              _quantityController.clear();
                              _unitController.clear();
                              setState(() {
                                _selectedCategory = null;
                                _selectedExpiryDate = null;
                              });
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Errore nell\'aggiunta del prodotto: $e',
                                      style: const TextStyle(color: AppTheme.white),
                                    ),
                                    backgroundColor: AppTheme.errorColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          } else if (_selectedInventory == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Seleziona un inventario', style: const TextStyle(color: AppTheme.white)),
                                  backgroundColor: AppTheme.errorColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                        ),
                        child: Text(
                          _selectedAddToType == AddToType.inventory
                              ? 'Aggiungi all\'Inventario'
                              : 'Aggiungi alla Lista della Spesa',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontFamily: AppConstants.fontFamily,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildAddToTypeFilter(String label, AddToType type) {
    final isSelected = _selectedAddToType == type;
    final Color selectedBg = AppTheme.chipSelectedBg;
    final Color selectedText = AppTheme.chipSelectedText;
    final Color selectedBorder = AppTheme.chipSelectedBorder;
    final Color unselectedBg = AppTheme.chipBg;
    final Color unselectedText = AppTheme.chipText;
    final Color unselectedBorder = AppTheme.unselectedBorder;
    final Color borderColor = isSelected ? selectedBorder : unselectedBorder;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      constraints: BoxConstraints(minHeight: 55),
      decoration: BoxDecoration(
        color: isSelected ? selectedBg : unselectedBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: isSelected ? selectedText : unselectedText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    return FoodCategories.getCategoryEmoji(category);
  }
}
