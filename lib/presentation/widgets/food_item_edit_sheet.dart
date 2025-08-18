import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import '../../data/models/food_item_model.dart';
import '../../data/models/inventory_model.dart';
import '../../data/datasources/remote/database_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/food_categories.dart';
import '../controllers/food_controller.dart';

class FoodItemEditSheet extends StatefulWidget {
  final FoodItemModel item;
  final InventoryModel inventory;
  final bool isAddingToShoppingList;

  const FoodItemEditSheet({
    super.key,
    required this.item,
    required this.inventory,
    this.isAddingToShoppingList = false,
  });

  @override
  State<FoodItemEditSheet> createState() => _FoodItemEditSheetState();
}

class _FoodItemEditSheetState extends State<FoodItemEditSheet> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _emojiController;
  DateTime? _selectedDate;
  String _selectedCategory = FoodCategories.defaultCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(text: widget.item.quantity);
    _emojiController = TextEditingController(text: widget.item.imageUrl);
    _selectedDate = widget.item.expiryDate;

    // Imposta la categoria dell'alimento usando il metodo centralizzato
    _selectedCategory = FoodCategories.getValidCategoryOrDefault(
      widget.item.category,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
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
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _markAsOutOfStock() async {
    if (!mounted) return;

    setState(() {
      _quantityController.text = '0';
    });

    // Update the item with out of stock status
    await _updateItemWithStatus(FoodStatus.outOfStock);
  }

  Future<void> _updateItem() async {
    if (!mounted) return;

    if (widget.isAddingToShoppingList) {
      await _addToShoppingList();
    } else {
      // Check if quantity is 0, automatically set as out of stock
      FoodStatus newStatus;
      if (_quantityController.text.trim() == '0') {
        newStatus = FoodStatus.outOfStock;
      } else if (widget.item.isOutOfStock &&
          _quantityController.text.trim() != '0') {
        // If item was out of stock but now has quantity, mark as fresh (status will be recalculated based on expiry date)
        newStatus = FoodStatus.fresh;
      } else {
        // Keep current status if no quantity change affecting out-of-stock status
        newStatus = widget.item.status;
      }

      await _updateItemWithStatus(newStatus);
    }
  }

  Future<void> _addToShoppingList() async {
    if (!mounted) return;

    if (_nameController.text.trim().isEmpty ||
        _quantityController.text.trim().isEmpty ||
        _emojiController.text.trim().isEmpty) {
      _showErrorSnackBar('Tutti i campi sono obbligatori');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crea un item temporaneo con i dati aggiornati per la lista della spesa
      final itemForShoppingList = widget.item.copyWith(
        name: _nameController.text.trim(),
        quantity: _quantityController.text.trim(),
        imageUrl: _emojiController.text.trim(),
        category: _selectedCategory,
        expiryDate: _selectedDate,
      );

      // Salva il controller prima delle operazioni async
      final foodController = mounted ? context.read<FoodController>() : null;

      if (foodController == null || !mounted) return;

      // Aggiungi alla lista della spesa
      await DatabaseService.addOutOfStockItemToShoppingList(
        itemForShoppingList,
      );

      // Elimina completamente l'item dall'inventario (non solo marcarlo come non esaurito)
      await foodController.deleteFoodItem(widget.item.id);

      if (!mounted) return;

      Navigator.pop(context);
      _showSuccessSnackBar(
        '${itemForShoppingList.name} aggiunto alla lista della spesa!',
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Errore nell\'aggiunta alla lista: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateItemWithStatus(FoodStatus status) async {
    if (!mounted) return;

    if (_nameController.text.trim().isEmpty ||
        _quantityController.text.trim().isEmpty ||
        _emojiController.text.trim().isEmpty) {
      _showErrorSnackBar('Tutti i campi sono obbligatori');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedItem = widget.item.copyWith(
        name: _nameController.text.trim(),
        quantity: _quantityController.text.trim(),
        imageUrl: _emojiController.text.trim(),
        category: _selectedCategory,
        expiryDate: _selectedDate,
        isOutOfStock: status == FoodStatus.outOfStock,
        updatedAt: DateTime.now(),
      );

      final foodController = mounted ? context.read<FoodController>() : null;

      if (foodController == null || !mounted) return;

      await foodController.updateFoodItem(updatedItem);

      if (!mounted) return;

      Navigator.pop(context);
      _showSuccessSnackBar('Alimento aggiornato con successo!');
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

  Future<void> _deleteItem() async {
    if (!mounted) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => SimpleDialog(
            title: const Text(
              'Elimina alimento',
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
                'Sei sicuro di voler eliminare "${widget.item.name}"? Questa azione non può essere annullata.',
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
        final foodController = context.read<FoodController>();
        await foodController.deleteFoodItem(widget.item.id);

        if (!mounted) return;

        Navigator.pop(context);
        _showSuccessSnackBar('Alimento eliminato con successo!');
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
                    widget.isAddingToShoppingList
                        ? 'Aggiungi alla Lista della Spesa'
                        : 'Modifica Alimento',
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
                    widget.inventory.name,
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

            // Form Fields
            Row(
              children: [
                // Emoji field
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _emojiController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      labelText: 'Icona',
                      labelStyle: const TextStyle(
                        color: AppTheme.unselectedText,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppTheme.grey50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                        ),
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
                ),
                const SizedBox(width: 16),
                // Name field
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome alimento *',
                      labelStyle: const TextStyle(
                        color: AppTheme.unselectedText,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppTheme.grey50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                        ),
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
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quantity and Category
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    onChanged: (value) {
                      // Auto-detect if quantity is 0 to mark as out of stock
                      if (value.trim() == '0') {
                        // Don't automatically change status, just prepare for it
                        // User can explicitly mark as out of stock if needed
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Quantità *',
                      labelStyle: const TextStyle(
                        color: AppTheme.unselectedText,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppTheme.grey50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                        ),
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      labelStyle: const TextStyle(
                        color: AppTheme.unselectedText,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppTheme.grey50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.cardBorder,
                          width: 2,
                        ),
                      ),
                    ),
                    items:
                        FoodCategories.categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date picker
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
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
                    const Icon(
                      Icons.calendar_today,
                      color: AppTheme.unselectedText,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? 'Scadenza: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Seleziona data di scadenza (opzionale)',
                      style: const TextStyle(
                        color: AppTheme.black,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = null;
                          });
                        },
                        child: const Icon(
                          Icons.clear,
                          color: AppTheme.unselectedText,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mark as out of stock button (nascondi se stiamo aggiungendo alla lista della spesa)
            if (widget.item.status != FoodStatus.outOfStock &&
                !widget.isAddingToShoppingList)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _markAsOutOfStock,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.orange,
                    side: const BorderSide(color: AppTheme.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(
                    UniconsLine.exclamation_triangle,
                    size: 18,
                    color: AppTheme.orange,
                  ),
                  label: const Text(
                    'Segna come esaurito',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Nascondi il bottone "Elimina" quando siamo in modalità "Aggiungi alla Lista della Spesa"
                if (!widget.isAddingToShoppingList)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _deleteItem,
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
                if (!widget.isAddingToShoppingList) const SizedBox(width: 16),
                Expanded(
                  flex: widget.isAddingToShoppingList ? 1 : 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateItem,
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
                      _isLoading
                          ? (widget.isAddingToShoppingList
                              ? 'Aggiungendo...'
                              : 'Salvando...')
                          : (widget.isAddingToShoppingList
                              ? 'Aggiungi alla Lista'
                              : 'Salva modifiche'),
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
      ),
    );
  }
}
