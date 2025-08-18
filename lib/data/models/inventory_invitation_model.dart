class InventoryInvitationModel {
  final String id;
  final String inventoryId;
  final String invitedBy;
  final String invitedEmail;
  final String? invitedUserId;
  final String role;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Additional fields from joins
  final String? inventoryName;
  final String? inviterEmail;

  const InventoryInvitationModel({
    required this.id,
    required this.inventoryId,
    required this.invitedBy,
    required this.invitedEmail,
    this.invitedUserId,
    required this.role,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.inventoryName,
    this.inviterEmail,
  });

  factory InventoryInvitationModel.fromJson(Map<String, dynamic> json) {
    return InventoryInvitationModel(
      id: json['id'] as String,
      inventoryId: json['inventory_id'] as String,
      invitedBy: json['invited_by'] as String,
      invitedEmail: json['invited_email'] as String,
      invitedUserId: json['invited_user_id'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      inventoryName: json['inventories']?['name'] as String?,
      inviterEmail: null, // Will be fetched separately if needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventory_id': inventoryId,
      'invited_by': invitedBy,
      'invited_email': invitedEmail,
      'invited_user_id': invitedUserId,
      'role': role,
      'status': status,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InventoryInvitationModel copyWith({
    String? id,
    String? inventoryId,
    String? invitedBy,
    String? invitedEmail,
    String? invitedUserId,
    String? role,
    String? status,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? inventoryName,
    String? inviterEmail,
  }) {
    return InventoryInvitationModel(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedEmail: invitedEmail ?? this.invitedEmail,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      role: role ?? this.role,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      inventoryName: inventoryName ?? this.inventoryName,
      inviterEmail: inviterEmail ?? this.inviterEmail,
    );
  }

  bool get isPending => status == 'pending';
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => isPending && !isExpired;
}