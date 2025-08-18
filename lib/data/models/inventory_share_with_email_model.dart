import 'inventory_share_model.dart';

class InventoryShareWithEmailModel extends InventoryShareModel {
  final String? userEmail;

  const InventoryShareWithEmailModel({
    required super.id,
    required super.inventoryId,
    required super.userId,
    required super.role,
    required super.createdAt,
    required super.updatedAt,
    this.userEmail,
  });

  factory InventoryShareWithEmailModel.fromJson(Map<String, dynamic> json) {
    return InventoryShareWithEmailModel(
      id: json['id'] as String,
      inventoryId: json['inventory_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userEmail: json['user_email'] as String?,
    );
  }

  @override
  InventoryShareWithEmailModel copyWith({
    String? id,
    String? inventoryId,
    String? userId,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userEmail,
  }) {
    return InventoryShareWithEmailModel(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}