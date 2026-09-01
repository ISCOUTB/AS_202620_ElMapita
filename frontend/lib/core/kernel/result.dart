// lib/core/kernel/result.dart

sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(String error) failure,
  });
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(String error) failure,
  }) => success(value);
}

class Failure<T> extends Result<T> {
  final String error;
  const Failure(this.error);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(String error) failure,
  }) => failure(error);
}
