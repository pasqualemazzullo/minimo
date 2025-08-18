class UserEntity {
  final String id;
  final String email;
  final String? fullName;
  final DateTime? emailConfirmedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.emailConfirmedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmailConfirmed => emailConfirmedAt != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          fullName == other.fullName &&
          emailConfirmedAt == other.emailConfirmedAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      fullName.hashCode ^
      emailConfirmedAt.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'UserEntity{id: $id, email: $email, fullName: $fullName, emailConfirmedAt: $emailConfirmedAt, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}