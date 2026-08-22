import { Injectable } from '@nestjs/common';
import { getSupabaseClient } from '../../../../shared/supabase/client';
import { ConfigService } from '@nestjs/config';
import { SupabaseAuthClient, AuthTokens, User, UserId, UserRole } from '../../domain';

@Injectable()
export class SupabaseAuthClientImpl implements SupabaseAuthClient {
  constructor(private readonly configService: ConfigService) {}

  private get client() {
    return getSupabaseClient(this.configService);
  }

  async signInWithEmail(email: string, password: string): Promise<AuthTokens> {
    const { data, error } = await this.client.auth.signInWithPassword({
      email,
      password,
    });

    if (error || !data.session) {
      throw new Error(`Sign in failed: ${error?.message}`);
    }

    return {
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresIn: data.session.expires_in,
    };
  }

  async signUpWithEmail(email: string, password: string, metadata: { nombre: string }): Promise<AuthTokens> {
    const { data, error } = await this.client.auth.signUp({
      email,
      password,
      options: {
        data: metadata,
      },
    });

    if (error || !data.session) {
      throw new Error(`Sign up failed: ${error?.message}`);
    }

    return {
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresIn: data.session.expires_in,
    };
  }

  async refreshAccessToken(refreshToken: string): Promise<AuthTokens> {
    const { data, error } = await this.client.auth.refreshSession({
      refresh_token: refreshToken,
    });

    if (error || !data.session) {
      throw new Error(`Token refresh failed: ${error?.message}`);
    }

    return {
      accessToken: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresIn: data.session.expires_in,
    };
  }

  async signOut(): Promise<void> {
    await this.client.auth.signOut();
  }

  async getUser(accessToken: string): Promise<User | null> {
    const { data, error } = await this.client.auth.getUser(accessToken);

    if (error || !data.user) {
      return null;
    }

    return this.mapToUser(data.user);
  }

  async updateUserRole(userId: string, role: UserRole): Promise<void> {
    const { error } = await this.client.auth.admin.updateUserById(userId, {
      user_metadata: { role },
    });

    if (error) {
      throw new Error(`Failed to update user role: ${error.message}`);
    }
  }

  private mapToUser(supabaseUser: any): User {
    return {
      id: supabaseUser.id as UserId,
      email: supabaseUser.email!,
      role: (supabaseUser.user_metadata?.role as UserRole) || 'estudiante',
      nombre: supabaseUser.user_metadata?.nombre || supabaseUser.email!,
      activo: true,
      createdAt: new Date(supabaseUser.created_at),
      updatedAt: new Date(supabaseUser.updated_at || supabaseUser.created_at),
    };
  }
}