import {
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard, Roles } from './auth.guard';
import type { User, UserRole } from '../domain';

function contextFor(
  authorization: string | undefined,
  roles: UserRole[] | undefined,
): ExecutionContext {
  const handler = () => undefined;
  @Roles(...(roles ?? []))
  class Handler {}
  const request: { headers: Record<string, string>; user?: User } = {
    headers: authorization ? { authorization } : {},
  };
  return {
    switchToHttp: () => ({ getRequest: () => request }),
    getHandler: () => handler,
    getClass: () => Handler,
  } as unknown as ExecutionContext;
}

function guardWith(user: Partial<User> | null) {
  const authClient = { getUser: jest.fn().mockResolvedValue(user) };
  return {
    guard: new AuthGuard(authClient as never, new Reflector()),
    authClient,
  };
}

describe('AuthGuard', () => {
  it('rechaza con 401 una petición sin cabecera Authorization', async () => {
    const { guard, authClient } = guardWith(null);
    await expect(
      guard.canActivate(contextFor(undefined, ['admin_utb'])),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(authClient.getUser).not.toHaveBeenCalled();
  });

  it('rechaza con 401 un token que Supabase no reconoce', async () => {
    const { guard } = guardWith(null);
    await expect(
      guard.canActivate(contextFor('Bearer falso', ['admin_utb'])),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('rechaza con 403 a un usuario autenticado sin el rol requerido', async () => {
    const { guard } = guardWith({ id: 'u1' as never, role: 'estudiante' });
    await expect(
      guard.canActivate(contextFor('Bearer ok', ['admin_utb'])),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('permite al usuario con uno de los roles requeridos y lo deja en la petición', async () => {
    const { guard } = guardWith({ id: 'u1' as never, role: 'admin_staff' });
    const ctx = contextFor('Bearer ok', ['admin_staff', 'admin_utb']);
    await expect(guard.canActivate(ctx)).resolves.toBe(true);
    const req = ctx.switchToHttp().getRequest<{ user?: User }>();
    expect(req.user?.role).toBe('admin_staff');
  });

  it('sin roles declarados solo exige estar autenticado', async () => {
    const { guard } = guardWith({ id: 'u1' as never, role: 'estudiante' });
    await expect(
      guard.canActivate(contextFor('Bearer ok', undefined)),
    ).resolves.toBe(true);
  });
});
