class ShoppingListItemEntity {
  final String id;
  final String inventoryId;
  final String name;
  final String quantity;
  final String emoji;
  final bool isChecked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShoppingListItemEntity({
    required this.id,
    required this.inventoryId,
    required this.name,
    required this.quantity,
    required this.emoji,
    required this.isChecked,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListItemEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          inventoryId == other.inventoryId &&
          name == other.name &&
          quantity == other.quantity &&
          emoji == other.emoji &&
          isChecked == other.isChecked &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      inventoryId.hashCode ^
      name.hashCode ^
      quantity.hashCode ^
      emoji.hashCode ^
      isChecked.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'ShoppingListItemEntity{id: $id, inventoryId: $inventoryId, name: $name, quantity: $quantity, emoji: $emoji, isChecked: $isChecked, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}