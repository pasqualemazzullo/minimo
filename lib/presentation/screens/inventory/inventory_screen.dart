import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import '../../../data/models/food_item_model.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/food_item_edit_sheet.dart';
import '../../widgets/inventory_dropdown.dart';
import '../../controllers/food_controller.dart';
import '../../controllers/inventory_selection_controller.dart';
import '../../../core/constants/food_categories.dart';

enum SortOption { name, quantity, expiryDate }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  InventoryScreenState createState() => InventoryScreenState();
}

class InventoryScreenState extends State<InventoryScreen> {
  FoodStatus? selectedStatus = FoodStatus.fresh;
  String? selectedCategory;
  SortOption sortOption = SortOption.name;
  bool isAscending = true;

  bool isLoading = true;

  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadData();
    
    // Initialize the FoodController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodController>().loadAllData();
    });
  }

  Future<void> _loadData() async {
    try {
      final foodController = context.read<FoodController>();
      final inventoryController = context.read<InventorySelectionController>();
      
      // Initialize controllers if not already done
      if (foodController.inventories.isEmpty) {
        await foodController.loadAllData();
      }
      
      if (inventoryController.selectedInventory == null) {
        await inventoryController.initialize();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricamento dei dati: $e', style: const TextStyle(color: AppTheme.white)),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStatusFilterTap(FoodStatus status) {
    int page = 0;
    switch (status) {
      case FoodStatus.fresh:
        page = 0;
        break;
      case FoodStatus.outOfStock:
        page = 1;
        break;
      case FoodStatus.expired:
        page = 2;
        break;
      default:
        page = 0;
    }
    _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  List<String> get categories => ['Tutti', ...FoodCategories.categories];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventario',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        actions: [
          InventoryDropdown(
            onInventoryChanged: (inventory) {
              // Optional callback - the UI will update automatically via Consumer
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.white,
      body: Consumer2<FoodController, InventorySelectionController>(
        builder: (context, foodController, inventoryController, child) {
          // Use data directly from the controllers
          final currentInventories = foodController.inventories;
          final selectedInventory = inventoryController.selectedInventory;
          final currentFoodItems = selectedInventory != null
              ? foodController.getFoodItemsForInventory(selectedInventory.id)
              : <FoodItemModel>[];

          // Sync inventories with selection controller when food controller updates
          if (currentInventories.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              inventoryController.updateInventories(currentInventories);
            });
          }
          
          return isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
              : currentInventories.isEmpty
              ? Center(
                child: Text(
                  'Nessun inventario trovato.\nCreane uno nuovo!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.grey, fontSize: 16),
                ),
              )
              : Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onStatusFilterTap(FoodStatus.fresh),
                            child: _buildStatusFilter(
                              'Disponibili',
                              FoodStatus.fresh,
                              0,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap:
                                () => _onStatusFilterTap(FoodStatus.outOfStock),
                            child: _buildStatusFilter(
                              'Esauriti',
                              FoodStatus.outOfStock,
                              1,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onStatusFilterTap(FoodStatus.expired),
                            child: _buildStatusFilter(
                              'Scaduti',
                              FoodStatus.expired,
                              2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 50,
                    padding: EdgeInsets.only(left: 16, right: 16, top: 0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getSortOptionText(sortOption),
                                    style: TextStyle(
                                      color: AppTheme.chipText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    isAscending
                                        ? UniconsLine.arrow_up
                                        : UniconsLine.arrow_down,
                                    size: 18,
                                    color: AppTheme.chipText,
                                  ),
                                ],
                              ),
                              selected: false,
                              backgroundColor: AppTheme.chipBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: AppTheme.chipBorder),
                              ),
                              onSelected: (_) async {
                                final SortOption? selected =
                                    await showDialog<SortOption>(
                                      context: context,
                                      builder:
                                          (context) => SimpleDialog(
                                            title: Text('Ordina per'),
                                            backgroundColor: AppTheme.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              side: BorderSide(
                                                color: AppTheme.cardBorder,
                                              ),
                                            ),
                                            children: [
                                              _buildDialogOption(
                                                context,
                                                'Nome',
                                                SortOption.name,
                                                sortOption,
                                              ),
                                              _buildDialogOption(
                                                context,
                                                'Quantità',
                                                SortOption.quantity,
                                                sortOption,
                                              ),
                                              _buildDialogOption(
                                                context,
                                                'Scadenza',
                                                SortOption.expiryDate,
                                                sortOption,
                                              ),
                                            ],
                                          ),
                                    );
                                if (selected != null) {
                                  setState(() {
                                    if (selected == sortOption) {
                                      isAscending = !isAscending;
                                    } else {
                                      sortOption = selected;
                                    }
                                  });
                                }
                              },
                              selectedColor: AppTheme.chipSelectedBg,
                              checkmarkColor: AppTheme.chipSelectedText,
                            ),
                          );
                        } else {
                          final category = categories[index - 1];
                          final isSelected = selectedCategory == category;
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(
                                category,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? AppTheme.chipSelectedText
                                          : AppTheme.chipText,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              backgroundColor: AppTheme.chipBg,
                              selectedColor: AppTheme.chipSelectedBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? AppTheme.chipSelectedBorder
                                          : AppTheme.chipBorder,
                                ),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  selectedCategory = selected ? category : null;
                                });
                              },
                              checkmarkColor: AppTheme.chipSelectedText,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                          switch (index) {
                            case 0:
                              selectedStatus = FoodStatus.fresh;
                              break;
                            case 1:
                              selectedStatus = FoodStatus.outOfStock;
                              break;
                            case 2:
                              selectedStatus = FoodStatus.expired;
                              break;
                          }
                        });
                      },
                      children: [
                        _buildFoodListWithData(FoodStatus.fresh, currentFoodItems),
                        _buildFoodListWithData(FoodStatus.outOfStock, currentFoodItems),
                        _buildFoodListWithData(FoodStatus.expired, currentFoodItems),
                      ],
                    ),
                  ),
                ],
              );
        },
      ),
    );
  }


  Widget _buildFoodListWithData(FoodStatus status, List<FoodItemModel> currentFoodItems) {
    List<FoodItemModel> items = List.from(currentFoodItems);

    if (status == FoodStatus.fresh) {
      items =
          items
              .where(
                (item) =>
                    item.status == FoodStatus.fresh ||
                    item.status == FoodStatus.expiringSoon,
              )
              .toList();
    } else {
      items = items.where((item) => item.status == status).toList();
    }

    if (selectedCategory != null && selectedCategory != 'Tutti') {
      items = items.where((item) => item.category == selectedCategory).toList();
    }

    items.sort((a, b) {
      int comparison = 0;
      switch (sortOption) {
        case SortOption.name:
          comparison = a.name.compareTo(b.name);
          break;
        case SortOption.quantity:
          comparison = a.quantity.compareTo(b.quantity);
          break;
        case SortOption.expiryDate:
          if (a.expiryDate == null && b.expiryDate == null) {
            comparison = 0;
          } else if (a.expiryDate == null) {
            comparison = 1;
          } else if (b.expiryDate == null) {
            comparison = -1;
          } else {
            comparison = a.expiryDate!.compareTo(b.expiryDate!);
          }
          break;
      }
      return isAscending ? comparison : -comparison;
    });

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => _buildFoodItemCard(items[index]),
    );
  }

  Widget _buildStatusFilter(String label, FoodStatus status, int pageIndex) {
    final isSelected = _currentPage == pageIndex;
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

  Widget _buildFoodItemCard(FoodItemModel item) {
    if (item.status == FoodStatus.outOfStock) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () {
              // Trova l'inventario corrente
              final selectedInventory = context.read<InventorySelectionController>().selectedInventory;
              if (selectedInventory != null) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => FoodItemEditSheet(
                    item: item,
                    inventory: selectedInventory,
                  ),
                );
              }
            },
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.cardBorder),
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.grey200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            item.imageUrl,
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              item.quantity,
                              style: TextStyle(
                                color: AppTheme.grey700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Trova l'inventario corrente
                        final selectedInventory = context.read<InventorySelectionController>().selectedInventory;
                        if (selectedInventory != null) {
                          // Apri FoodItemEditSheet per impostare la quantità da comprare
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => FoodItemEditSheet(
                              item: item,
                              inventory: selectedInventory,
                              isAddingToShoppingList: true, // Flag per indicare che stiamo aggiungendo alla lista della spesa
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        textStyle: TextStyle(
                          fontFamily: AppConstants.fontFamily,
                          fontSize: 14,
                        ),
                      ),
                      child: Text('Aggiungi alla Lista della Spesa'),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          ),
          Positioned(
            top: 24,
            right: 32,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.outOfStockLabel,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Esaurito',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        onTap: () {
          // Trova l'inventario corrente
          final selectedInventory = context.read<InventorySelectionController>().selectedInventory;
          if (selectedInventory != null) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => FoodItemEditSheet(
                item: item,
                inventory: selectedInventory,
              ),
            );
          }
        },
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.grey200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(item.imageUrl, style: TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.quantity,
              style: TextStyle(color: AppTheme.grey700, fontSize: 12),
            ),
            _buildExpiryText(item),
          ],
        ),
      ),
    );
  }

  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.name:
        return 'Nome';
      case SortOption.quantity:
        return 'Quantità';
      case SortOption.expiryDate:
        return 'Scadenza';
    }
  }

  Widget _buildExpiryText(FoodItemModel item) {
    if (item.expiryDate == null) {
      return Text(
        'Nessuna scadenza',
        style: TextStyle(color: AppTheme.grey, fontSize: 12),
      );
    }

    final now = DateTime.now();
    final daysToExpiry = item.expiryDate!.difference(now).inDays;
    if (daysToExpiry >= 0 && daysToExpiry <= 7) {
      String text;
      if (daysToExpiry == 0) {
        text = 'Scade oggi';
      } else if (daysToExpiry == 1) {
        text = 'Scade tra 1 giorno';
      } else {
        text = 'Scade tra $daysToExpiry giorni';
      }
      return Text(text, style: TextStyle(color: AppTheme.red, fontSize: 12));
    } else {
      return Text(
        'Scadenza:  ${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}',
        style: TextStyle(color: AppTheme.black, fontSize: 12),
      );
    }
  }

  Widget _buildDialogOption(
    BuildContext context,
    String label,
    SortOption value,
    SortOption selected,
  ) {
    final bool isSelected = value == selected;
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.white : AppTheme.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(UniconsLine.check, color: AppTheme.white, size: 20),
          ],
        ),
      ),
    );
  }
}
