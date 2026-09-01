// lib/features/auth/domain/repositories.dart

import 'package:either_dart/either.dart';
import 'package:equatable/equatable.dart';
import 'entities.dart';

abstract class AuthRepository {
  Future<Either<String, AuthResult>> signIn(String email, String password);
  Future<Either<String, AuthResult>> signUp(String email, String password, String nombre);
  Future<Either<String, AuthTokens>> refreshToken(String refreshToken);
  Future<void> signOut();
  Future<Either<String, User>> getCurrentUser();
}

class AuthResult extends Equatable {
  final User user;
  final AuthTokens tokens;
  const AuthResult({required this.user, required this.tokens});
  @override List<Object?> get props => [user, tokens];
}