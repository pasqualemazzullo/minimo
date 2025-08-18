import 'shopping_list_item_model.dart';

class ShoppingListItemWithCreatorModel extends ShoppingListItemModel {
  final String? createdBy;
  final String? creatorEmail;

  const ShoppingListItemWithCreatorModel({
    required super.id,
    required super.inventoryId,
    required super.name,
    required super.quantity,
    required super.emoji,
    required super.isChecked,
    required super.createdAt,
    required super.updatedAt,
    this.createdBy,
    this.creatorEmail,
  });

  factory ShoppingListItemWithCreatorModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListItemWithCreatorModel(
      id: json['id'] as String,
      inventoryId: json['inventory_id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as String,
      emoji: json['emoji'] as String? ?? '📦',
      isChecked: json['is_checked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      creatorEmail: json['creator_email'] as String?,
    );
  }

  @override
  Map<String, dynamic> toInsert() {
    final map = super.toInsert();
    map['created_by'] = createdBy;
    return map;
  }

  @override
  ShoppingListItemWithCreatorModel copyWith({
    String? id,
    String? inventoryId,
    String? name,
    String? quantity,
    String? emoji,
    bool? isChecked,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? creatorEmail,
  }) {
    return ShoppingListItemWithCreatorModel(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      emoji: emoji ?? this.emoji,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      creatorEmail: creatorEmail ?? this.creatorEmail,
    );
  }

  // Helper to check if current user is the creator
  bool isCreatedBy(String? currentUserId) {
    return createdBy == currentUserId;
  }

  // Helper to get creator display name
  String getCreatorDisplayName(String? currentUserId) {
    if (createdBy == currentUserId) {
      return 'Te';
    }
    if (creatorEmail != null) {
      // Extract name from email (part before @)
      return creatorEmail!.split('@')[0];
    }
    return 'Sconosciuto';
  }
}
