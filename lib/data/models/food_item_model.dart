import '../../domain/entities/food_item_entity.dart';

enum FoodStatus { fresh, outOfStock, expired, expiringSoon }

class FoodItemModel extends FoodItemEntity {
  const FoodItemModel({
    required super.id,
    required super.inventoryId,
    required super.name,
    required super.category,
    required super.quantity,
    super.expiryDate,
    required super.imageUrl,
    required super.isOutOfStock,
    required super.createdAt,
    required super.updatedAt,
  });

  FoodStatus get status {
    final now = DateTime.now();
    
    if (isOutOfStock) return FoodStatus.outOfStock;
    
    if (expiryDate != null) {
      final daysToExpiry = expiryDate!.difference(now).inDays;
      if (daysToExpiry < 0) return FoodStatus.expired;
      if (daysToExpiry <= 3) return FoodStatus.expiringSoon;
    }
    
    return FoodStatus.fresh;
  }

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      id: json['id'] as String,
      inventoryId: json['inventory_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as String,
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date'] as String) 
          : null,
      imageUrl: json['image_url'] as String? ?? '📦',
      isOutOfStock: json['is_out_of_stock'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_id': inventoryId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'expiry_date': expiryDate?.toIso8601String(),
      'image_url': imageUrl,
      'is_out_of_stock': isOutOfStock,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsert() {
    return {
      'inventory_id': inventoryId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'expiry_date': expiryDate?.toIso8601String(),
      'image_url': imageUrl,
      'is_out_of_stock': isOutOfStock,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdate() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'expiry_date': expiryDate?.toIso8601String(),
      'image_url': imageUrl,
      'is_out_of_stock': isOutOfStock,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  FoodItemModel copyWith({
    String? id,
    String? inventoryId,
    String? name,
    String? category,
    String? quantity,
    DateTime? expiryDate,
    String? imageUrl,
    bool? isOutOfStock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodItemModel(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory FoodItemModel.fromEntity(FoodItemEntity entity) {
    return FoodItemModel(
      id: entity.id,
      inventoryId: entity.inventoryId,
      name: entity.name,
      category: entity.category,
      quantity: entity.quantity,
      expiryDate: entity.expiryDate,
      imageUrl: entity.imageUrl,
      isOutOfStock: entity.isOutOfStock,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  FoodItemEntity toEntity() {
    return FoodItemEntity(
      id: id,
      inventoryId: inventoryId,
      name: name,
      category: category,
      quantity: quantity,
      expiryDate: expiryDate,
      imageUrl: imageUrl,
      isOutOfStock: isOutOfStock,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}