import '../errors/failures.dart';

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;

  T? get data => isSuccess ? (this as Success<T>).data : null;
  Failure? get failure => isError ? (this as Error<T>).failure : null;

  R fold<R>(
    R Function(Failure failure) onError,
    R Function(T data) onSuccess,
  ) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      Error<T>(:final failure) => onError(failure),
    };
  }

  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => Success(transform(data)),
      Error<T>(:final failure) => Error(failure),
    };
  }

  Future<Result<R>> asyncMap<R>(Future<R> Function(T data) transform) async {
    return switch (this) {
      Success<T>(:final data) => Success(await transform(data)),
      Error<T>(:final failure) => Error(failure),
    };
  }
}