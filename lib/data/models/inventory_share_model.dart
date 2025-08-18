class InventoryShareModel {
  final String id;
  final String inventoryId;
  final String userId;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryShareModel({
    required this.id,
    required this.inventoryId,
    required this.userId,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryShareModel.fromJson(Map<String, dynamic> json) {
    return InventoryShareModel(
      id: json['id'] as String,
      inventoryId: json['inventory_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_id': inventoryId,
      'user_id': userId,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InventoryShareModel copyWith({
    String? id,
    String? inventoryId,
    String? userId,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryShareModel(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';
  bool get canEdit => role != 'member' || role == 'admin' || role == 'owner';
}