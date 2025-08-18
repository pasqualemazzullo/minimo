import '../../domain/entities/shopping_list_item_entity.dart';

class ShoppingListItemModel extends ShoppingListItemEntity {
  const ShoppingListItemModel({
    required super.id,
    required super.inventoryId,
    required super.name,
    required super.quantity,
    required super.emoji,
    required super.isChecked,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ShoppingListItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListItemModel(
      id: json['id'] as String,
      inventoryId: json['inventory_id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as String,
      emoji: json['emoji'] as String? ?? '📦',
      isChecked: json['is_checked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_id': inventoryId,
      'name': name,
      'quantity': quantity,
      'emoji': emoji,
      'is_checked': isChecked,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsert() {
    return {
      'inventory_id': inventoryId,
      'name': name,
      'quantity': quantity,
      'emoji': emoji,
      'is_checked': isChecked,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ShoppingListItemModel copyWith({
    String? id,
    String? inventoryId,
    String? name,
    String? quantity,
    String? emoji,
    bool? isChecked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingListItemModel(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      emoji: emoji ?? this.emoji,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ShoppingListItemModel.fromEntity(ShoppingListItemEntity entity) {
    return ShoppingListItemModel(
      id: entity.id,
      inventoryId: entity.inventoryId,
      name: entity.name,
      quantity: entity.quantity,
      emoji: entity.emoji,
      isChecked: entity.isChecked,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  ShoppingListItemEntity toEntity() {
    return ShoppingListItemEntity(
      id: id,
      inventoryId: inventoryId,
      name: name,
      quantity: quantity,
      emoji: emoji,
      isChecked: isChecked,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}