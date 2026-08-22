import { Entity, ValueObject } from '../../../shared/kernel';

export type UserId = string & { readonly __brand: unique symbol };
export type UserRole = 'estudiante' | 'visitante' | 'docente' | 'admin_staff' | 'admin_utb';

export interface User extends Entity<UserId> {
  email: string;
  role: UserRole;
  nombre: string;
  activo: boolean;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface AuthRepository {
  findById(id: UserId): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
  updateRole(userId: UserId, role: UserRole): Promise<User>;
}

export interface SupabaseAuthClient {
  signInWithEmail(email: string, password: string): Promise<AuthTokens>;
  signUpWithEmail(email: string, password: string, metadata: { nombre: string }): Promise<AuthTokens>;
  refreshAccessToken(refreshToken: string): Promise<AuthTokens>;
  signOut(): Promise<void>;
  getUser(accessToken: string): Promise<User | null>;
  updateUserRole(userId: string, role: UserRole): Promise<void>;
}

// Use Case DTOs
export interface SignInInput {
  email: string;
  password: string;
}

export interface SignInOutput {
  user: User;
  tokens: AuthTokens;
}

export interface SignUpInput {
  email: string;
  password: string;
  nombre: string;
}

export interface SignUpOutput {
  user: User;
  tokens: AuthTokens;
}

export interface RefreshTokenInput {
  refreshToken: string;
}

export interface RefreshTokenOutput {
  tokens: AuthTokens;
}

export interface SignOutInput {
  accessToken: string;
}

export interface GetCurrentUserInput {
  accessToken: string;
}

export interface GetCurrentUserOutput {
  user: User;
}

export interface UpdateUserRoleInput {
  userId: string;
  role: UserRole;
}