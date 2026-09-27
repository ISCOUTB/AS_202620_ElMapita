import { Inject, Injectable } from '@nestjs/common';
import { UseCase } from '../../../shared/kernel';
import type { User, UserRole, AuthTokens, SupabaseAuthClient } from '../domain';

export interface SignInInput {
  email: string;
  password: string;
}

export interface SignInOutput {
  user: User;
  tokens: AuthTokens;
}

@Injectable()
export class SignInUseCase implements UseCase<SignInInput, SignInOutput> {
  constructor(
    @Inject('SupabaseAuthClient')
    private readonly authClient: SupabaseAuthClient,
  ) {}

  async execute(input: SignInInput): Promise<SignInOutput> {
    const tokens = await this.authClient.signInWithEmail(
      input.email,
      input.password,
    );
    const user = await this.authClient.getUser(tokens.accessToken);

    if (!user) {
      throw new Error('User not found after sign in');
    }

    return { user, tokens };
  }
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

@Injectable()
export class SignUpUseCase implements UseCase<SignUpInput, SignUpOutput> {
  constructor(
    @Inject('SupabaseAuthClient')
    private readonly authClient: SupabaseAuthClient,
  ) {}

  async execute(input: SignUpInput): Promise<SignUpOutput> {
    const tokens = await this.authClient.signUpWithEmail(
      input.email,
      input.password,
      { nombre: input.nombre },
    );
    const user = await this.authClient.getUser(tokens.accessToken);

    if (!user) {
      throw new Error('User not found after sign up');
    }

    return { user, tokens };
  }
}

export interface RefreshTokenInput {
  refreshToken: string;
}

export interface RefreshTokenOutput {
  tokens: AuthTokens;
}

@Injectable()
export class RefreshTokenUseCase implements UseCase<
  RefreshTokenInput,
  RefreshTokenOutput
> {
  constructor(
    @Inject('SupabaseAuthClient')
    private readonly authClient: SupabaseAuthClient,
  ) {}

  async execute(input: RefreshTokenInput): Promise<RefreshTokenOutput> {
    const tokens = await this.authClient.refreshAccessToken(input.refreshToken);
    return { tokens };
  }
}

export interface SignOutInput {
  accessToken: string;
}

@Injectable()
export class SignOutUseCase implements UseCase<SignOutInput, void> {
  constructor(
    @Inject('SupabaseAuthClient')
    private readonly authClient: SupabaseAuthClient,
  ) {}

  async execute(): Promise<void> {
    await this.authClient.signOut();
  }
}

export interface GetCurrentUserInput {
  accessToken: string;
}

export interface GetCurrentUserOutput {
  user: User;
}

@Injectable()
export class GetCurrentUserUseCase implements UseCase<
  GetCurrentUserInput,
  GetCurrentUserOutput
> {
  constructor(
    @Inject('SupabaseAuthClient')
    private readonly authClient: SupabaseAuthClient,
  ) {}

  async execute(input: GetCurrentUserInput): Promise<GetCurrentUserOutput> {
    const user = await this.authClient.getUser(input.accessToken);

    if (!user) {
      throw new Error('Invalid or expired token');
    }

    return { user };
  }
}

export interface UpdateUserRoleInput {
  userId: string;
  role: UserRole;
}

@Injectable()
export class UpdateUserRoleUseCase implements UseCase<
  UpdateUserRoleInput,
  void
> {
  constructor(
    @Inject('SupabaseAuthClient')
    private readonly authClient: SupabaseAuthClient,
  ) {}

  async execute(input: UpdateUserRoleInput): Promise<void> {
    await this.authClient.updateUserRole(input.userId, input.role);
  }
}
