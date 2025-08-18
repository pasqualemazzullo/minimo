import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/inventory_model.dart';
import '../../../data/models/food_item_model.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/food_item_edit_sheet.dart';
import '../../widgets/invitations_bottom_sheet.dart';
import '../../controllers/food_controller.dart';
import '../../controllers/invitations_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/app_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dati dinamici
  int expiredItems = 0;
  int outOfStock = 0;
  int expiringSoonItems = 0;
  double foodWastagePercent = 0.0;
  bool isLoading = true;

  // Alimento prossimo a scadenza
  FoodItemModel? nextExpiringItem;
  String? nextExpiringInventoryName;

  List<InventoryModel> inventories = [];
  List<FoodItemModel> allFoodItems = [];

  // Ricerca
  final TextEditingController _searchController = TextEditingController();
  List<FoodItemModel> filteredFoodItems = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    // Inizializza il FoodController e InvitationsController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodController>().loadAllData();
      context.read<InvitationsController>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    try {
      final foodController = context.read<FoodController>();

      // I dati sono già caricati dal FoodController
      inventories = foodController.inventories;
      allFoodItems = foodController.allFoodItems;

      _calculateStatistics();
    } catch (e) {
      if (mounted) {
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
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _calculateStatistics() {
    final stats = _calculateStatisticsFromData(inventories, allFoodItems);
    expiredItems = stats['expiredItems'];
    outOfStock = stats['outOfStock'];
    expiringSoonItems = stats['expiringSoonItems'];
    nextExpiringItem = stats['nextExpiringItem'];
    nextExpiringInventoryName = stats['nextExpiringInventoryName'];
    foodWastagePercent = stats['foodWastagePercent'];

    setState(() {});
  }

  Map<String, dynamic> _calculateStatisticsFromData(
    List<InventoryModel> currentInventories,
    List<FoodItemModel> currentAllFoodItems,
  ) {
    // Reset contatori
    int currentExpiredItems = 0;
    int currentOutOfStock = 0;
    int currentExpiringSoonItems = 0;
    FoodItemModel? currentNextExpiringItem;
    String? currentNextExpiringInventoryName;
    double currentFoodWastagePercent = 0.0;

    // Lista per trovare l'alimento prossimo alla scadenza
    List<MapEntry<FoodItemModel, String>> validItems = [];

    for (final item in currentAllFoodItems) {
      // Trova l'inventario di appartenenza
      final inventory = currentInventories.firstWhere(
        (inv) => inv.id == item.inventoryId,
        orElse:
            () => InventoryModel(
              id: '',
              userId: '',
              name: 'Sconosciuto',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      );

      // Conta stati
      switch (item.status) {
        case FoodStatus.expired:
          currentExpiredItems++;
          break;
        case FoodStatus.outOfStock:
          currentOutOfStock++;
          break;
        case FoodStatus.expiringSoon:
          currentExpiringSoonItems++;
          // Aggiungi agli elementi validi per la scadenza
          if (item.expiryDate != null) {
            validItems.add(MapEntry(item, inventory.name));
          }
          break;
        case FoodStatus.fresh:
          // Aggiungi agli elementi validi per la scadenza
          if (item.expiryDate != null) {
            validItems.add(MapEntry(item, inventory.name));
          }
          break;
      }
    }

    // Trova l'alimento più prossimo alla scadenza
    if (validItems.isNotEmpty) {
      validItems.sort((a, b) => a.key.expiryDate!.compareTo(b.key.expiryDate!));
      final closestItem = validItems.first;
      currentNextExpiringItem = closestItem.key;
      currentNextExpiringInventoryName = closestItem.value;
    }

    // Calcola percentuale spreco (prodotti scaduti rispetto al totale)
    if (currentAllFoodItems.isNotEmpty) {
      currentFoodWastagePercent =
          (currentExpiredItems / currentAllFoodItems.length) * 100;
    } else {
      currentFoodWastagePercent = 0.0;
    }

    return {
      'expiredItems': currentExpiredItems,
      'outOfStock': currentOutOfStock,
      'expiringSoonItems': currentExpiringSoonItems,
      'nextExpiringItem': currentNextExpiringItem,
      'nextExpiringInventoryName': currentNextExpiringInventoryName,
      'foodWastagePercent': currentFoodWastagePercent,
    };
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        isSearching = false;
        filteredFoodItems = [];
      } else {
        isSearching = true;
        filteredFoodItems = context.read<FoodController>().searchFoodItems(
          query,
        );
      }
    });
  }

  void _showFoodItemBottomSheet(FoodItemModel item) {
    final currentInventories = context.read<FoodController>().inventories;
    final inventory = currentInventories.firstWhere(
      (inv) => inv.id == item.inventoryId,
      orElse:
          () => InventoryModel(
            id: '',
            userId: '',
            name: 'Sconosciuto',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoodItemEditSheet(item: item, inventory: inventory),
    );
  }

  String _getExpiryText(FoodItemModel item) {
    if (item.expiryDate == null) return 'Nessuna scadenza';

    final now = DateTime.now();
    final daysToExpiry = item.expiryDate!.difference(now).inDays;

    if (daysToExpiry < 0) {
      return 'Scaduto ${-daysToExpiry} giorni fa';
    } else if (daysToExpiry == 0) {
      return 'Scade oggi';
    } else if (daysToExpiry == 1) {
      return 'Scade tra 1 giorno';
    } else {
      return 'Scade tra $daysToExpiry giorni';
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text(
              'Logout',
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
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            children: [
              const Text(
                'Sei sicuro di voler uscire dal tuo account?',
                style: TextStyle(fontSize: 14, color: AppTheme.black),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: () async {
                      Navigator.pop(context);

                      final authController = context.read<AuthController>();
                      final appController = context.read<AppController>();

                      await authController.signOut();
                      appController.setAuthenticated(false);
                    },
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
                    child: const Text('Esci'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minimo', style: AppTheme.textLargeBold),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        elevation: 0,
        actions: [
          Consumer<InvitationsController>(
            builder: (context, invitationsController, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(UniconsLine.bell, color: AppTheme.black),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const InvitationsBottomSheet(),
                      );
                    },
                  ),
                  if (invitationsController.hasNotifications)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${invitationsController.pendingCount}',
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _showLogoutDialog(context),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  () {
                    final user = Supabase.instance.client.auth.currentUser;
                    final email = user?.email;
                    if (email != null && email.isNotEmpty) {
                      return email.substring(0, 1).toUpperCase();
                    }
                    return 'U'; // Fallback per "User"
                  }(),
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<FoodController>(
        builder: (context, foodController, child) {
          // Use data directly from the controller
          final currentInventories = foodController.inventories;
          final currentAllFoodItems = foodController.allFoodItems;

          // Calculate statistics directly without setState
          final stats = _calculateStatisticsFromData(
            currentInventories,
            currentAllFoodItems,
          );
          final currentExpiredItems = stats['expiredItems'] as int;
          final currentOutOfStock = stats['outOfStock'] as int;
          final currentNextExpiringItem =
              stats['nextExpiringItem'] as FoodItemModel?;
          final currentNextExpiringInventoryName =
              stats['nextExpiringInventoryName'] as String?;
          final currentFoodWastagePercent =
              stats['foodWastagePercent'] as double;

          return isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra di ricerca
                    TextFormField(
                      controller: _searchController,
                      cursorColor: AppTheme.primaryColor,
                      decoration: InputDecoration(
                        labelText: 'Cerca nella tua dispensa',
                        labelStyle: const TextStyle(
                          color: AppTheme.unselectedText,
                          fontSize: 14,
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.unselectedText,
                        ),
                        suffixIcon:
                            isSearching
                                ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: AppTheme.unselectedText,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch('');
                                  },
                                )
                                : null,
                        filled: true,
                        fillColor: AppTheme.chipBg,
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
                      onChanged: _performSearch,
                    ),
                    const SizedBox(height: 20),

                    // Risultati della ricerca
                    if (isSearching) ...[
                      Text(
                        'Risultati della ricerca (${filteredFoodItems.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (filteredFoodItems.isEmpty)
                        Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 8,
                          ),
                          color: AppTheme.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppTheme.cardBorder),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  color: AppTheme.grey,
                                  size: 50,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nessun risultato',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Non ho trovato alimenti corrispondenti alla tua ricerca',
                                        style: TextStyle(
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
                        )
                      else
                        ...filteredFoodItems.map((item) {
                          final inventory = currentInventories.firstWhere(
                            (inv) => inv.id == item.inventoryId,
                            orElse:
                                () => InventoryModel(
                                  id: '',
                                  userId: '',
                                  name: 'Sconosciuto',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                          );

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 8,
                                ),
                                color: AppTheme.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                    color: AppTheme.cardBorder,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () => _showFoodItemBottomSheet(item),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppTheme.grey200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.imageUrl,
                                        style: AppTheme.textExtraLarge,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    item.name,
                                    style: AppTheme.textLargeBold,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.quantity,
                                        style: const TextStyle(
                                          color: AppTheme.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (item.expiryDate != null)
                                        Text(
                                          _getExpiryText(item),
                                          style: TextStyle(
                                            color:
                                                item.status ==
                                                            FoodStatus
                                                                .expiringSoon ||
                                                        item.status ==
                                                            FoodStatus.expired
                                                    ? AppTheme.red
                                                    : AppTheme.orange,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 16,
                                top: -8,
                                child: Chip(
                                  label: Text(
                                    inventory.name,
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                  backgroundColor: AppTheme.chipBg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 0,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                    ] else ...[
                      // Card alimento prossimo a scadenza con chip sopra il bordo
                      currentNextExpiringItem != null
                          ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 8,
                                ),
                                color: AppTheme.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: AppTheme.cardBorder),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    if (currentNextExpiringInventoryName !=
                                        null) {
                                      // Trova l'inventario corrispondente
                                      final inventory = currentInventories
                                          .firstWhere(
                                            (inv) =>
                                                inv.name ==
                                                currentNextExpiringInventoryName,
                                          );

                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder:
                                            (context) => FoodItemEditSheet(
                                              item: currentNextExpiringItem,
                                              inventory: inventory,
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
                                      child: Text(
                                        currentNextExpiringItem.imageUrl,
                                        style: AppTheme.textExtraLarge,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    currentNextExpiringItem.name,
                                    style: AppTheme.textLargeBold,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentNextExpiringItem.quantity,
                                        style: TextStyle(
                                          color: AppTheme.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _getExpiryText(currentNextExpiringItem),
                                        style: TextStyle(
                                          color:
                                              currentNextExpiringItem.status ==
                                                      FoodStatus.expiringSoon
                                                  ? AppTheme.red
                                                  : AppTheme.orange,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 16,
                                top: -16,
                                child: Chip(
                                  label: Text(
                                    currentNextExpiringInventoryName ??
                                        'Sconosciuto',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: AppTheme.chipBg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 0,
                                  ),
                                ),
                              ),
                            ],
                          )
                          : Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 8,
                            ),
                            color: AppTheme.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppTheme.cardBorder),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
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
                                        '✨',
                                        style: AppTheme.textExtraLarge,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tutto in ordine!',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Non ci sono alimenti in scadenza',
                                          style: TextStyle(
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
                      const SizedBox(height: 10),
                      // Indicatori
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _IndicatorCard(
                              label: 'Scaduti',
                              value: currentExpiredItems.toString(),
                              color: AppTheme.alertRedBackground,
                              textColor: AppTheme.alertRedText,
                              borderColor: AppTheme.alertRedBorder,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _IndicatorCard(
                              label: 'Esauriti',
                              value: currentOutOfStock.toString(),
                              color: AppTheme.alertYellowBackground,
                              textColor: AppTheme.alertYellowText,
                              borderColor: AppTheme.alertYellowBorder,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _IndicatorCard(
                              label: 'Spreco',
                              value:
                                  '${currentFoodWastagePercent.toStringAsFixed(1)}%',
                              color: AppTheme.alertBlueBackground,
                              textColor: AppTheme.alertBlueText,
                              borderColor: AppTheme.alertBlueBorder,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
        },
      ),
    );
  }
}

// Widget per gli indicatori
class _IndicatorCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  final Color borderColor;

  const _IndicatorCard({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      color: color,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: AppTheme.black)),
          ],
        ),
      ),
    );
  }
}
