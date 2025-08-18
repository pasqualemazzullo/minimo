import '../../core/utils/result.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();

  Future<Result<void>> resetPassword(String email);

  Future<Result<void>> resendConfirmation(String email);

  UserEntity? getCurrentUser();

  bool isAuthenticated();

  bool isEmailConfirmed();

  Stream<UserEntity?> get authStateChanges;
}