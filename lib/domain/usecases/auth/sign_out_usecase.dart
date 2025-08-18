import '../../../core/utils/result.dart';
import '../../repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _authRepository;

  const SignOutUseCase(this._authRepository);

  Future<Result<void>> call() async {
    return await _authRepository.signOut();
  }
}