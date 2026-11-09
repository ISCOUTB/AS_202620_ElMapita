import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AuthController } from './auth.controller';
import {
  SignInUseCase,
  SignUpUseCase,
  RefreshTokenUseCase,
  SignOutUseCase,
  GetCurrentUserUseCase,
  UpdateUserRoleUseCase,
} from '../application/use-cases';
import { PoisController } from '../../pois/interfaces/pois.controller';
import {
  GetPoiUseCase,
  ListPoisByFloorUseCase,
  CreatePoiUseCase,
} from '../../pois/application/use-cases';

const USER_ID = '3f2b8c1e-5a4d-4e0a-9b6f-1c2d3e4f5a6b';
const OTHER_ID = '9a8b7c6d-5e4f-4a3b-8c2d-1e0f9a8b7c6d';

const USERS: Record<string, { id: string; role: string }> = {
  'tok-estudiante': { id: 'u-est', role: 'estudiante' },
  'tok-staff': { id: 'u-staff', role: 'admin_staff' },
  'tok-admin': { id: 'u-admin', role: 'admin_utb' },
};

describe('Endpoints protegidos (S11, T-01/T-03)', () => {
  let app: INestApplication<App>;
  const updateRole = jest.fn().mockResolvedValue(undefined);
  const createPoi = jest.fn().mockResolvedValue({ poi: { id: 'p1' } });

  beforeAll(async () => {
    const unused = {};
    const moduleRef = await Test.createTestingModule({
      controllers: [AuthController, PoisController],
      providers: [
        { provide: SignInUseCase, useValue: unused },
        { provide: SignUpUseCase, useValue: unused },
        { provide: RefreshTokenUseCase, useValue: unused },
        { provide: SignOutUseCase, useValue: unused },
        { provide: GetCurrentUserUseCase, useValue: unused },
        { provide: UpdateUserRoleUseCase, useValue: { execute: updateRole } },
        { provide: GetPoiUseCase, useValue: unused },
        { provide: ListPoisByFloorUseCase, useValue: unused },
        { provide: CreatePoiUseCase, useValue: { execute: createPoi } },
        {
          provide: 'SupabaseAuthClient',
          useValue: {
            getUser: (token: string) => Promise.resolve(USERS[token] ?? null),
          },
        },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterAll(() => app.close());
  beforeEach(() => jest.clearAllMocks());

  describe('POST /v1/auth/users/:userId/role', () => {
    const url = `/v1/auth/users/${USER_ID}/role`;

    it('401 sin token y no ejecuta el caso de uso', async () => {
      await request(app.getHttpServer())
        .post(url)
        .send({ role: 'admin_utb' })
        .expect(401);
      expect(updateRole).not.toHaveBeenCalled();
    });

    it('401 con un token que Supabase no reconoce', async () => {
      await request(app.getHttpServer())
        .post(url)
        .set('Authorization', 'Bearer falso')
        .send({ role: 'admin_utb' })
        .expect(401);
      expect(updateRole).not.toHaveBeenCalled();
    });

    it('403 a un usuario con rol estudiante', async () => {
      await request(app.getHttpServer())
        .post(url)
        .set('Authorization', 'Bearer tok-estudiante')
        .send({ role: 'admin_utb' })
        .expect(403);
      expect(updateRole).not.toHaveBeenCalled();
    });

    it('403 a admin_staff: el cambio de roles es solo de admin_utb', async () => {
      await request(app.getHttpServer())
        .post(url)
        .set('Authorization', 'Bearer tok-staff')
        .send({ role: 'admin_utb' })
        .expect(403);
      expect(updateRole).not.toHaveBeenCalled();
    });

    it('200 a admin_utb y usa el userId de la ruta, no el del cuerpo', async () => {
      await request(app.getHttpServer())
        .post(url)
        .set('Authorization', 'Bearer tok-admin')
        .send({ userId: OTHER_ID, role: 'docente' })
        .expect(201);
      expect(updateRole).toHaveBeenCalledWith({
        userId: USER_ID,
        role: 'docente',
      });
    });

    it('400 si el userId de la ruta no es un UUID', async () => {
      await request(app.getHttpServer())
        .post('/v1/auth/users/no-es-uuid/role')
        .set('Authorization', 'Bearer tok-admin')
        .send({ role: 'docente' })
        .expect(400);
      expect(updateRole).not.toHaveBeenCalled();
    });
  });

  describe('POST /v1/pois', () => {
    const body = { nombre: 'Laboratorio' };

    it('401 sin token y no crea el POI', async () => {
      await request(app.getHttpServer())
        .post('/v1/pois')
        .send(body)
        .expect(401);
      expect(createPoi).not.toHaveBeenCalled();
    });

    it('403 a un usuario con rol estudiante', async () => {
      await request(app.getHttpServer())
        .post('/v1/pois')
        .set('Authorization', 'Bearer tok-estudiante')
        .send(body)
        .expect(403);
      expect(createPoi).not.toHaveBeenCalled();
    });

    it('201 a admin_staff', async () => {
      await request(app.getHttpServer())
        .post('/v1/pois')
        .set('Authorization', 'Bearer tok-staff')
        .send(body)
        .expect(201);
      expect(createPoi).toHaveBeenCalledWith(body);
    });

    it('con Idempotency-Key pasa la llave y el usuario autenticado al caso de uso', async () => {
      await request(app.getHttpServer())
        .post('/v1/pois')
        .set('Authorization', 'Bearer tok-staff')
        .set('Idempotency-Key', 'k-123')
        .send(body)
        .expect(201);
      expect(createPoi).toHaveBeenCalledWith(body, {
        idempotencyKey: 'k-123',
        actorId: 'u-staff',
      });
    });

    it('400 con una Idempotency-Key de más de 128 caracteres y no crea el POI', async () => {
      await request(app.getHttpServer())
        .post('/v1/pois')
        .set('Authorization', 'Bearer tok-staff')
        .set('Idempotency-Key', 'x'.repeat(129))
        .send(body)
        .expect(400);
      expect(createPoi).not.toHaveBeenCalled();
    });
  });
});
