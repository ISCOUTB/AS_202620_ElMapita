import { readFileSync } from 'fs';
import { resolve } from 'path';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { parse } from 'yaml';
import Ajv2020 from 'ajv/dist/2020';
import addFormats from 'ajv-formats';
import { AppModule } from '../../src/app.module';
import type {
  Building,
  BuildingId,
  BuildingRepository,
  Floor,
  FloorId,
  FloorRepository,
  Model3DStorage,
  ModelVersion,
} from '../../src/modules/mapas/domain';
import type { Poi, PoiId, PoiRepository } from '../../src/modules/pois/domain';
import type {
  AuthTokens,
  SupabaseAuthClient,
  User,
} from '../../src/modules/auth/domain';

/**
 * Prueba de contrato (capa 3 — runtime): levanta la aplicación completa con
 * el MISMO bootstrap que src/main.ts (setGlobalPrefix + ValidationPipe) y
 * verifica, ruta por ruta, que docs/api/openapi.v1.yaml describe lo que el
 * servidor realmente expone. Los puertos hacia Supabase (DEC-02) se
 * sustituyen por fakes en memoria: no requiere credenciales reales.
 *
 * RSK-04 (arc42) — deriva de prefijo de ruta (/api/api/v1 y /api/health) —
 * se cerró corrigiendo los 4 controladores y excluyendo 'health' del
 * prefijo global (ver docs/adr/0003-contrato-openapi-versionado.md,
 * sección "Cierre de RSK-04"). Esta prueba corre en verde por eso mismo;
 * el run que la capturó en rojo antes del fix queda como evidencia
 * histórica citada en el ADR.
 */

const BUILDING_ID = '11111111-1111-1111-1111-111111111111' as BuildingId;
const FLOOR_ID = '22222222-2222-2222-2222-222222222222' as FloorId;
const POI_ID = '33333333-3333-3333-3333-333333333333' as PoiId;

const fakeBuilding: Building = {
  id: BUILDING_ID,
  nombre: 'Edificio de Ingenierías',
  codigo: 'ING',
  geometria: {
    type: 'Polygon',
    coordinates: [
      [
        [0, 0],
        [0, 1],
        [1, 1],
        [0, 0],
      ],
    ],
  },
  pisos: [FLOOR_ID],
  versionModelo3D: 'v1' as ModelVersion,
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  updatedAt: new Date('2026-01-01T00:00:00.000Z'),
};

const fakeFloor: Floor = {
  id: FLOOR_ID,
  edificioId: BUILDING_ID,
  numero: 1,
  nombre: 'Piso 1',
  modelo3DUrl: 'https://storage.example/model.glb',
  modelo3DVersion: 'v1' as ModelVersion,
  alturaMetros: 3.5,
  pois: [POI_ID],
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  updatedAt: new Date('2026-01-01T00:00:00.000Z'),
};

const fakePoi: Poi = {
  id: POI_ID,
  pisoId: FLOOR_ID,
  tipo: 'salon',
  nombre: 'Salón 101',
  geometria: { type: 'Point', coordinates: [0.5, 0.5] },
  metadatos: { capacidad: 40 },
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  updatedAt: new Date('2026-01-01T00:00:00.000Z'),
};

const fakeUser: User = {
  id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' as unknown as User['id'],
  email: 'estudiante@utb.edu.co',
  role: 'estudiante',
  nombre: 'Estudiante de prueba',
  activo: true,
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  updatedAt: new Date('2026-01-01T00:00:00.000Z'),
};

const fakeTokens: AuthTokens = {
  accessToken: 'fake-access-token',
  refreshToken: 'fake-refresh-token',
  expiresIn: 3600,
};

class FakeBuildingRepository implements BuildingRepository {
  findById(id: BuildingId) {
    return Promise.resolve(id === BUILDING_ID ? fakeBuilding : null);
  }
  findAll() {
    return Promise.resolve([fakeBuilding]);
  }
  findByCodigo() {
    return Promise.resolve(fakeBuilding);
  }
}

class FakeFloorRepository implements FloorRepository {
  findById(id: FloorId) {
    return Promise.resolve(id === FLOOR_ID ? fakeFloor : null);
  }
  findByBuildingId() {
    return Promise.resolve([fakeFloor]);
  }
}

class FakeModel3DStorage implements Model3DStorage {
  getSignedUrl() {
    return Promise.resolve('https://storage.example/signed-model.glb');
  }
  uploadModel() {
    return Promise.resolve('https://storage.example/uploaded-model.glb');
  }
}

class FakePoiRepository implements PoiRepository {
  findById(id: PoiId) {
    return Promise.resolve(id === POI_ID ? fakePoi : null);
  }
  findByFloorId() {
    return Promise.resolve([fakePoi]);
  }
  findByTipo() {
    return Promise.resolve([fakePoi]);
  }
  save(poi: Poi) {
    return Promise.resolve(poi);
  }
}

class FakeSupabaseAuthClient implements SupabaseAuthClient {
  signInWithEmail() {
    return Promise.resolve(fakeTokens);
  }
  signUpWithEmail() {
    return Promise.resolve(fakeTokens);
  }
  refreshAccessToken() {
    return Promise.resolve(fakeTokens);
  }
  signOut() {
    return Promise.resolve();
  }
  getUser() {
    return Promise.resolve(fakeUser);
  }
  updateUserRole() {
    return Promise.resolve();
  }
}

interface OpenApiOperation {
  method: string;
  path: string;
  expectedStatuses: number[];
}

function loadContractOperations(): OpenApiOperation[] {
  const contractPath = resolve(__dirname, '../../../docs/api/openapi.v1.yaml');
  const doc = parse(readFileSync(contractPath, 'utf-8')) as {
    paths: Record<
      string,
      Record<string, { responses: Record<string, unknown> }>
    >;
  };

  const operations: OpenApiOperation[] = [];
  for (const [path, methods] of Object.entries(doc.paths)) {
    for (const [method, operation] of Object.entries(methods)) {
      if (!['get', 'post', 'put', 'patch', 'delete'].includes(method)) continue;
      const expectedStatuses = Object.keys(operation.responses)
        .map(Number)
        .filter((s) => !Number.isNaN(s));
      operations.push({ method: method.toUpperCase(), path, expectedStatuses });
    }
  }
  return operations;
}

/** Rellena los parámetros de ruta {param} con UUIDs conocidos por los fakes. */
function resolveSamplePath(path: string): string {
  return path
    .replace('{buildingId}', BUILDING_ID)
    .replace('{floorId}', FLOOR_ID)
    .replace('{poiId}', POI_ID)
    .replace('{userId}', fakeUser.id as unknown as string);
}

/**
 * Cuerpo de petición válido por ruta, para las operaciones que lo requieren.
 * Los fakes de auth/ubicación ignoran su input y devuelven datos fijos, pero
 * CreatePoiUseCase sí construye la entidad a partir del body real — sin esto,
 * un body vacío produce un Poi incompleto que no cumple el schema.
 */
function sampleRequestBody(path: string): Record<string, unknown> {
  const bodies: Record<string, Record<string, unknown>> = {
    '/api/v1/auth/signin': {
      email: 'estudiante@utb.edu.co',
      password: 'clave-segura',
    },
    '/api/v1/auth/signup': {
      email: 'nuevo@utb.edu.co',
      password: 'clave-segura',
      nombre: 'Nuevo Estudiante',
    },
    '/api/v1/auth/refresh': { refreshToken: 'fake-refresh-token' },
    '/api/v1/auth/users/{userId}/role': {
      userId: fakeUser.id,
      role: 'docente',
    },
    '/api/v1/pois': {
      pisoId: FLOOR_ID,
      tipo: 'salon',
      nombre: 'Salón 102',
      geometria: { type: 'Point', coordinates: [0.6, 0.6] },
      metadatos: { capacidad: 30 },
    },
    '/api/v1/location/manual': {
      buildingId: BUILDING_ID,
      floor: 1,
      x: 10,
      y: 20,
    },
  };
  return bodies[path] ?? {};
}

describe('Contrato OpenAPI v1 (docs/api/openapi.v1.yaml) vs runtime real', () => {
  let app: INestApplication<App>;
  let ajv: Ajv2020;
  let contractDoc: Record<string, unknown>;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider('BuildingRepository')
      .useClass(FakeBuildingRepository)
      .overrideProvider('FloorRepository')
      .useClass(FakeFloorRepository)
      .overrideProvider('Model3DStorage')
      .useClass(FakeModel3DStorage)
      .overrideProvider('PoiRepository')
      .useClass(FakePoiRepository)
      .overrideProvider('SupabaseAuthClient')
      .useClass(FakeSupabaseAuthClient)
      .compile();

    app = moduleFixture.createNestApplication();
    // Mismo bootstrap que src/main.ts — si diverge de aquí, esta prueba
    // deja de reflejar lo que se despliega realmente (ver comentario arriba).
    app.setGlobalPrefix('api', { exclude: ['health', 'metrics'] });
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: { enableImplicitConversion: true },
      }),
    );
    await app.init();

    ajv = new Ajv2020({ strict: false, allErrors: true });
    addFormats(ajv);

    const contractPath = resolve(
      __dirname,
      '../../../docs/api/openapi.v1.yaml',
    );
    contractDoc = parse(readFileSync(contractPath, 'utf-8')) as Record<
      string,
      unknown
    >;
  });

  afterAll(async () => {
    await app.close();
  });

  const operations = loadContractOperations();

  it.each(operations)(
    '$method $path existe en el servidor (no 404)',
    async ({ method, path, expectedStatuses }) => {
      const samplePath = resolveSamplePath(path);
      const req = request(app.getHttpServer())[
        method.toLowerCase() as 'get' | 'post'
      ](samplePath);

      const response = await req.send(sampleRequestBody(path));

      expect(response.status).not.toBe(404);

      if (expectedStatuses.includes(response.status)) {
        const operationSchema = (
          (contractDoc.paths as Record<string, Record<string, unknown>>)[path][
            method.toLowerCase()
          ] as {
            responses: Record<
              string,
              {
                content?: {
                  'application/json'?: { schema: { $ref?: string } };
                };
              }
            >;
          }
        ).responses[String(response.status)]?.content?.['application/json']
          ?.schema;

        if (operationSchema?.$ref) {
          // Compila un schema autocontenido: incluye components.schemas del
          // contrato como hermano de $ref, para que '#/components/schemas/X'
          // resuelva contra ESTE documento (sin registrar/cachear estado
          // compartido entre pruebas, que resultó frágil con addSchema).
          const validate = ajv.compile({
            components: contractDoc.components,
            $ref: operationSchema.$ref,
          });
          const valid = validate(response.body);
          if (!valid) {
            throw new Error(
              `Respuesta no cumple el schema del contrato para ${method} ${path}: ${JSON.stringify(
                validate.errors,
              )}`,
            );
          }
        }
      }
    },
    // GET /health golpea Supabase real (no tiene puerto fakeable, ver
    // health.controller.ts); con credenciales dummy la conexión falla más
    // lento que el timeout por defecto de Jest.
    15000,
  );
});
