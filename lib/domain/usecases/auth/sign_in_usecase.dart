import '../../../core/utils/result.dart';
import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _authRepository;

  const SignInUseCase(this._authRepository);

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
  }) async {
    return await _authRepository.signIn(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }
}