// lib/features/auth/domain/entities.dart

import 'package:equatable/equatable.dart';
import '../../../core/kernel/value_object.dart';

class UserId extends ValueObject {
  final String value;
  const UserId(this.value);
  @override List<Object?> get props => [value];
}

enum UserRole { estudiante, visitante, docente, adminStaff, adminUtb }

class User extends Equatable {
  final UserId id;
  final String email;
  final UserRole role;
  final String nombre;
  final bool activo;

  const User({
    required this.id,
    required this.email,
    required this.role,
    required this.nombre,
    required this.activo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: UserId(json['id'] as String),
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      nombre: json['nombre'] as String,
      activo: json['activo'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id.value,
    'email': email,
    'role': role.name,
    'nombre': nombre,
    'activo': activo,
  };

  @override List<Object?> get props => [id, email, role, nombre, activo];
}

class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
  @override List<Object?> get props => [accessToken, refreshToken, expiresIn];
}