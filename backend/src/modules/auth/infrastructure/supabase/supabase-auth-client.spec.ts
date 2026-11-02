import type { ConfigService } from '@nestjs/config';
import { SupabaseAuthClientImpl } from './supabase-auth-client';
import { getSupabaseClient } from '../../../../shared/supabase/client';

jest.mock('../../../../shared/supabase/client');

const getUser = jest.fn();
const updateUserById = jest.fn();

function supabaseUser(overrides: Record<string, unknown>) {
  return {
    id: 'u1',
    email: 'a@utb.edu.co',
    created_at: '2026-01-01T00:00:00Z',
    user_metadata: {},
    app_metadata: {},
    ...overrides,
  };
}

describe('SupabaseAuthClientImpl: fuente del rol (S11, T-02)', () => {
  const client = new SupabaseAuthClientImpl({} as ConfigService);

  beforeEach(() => {
    jest.resetAllMocks();
    (getSupabaseClient as jest.Mock).mockReturnValue({
      auth: { getUser, admin: { updateUserById } },
    });
  });

  it('lee el rol de app_metadata', async () => {
    getUser.mockResolvedValue({
      data: { user: supabaseUser({ app_metadata: { role: 'admin_utb' } }) },
      error: null,
    });
    await expect(client.getUser('t')).resolves.toMatchObject({
      role: 'admin_utb',
    });
  });

  it('ignora un rol puesto por el propio usuario en user_metadata', async () => {
    getUser.mockResolvedValue({
      data: { user: supabaseUser({ user_metadata: { role: 'admin_utb' } }) },
      error: null,
    });
    await expect(client.getUser('t')).resolves.toMatchObject({
      role: 'estudiante',
    });
  });

  it('el nombre sigue saliendo de user_metadata', async () => {
    getUser.mockResolvedValue({
      data: { user: supabaseUser({ user_metadata: { nombre: 'Ana' } }) },
      error: null,
    });
    await expect(client.getUser('t')).resolves.toMatchObject({ nombre: 'Ana' });
  });

  it('escribe el rol en app_metadata y nunca en user_metadata', async () => {
    updateUserById.mockResolvedValue({ error: null });
    await client.updateUserRole('u1', 'docente');
    expect(updateUserById).toHaveBeenCalledWith('u1', {
      app_metadata: { role: 'docente' },
    });
  });
});
