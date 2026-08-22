// Core kernel - Base classes for domain layer
// lib/core/kernel/result.dart

abstract class Result<T> {
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

// lib/core/kernel/usecase.dart

abstract class UseCase<Input, Output> {
  Future<Result<Output>> call(Input input);
}

abstract class NoParamsUseCase<Output> {
  Future<Result<Output>> call();
}

// lib/core/kernel/entity.dart

abstract class Entity<ID> {
  final ID id;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Entity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entity<ID> && runtimeType == other.runtimeType && id == other.id;
  
  @override
  int get hashCode => id.hashCode;
}

// lib/core/kernel/value_object.dart

abstract class ValueObject {
  const ValueObject();
  
  List<Object?> get props;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueObject && runtimeType == other.runtimeType && props == other.props;
  
  @override
  int get hashCode => Object.hashAll(props);
}

// lib/core/kernel/extensions.dart

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  
  T? get valueOrNull => switch (this) {
    Success(value: final v) => v,
    Failure() => null,
  };
  
  String? get errorOrNull => switch (this) {
    Success() => null,
    Failure(error: final e) => e,
  };
}