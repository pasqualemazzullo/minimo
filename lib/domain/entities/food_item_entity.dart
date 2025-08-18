class FoodItemEntity {
  final String id;
  final String inventoryId;
  final String name;
  final String category;
  final String quantity;
  final DateTime? expiryDate;
  final String imageUrl;
  final bool isOutOfStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodItemEntity({
    required this.id,
    required this.inventoryId,
    required this.name,
    required this.category,
    required this.quantity,
    this.expiryDate,
    required this.imageUrl,
    required this.isOutOfStock,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));
    return expiryDate!.isBefore(threeDaysFromNow) && !isExpired;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItemEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          inventoryId == other.inventoryId &&
          name == other.name &&
          category == other.category &&
          quantity == other.quantity &&
          expiryDate == other.expiryDate &&
          imageUrl == other.imageUrl &&
          isOutOfStock == other.isOutOfStock &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      inventoryId.hashCode ^
      name.hashCode ^
      category.hashCode ^
      quantity.hashCode ^
      expiryDate.hashCode ^
      imageUrl.hashCode ^
      isOutOfStock.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'FoodItemEntity{id: $id, inventoryId: $inventoryId, name: $name, category: $category, quantity: $quantity, expiryDate: $expiryDate, imageUrl: $imageUrl, isOutOfStock: $isOutOfStock, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}