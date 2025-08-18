import '../../core/errors/exceptions.dart' as exceptions;
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/supabase_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  @override
  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final userModel = await _dataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      return Success(userModel.toEntity());
    } on exceptions.AuthException catch (e) {
      return Error(_mapAuthException(e));
    } on exceptions.ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } catch (e) {
      return Error(ServerFailure('Errore imprevisto: $e'));
    }
  }

  @override
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _dataSource.signIn(
        email: email,
        password: password,
      );
      return Success(userModel.toEntity());
    } on exceptions.AuthException catch (e) {
      return Error(_mapAuthException(e));
    } on exceptions.ServerException catch (e) {
      return Error(ServerFailure(e.message));
    } catch (e) {
      return Error(ServerFailure('Errore imprevisto: $e'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Success(null);
    } on exceptions.AuthException catch (e) {
      return Error(_mapAuthException(e));
    } catch (e) {
      return Error(ServerFailure('Errore imprevisto: $e'));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _dataSource.resetPassword(email);
      return const Success(null);
    } on exceptions.AuthException catch (e) {
      return Error(_mapAuthException(e));
    } catch (e) {
      return Error(ServerFailure('Errore imprevisto: $e'));
    }
  }

  @override
  Future<Result<void>> resendConfirmation(String email) async {
    // Implementation would be similar
    throw UnimplementedError();
  }

  @override
  UserEntity? getCurrentUser() {
    final userModel = _dataSource.getCurrentUser();
    return userModel?.toEntity();
  }

  @override
  bool isAuthenticated() {
    return _dataSource.isAuthenticated();
  }

  @override
  bool isEmailConfirmed() {
    final user = getCurrentUser();
    return user?.isEmailConfirmed ?? false;
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _dataSource.authStateChanges
        .map((userModel) => userModel?.toEntity());
  }

  AuthFailure _mapAuthException(exceptions.AuthException exception) {
    final message = exception.message.toLowerCase();
    
    if (message.contains('invalid login credentials') || 
        message.contains('invalid credentials')) {
      return const InvalidCredentialsFailure();
    } else if (message.contains('email not confirmed')) {
      return const EmailNotConfirmedFailure();
    } else if (message.contains('weak password')) {
      return const WeakPasswordFailure();
    } else if (message.contains('email already in use') ||
               message.contains('already registered')) {
      return const EmailAlreadyInUseFailure();
    }
    
    return AuthFailure(exception.message);
  }
}