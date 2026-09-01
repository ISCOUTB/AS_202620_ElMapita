// lib/features/auth/presentation/bloc/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../application/sign_in_use_case.dart';
import '../../domain/entities.dart';
import '../../../../core/storage/secure_storage.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object?> get props => [];
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested(this.email, this.password);
  @override List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String nombre;
  const AuthSignUpRequested(this.email, this.password, this.nombre);
  @override List<Object?> get props => [email, password, nombre];
}

class AuthSignOutRequested extends AuthEvent {}

class AuthCheckStatus extends AuthEvent {}

class AuthTokenRefreshed extends AuthEvent {
  final AuthTokens tokens;
  const AuthTokenRefreshed(this.tokens);
  @override List<Object?> get props => [tokens];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
  @override List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SignOutUseCase _signOutUseCase;
  final SecureStorage _secureStorage;

  AuthBloc({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required SignOutUseCase signOutUseCase,
    required SecureStorage secureStorage,
  })  : _signInUseCase = signInUseCase,
        _signUpUseCase = signUpUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _signOutUseCase = signOutUseCase,
        _secureStorage = secureStorage,
        super(AuthInitial()) {
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthTokenRefreshed>(_onTokenRefreshed);
  }

  Future<void> _onSignInRequested(AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _signInUseCase.execute(event.email, event.password);
    result.fold(
      (error) => emit(AuthError(error)),
      (authResult) => emit(AuthAuthenticated(authResult.user)),
    );
  }

  Future<void> _onSignUpRequested(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _signUpUseCase.execute(event.email, event.password, event.nombre);
    result.fold(
      (error) => emit(AuthError(error)),
      (authResult) => emit(AuthAuthenticated(authResult.user)),
    );
  }

  Future<void> _onSignOutRequested(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _signOutUseCase.execute();
    emit(AuthUnauthenticated());
  }

  Future<void> _onCheckStatus(AuthCheckStatus event, Emitter<AuthState> emit) async {
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      emit(AuthUnauthenticated());
      return;
    }

    final result = await _getCurrentUserUseCase.execute();
    result.fold(
      (error) => emit(AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  void _onTokenRefreshed(AuthTokenRefreshed event, Emitter<AuthState> emit) {
    // Token refreshed, state remains the same if user is authenticated
    if (state is AuthAuthenticated) {
      // Could update user if needed
    }
  }
}