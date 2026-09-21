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
import type { Poi, PoiId, PoiRepository, PoiType } from '../../src/modules/pois/domain';
import type {
  AuthTokens,
  SupabaseAuthClient,
  User,
  UserRole,
} from '../../src/modules/auth/domain';

/**
 * Prueba de contrato (capa 3 — runtime): levanta la aplicación completa con
 * el MISMO bootstrap que src/main.ts (setGlobalPrefix + ValidationPipe) y
 * verifica, ruta por ruta, que docs/api/openapi.v1.yaml describe lo que el
 * servidor realmente expone. Los puertos hacia Supabase (DEC-02) se
 * sustituyen por fakes en memoria: no requiere credenciales reales.
 *
 * Hoy falla a propósito: documenta la deriva de prefijo (/api/api/v1 y
 * /api/health) descrita en docs/adr/0003-contrato-openapi-versionado.md
 * y RSK-04 (arc42). Ver ci.yml (job `contract`, continue-on-error) y
 * correcciones.md para el criterio de cierre de esta deuda.
 */

const BUILDING_ID = '11111111-1111-1111-1111-111111111111' as BuildingId;
const FLOOR_ID = '22222222-2222-2222-2222-222222222222' as FloorId;
const POI_ID = '33333333-3333-3333-3333-333333333333' as PoiId;

const fakeBuilding: Building = {
  id: BUILDING_ID,
  nombre: 'Edificio de Ingenierías',
  codigo: 'ING',
  geometria: { type: 'Polygon', coordinates: [[[0, 0], [0, 1], [1, 1], [0, 0]]] },
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
  tipo: 'salon' as PoiType,
  nombre: 'Salón 101',
  geometria: { type: 'Point', coordinates: [0.5, 0.5] },
  metadatos: { capacidad: 40 },
  createdAt: new Date('2026-01-01T00:00:00.000Z'),
  updatedAt: new Date('2026-01-01T00:00:00.000Z'),
};

const fakeUser: User = {
  id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' as unknown as User['id'],
  email: 'estudiante@utb.edu.co',
  role: 'estudiante' as UserRole,
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
  async findById(id: BuildingId) {
    return id === BUILDING_ID ? fakeBuilding : null;
  }
  async findAll() {
    return [fakeBuilding];
  }
  async findByCodigo() {
    return fakeBuilding;
  }
}

class FakeFloorRepository implements FloorRepository {
  async findById(id: FloorId) {
    return id === FLOOR_ID ? fakeFloor : null;
  }
  async findByBuildingId() {
    return [fakeFloor];
  }
}

class FakeModel3DStorage implements Model3DStorage {
  async getSignedUrl() {
    return 'https://storage.example/signed-model.glb';
  }
  async uploadModel() {
    return 'https://storage.example/uploaded-model.glb';
  }
}

class FakePoiRepository implements PoiRepository {
  async findById(id: PoiId) {
    return id === POI_ID ? fakePoi : null;
  }
  async findByFloorId() {
    return [fakePoi];
  }
  async findByTipo() {
    return [fakePoi];
  }
  async save(poi: Poi) {
    return poi;
  }
}

class FakeSupabaseAuthClient implements SupabaseAuthClient {
  async signInWithEmail() {
    return fakeTokens;
  }
  async signUpWithEmail() {
    return fakeTokens;
  }
  async refreshAccessToken() {
    return fakeTokens;
  }
  async signOut() {}
  async getUser() {
    return fakeUser;
  }
  async updateUserRole() {}
}

interface OpenApiOperation {
  method: string;
  path: string;
  expectedStatuses: number[];
}

function loadContractOperations(): OpenApiOperation[] {
  const contractPath = resolve(__dirname, '../../../docs/api/openapi.v1.yaml');
  const doc = parse(readFileSync(contractPath, 'utf-8')) as {
    paths: Record<string, Record<string, { responses: Record<string, unknown> }>>;
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
    app.setGlobalPrefix('api');
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

    const contractPath = resolve(__dirname, '../../../docs/api/openapi.v1.yaml');
    contractDoc = parse(readFileSync(contractPath, 'utf-8'));
    // Registra el documento completo bajo la clave 'contract' para poder
    // compilar validadores de sub-schemas por JSON pointer (p.ej.
    // 'contract#/components/schemas/Building') sin duplicar $refs a mano.
    ajv.addSchema(contractDoc, 'contract');
  });

  afterAll(async () => {
    await app.close();
  });

  const operations = loadContractOperations();

  it.each(operations)(
    '$method $path existe en el servidor (no 404)',
    async ({ method, path, expectedStatuses }) => {
      const samplePath = resolveSamplePath(path);
      const req = request(app.getHttpServer() as App)[method.toLowerCase() as 'get' | 'post']!(
        samplePath,
      );

      const response = await req.send({});

      expect(response.status).not.toBe(404);

      if (expectedStatuses.includes(response.status)) {
        const operationSchema = (
          (contractDoc.paths as Record<string, Record<string, unknown>>)[path][
            method.toLowerCase()
          ] as {
            responses: Record<string, { content?: { 'application/json'?: { schema: { $ref?: string } } } }>;
          }
        ).responses[String(response.status)]?.content?.['application/json']?.schema;

        if (operationSchema?.$ref) {
          // operationSchema.$ref es del tipo '#/components/schemas/X';
          // se resuelve contra el documento raíz registrado como 'contract'.
          const pointer = operationSchema.$ref.replace(/^#/, '');
          const validate = ajv.getSchema(`contract${pointer}`) ?? ajv.compile({ $ref: `contract${pointer}` });
          const valid = validate(response.body);
          expect(valid, JSON.stringify(validate.errors)).toBe(true);
        }
      }
    },
  );
});
