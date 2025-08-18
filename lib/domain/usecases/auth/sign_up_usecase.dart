import '../../../core/utils/result.dart';
import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _authRepository;

  const SignUpUseCase(this._authRepository);

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await _authRepository.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      fullName: fullName?.trim() ?? '',
    );
  }
}