// lib/core/kernel/usecase.dart

import 'result.dart';

abstract class UseCase<Input, Output> {
  Future<Result<Output>> call(Input input);
}

abstract class NoParamsUseCase<Output> {
  Future<Result<Output>> call();
}
