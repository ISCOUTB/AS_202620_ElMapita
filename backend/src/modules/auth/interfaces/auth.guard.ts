import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Inject,
  Injectable,
  SetMetadata,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import type { SupabaseAuthClient, User, UserRole } from '../domain';

const ROLES_KEY = 'roles';

/** Roles autorizados para el handler; sin roles basta con estar autenticado. */
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);

/**
 * Valida el Bearer token contra Supabase y comprueba el rol (S11, T-01/T-03).
 * Deja el usuario en `request.user` para auditoría.
 */
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    @Inject('SupabaseAuthClient')
    private readonly authClient: SupabaseAuthClient,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context
      .switchToHttp()
      .getRequest<Request & { user?: User }>();

    const header = request.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Token requerido');
    }

    const user = await this.authClient.getUser(header.substring(7));
    if (!user) {
      throw new UnauthorizedException('Token inválido o expirado');
    }

    const roles =
      this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
        context.getHandler(),
        context.getClass(),
      ]) ?? [];
    if (roles.length > 0 && !roles.includes(user.role)) {
      throw new ForbiddenException('No autorizado');
    }

    request.user = user;
    return true;
  }
}
