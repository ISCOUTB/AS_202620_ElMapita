// lib/features/auth/application/sign_in_use_case.dart

import 'package:either_dart/either.dart';
import '../domain/entities.dart';
import '../domain/repositories.dart';
import '../../../core/storage/secure_storage.dart';

class SignInUseCase {
  final AuthRepository _authClient;
  final SecureStorage _secureStorage;

  SignInUseCase({
    required AuthRepository authClient,
    required SecureStorage secureStorage,
  })  : _authClient = authClient,
        _secureStorage = secureStorage;

  Future<Either<String, AuthResult>> execute(String email, String password) async {
    return await _authClient.signIn(email, password);
  }
}

class SignUpUseCase {
  final AuthRepository _authClient;
  final SecureStorage _secureStorage;

  SignUpUseCase({
    required AuthRepository authClient,
    required SecureStorage secureStorage,
  })  : _authClient = authClient,
        _secureStorage = secureStorage;

  Future<Either<String, AuthResult>> execute(String email, String password, String nombre) async {
    return await _authClient.signUp(email, password, nombre);
  }
}

class GetCurrentUserUseCase {
  final AuthRepository _authClient;

  GetCurrentUserUseCase(this._authClient);

  Future<Either<String, User>> execute() async {
    return await _authClient.getCurrentUser();
  }
}

class SignOutUseCase {
  final AuthRepository _authClient;

  SignOutUseCase(this._authClient);

  Future<void> execute() async {
    await _authClient.signOut();
  }
}