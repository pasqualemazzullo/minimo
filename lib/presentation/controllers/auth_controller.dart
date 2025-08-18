import 'package:flutter/foundation.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth/sign_in_usecase.dart';
import '../../domain/usecases/auth/sign_up_usecase.dart';
import '../../domain/usecases/auth/sign_out_usecase.dart';

class AuthController extends ChangeNotifier {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;

  AuthController({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
  })  : _signInUseCase = signInUseCase,
        _signUpUseCase = signUpUseCase,
        _signOutUseCase = signOutUseCase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserEntity? _currentUser;
  UserEntity? get currentUser => _currentUser;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _signInUseCase(
        email: email,
        password: password,
      );

      result.fold(
        (failure) => _setError(_mapFailureToMessage(failure)),
        (user) => _currentUser = user,
      );

      return result;
    } finally {
      _setLoading(false);
    }
  }

  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _signUpUseCase(
        email: email,
        password: password,
        fullName: fullName,
      );

      result.fold(
        (failure) => _setError(_mapFailureToMessage(failure)),
        (user) => _currentUser = user,
      );

      return result;
    } finally {
      _setLoading(false);
    }
  }

  Future<Result<void>> signOut() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _signOutUseCase();

      result.fold(
        (failure) => _setError(_mapFailureToMessage(failure)),
        (_) => _currentUser = null,
      );

      return result;
    } finally {
      _setLoading(false);
    }
  }

  String _mapFailureToMessage(Failure failure) {
    return switch (failure) {
      InvalidCredentialsFailure() => 'Email o password non corretti',
      EmailNotConfirmedFailure() => 'Conferma prima la tua email',
      WeakPasswordFailure() => 'La password è troppo debole',
      EmailAlreadyInUseFailure() => 'Email già registrata',
      NetworkFailure() => 'Errore di connessione',
      ServerFailure() => 'Errore del server',
      _ => failure.message,
    };
  }
}