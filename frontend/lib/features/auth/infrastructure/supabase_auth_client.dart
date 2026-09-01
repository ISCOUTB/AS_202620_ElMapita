// lib/features/auth/infrastructure/supabase_auth_client.dart

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:either_dart/either.dart';
import '../domain/entities.dart';
import '../domain/repositories.dart';
import '../../../core/storage/secure_storage.dart';

class SupabaseAuthClient implements AuthRepository {
  final supabase.SupabaseClient _client = supabase.Supabase.instance.client;
  final SecureStorage _secureStorage;

  SupabaseAuthClient(this._secureStorage);

  @override
  Future<Either<String, AuthResult>> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null || response.user == null) {
        return const Left('Credenciales inválidas');
      }

      final tokens = AuthTokens(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken ?? '',
        expiresIn: response.session!.expiresIn ?? 0,
      );

      await _secureStorage.setAccessToken(tokens.accessToken);
      await _secureStorage.setRefreshToken(tokens.refreshToken);
      await _secureStorage.setUserId(response.user!.id);

      final user = User.fromJson({
        'id': response.user!.id,
        'email': response.user!.email!,
        'role': response.user!.userMetadata?['role'] ?? 'estudiante',
        'nombre': response.user!.userMetadata?['nombre'] ?? response.user!.email!,
        'activo': true,
      });

      return Right(AuthResult(user: user, tokens: tokens));
    } on supabase.AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left('Error al iniciar sesión: $e');
    }
  }

  @override
  Future<Either<String, AuthResult>> signUp(String email, String password, String nombre) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'nombre': nombre},
      );

      if (response.session == null || response.user == null) {
        return const Left('Error al registrar usuario');
      }

      final tokens = AuthTokens(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken ?? '',
        expiresIn: response.session!.expiresIn ?? 0,
      );

      await _secureStorage.setAccessToken(tokens.accessToken);
      await _secureStorage.setRefreshToken(tokens.refreshToken);
      await _secureStorage.setUserId(response.user!.id);

      final user = User.fromJson({
        'id': response.user!.id,
        'email': response.user!.email!,
        'role': response.user!.userMetadata?['role'] ?? 'estudiante',
        'nombre': response.user!.userMetadata?['nombre'] ?? nombre,
        'activo': true,
      });

      return Right(AuthResult(user: user, tokens: tokens));
    } on supabase.AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left('Error al registrarse: $e');
    }
  }

  @override
  Future<Either<String, AuthTokens>> refreshToken(String refreshToken) async {
    try {
      final response = await _client.auth.refreshSession(refreshToken);
      
      if (response.session == null) {
        return const Left('No se pudo refrescar la sesión');
      }

      final tokens = AuthTokens(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken ?? '',
        expiresIn: response.session!.expiresIn ?? 0,
      );

      await _secureStorage.setAccessToken(tokens.accessToken);
      await _secureStorage.setRefreshToken(tokens.refreshToken);

      return Right(tokens);
    } on supabase.AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left('Error al refrescar token: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    await _secureStorage.clearAuth();
  }

  @override
  Future<Either<String, User>> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const Left('No hay usuario autenticado');
      }

      return Right(User.fromJson({
        'id': user.id,
        'email': user.email!,
        'role': user.userMetadata?['role'] ?? 'estudiante',
        'nombre': user.userMetadata?['nombre'] ?? user.email!,
        'activo': true,
      }));
    } catch (e) {
      return Left('Error al obtener usuario: $e');
    }
  }
}