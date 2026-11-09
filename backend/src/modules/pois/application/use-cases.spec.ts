import { ConflictException, NotFoundException } from '@nestjs/common';
import {
  CreatePoiUseCase,
  GetPoiUseCase,
  ListPoisByFloorUseCase,
} from './use-cases';
import { InMemoryTtlCache } from '../../../shared/cache/in-memory-ttl-cache';
import { InMemoryMessageBus } from '../../../shared/messaging/in-memory-message-bus';
import type {
  FloorId,
  GeoPoint,
  Poi,
  PoiId,
  PoiMetadatos,
  PoiRepository,
  PoiType,
} from '../domain';

const pisoId = 'p1' as FloorId;

function fakeRepo() {
  const store: Poi[] = [];
  const repo = {
    findById: jest.fn((id: PoiId) =>
      Promise.resolve(store.find((p) => p.id === id) ?? null),
    ),
    findByFloorId: jest.fn((id: FloorId) =>
      Promise.resolve(store.filter((p) => p.pisoId === id)),
    ),
    save: jest.fn((poi: Poi) => {
      store.push(poi);
      return Promise.resolve(poi);
    }),
  };
  return { repo, asRepo: repo as unknown as PoiRepository };
}

const input = {
  pisoId,
  tipo: 'AULA' as unknown as PoiType,
  nombre: 'Aula 101',
  geometria: { type: 'Point', coordinates: [0, 0] } as unknown as GeoPoint,
  metadatos: {} as PoiMetadatos,
};

describe('POIs con caché', () => {
  it('GetPoi responde 404 (no 500) cuando el POI no existe', async () => {
    const { asRepo } = fakeRepo();
    const uc = new GetPoiUseCase(asRepo, new InMemoryTtlCache());
    await expect(uc.execute({ poiId: 'x' as PoiId })).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('ListPoisByFloor: la segunda llamada no toca el repositorio', async () => {
    const { repo, asRepo } = fakeRepo();
    const uc = new ListPoisByFloorUseCase(asRepo, new InMemoryTtlCache());
    await uc.execute({ floorId: pisoId });
    await uc.execute({ floorId: pisoId });
    expect(repo.findByFloorId).toHaveBeenCalledTimes(1);
  });

  it('CreatePoi invalida la lista del piso: la lectura siguiente ve el POI nuevo (read-your-writes)', async () => {
    const { asRepo } = fakeRepo();
    const cache = new InMemoryTtlCache();
    const list = new ListPoisByFloorUseCase(asRepo, cache);
    const create = new CreatePoiUseCase(
      asRepo,
      cache,
      new InMemoryMessageBus(),
    );

    expect((await list.execute({ floorId: pisoId })).pois).toHaveLength(0);
    await create.execute(input);
    expect((await list.execute({ floorId: pisoId })).pois).toHaveLength(1);
  });

  it('un error del repositorio no se cachea como lista vacía', async () => {
    const { repo, asRepo } = fakeRepo();
    repo.findByFloorId.mockRejectedValueOnce(new Error('503'));
    const uc = new ListPoisByFloorUseCase(asRepo, new InMemoryTtlCache());
    await expect(uc.execute({ floorId: pisoId })).rejects.toThrow('503');
    await expect(uc.execute({ floorId: pisoId })).resolves.toEqual({
      pois: [],
    });
  });
});

describe('CreatePoi con llave de idempotencia', () => {
  function setup() {
    const { repo, asRepo } = fakeRepo();
    const bus = new InMemoryMessageBus();
    const publish = jest.spyOn(bus, 'publish');
    const create = new CreatePoiUseCase(asRepo, new InMemoryTtlCache(), bus);
    return { repo, publish, create };
  }
  const key = { idempotencyKey: 'k-1', actorId: 'u-staff' };

  it('sin llave conserva el comportamiento previo: cada petición crea un POI', async () => {
    const { repo, create } = setup();
    const a = await create.execute(input);
    const b = await create.execute(input);
    expect(a.poi.id).not.toBe(b.poi.id);
    expect(repo.save).toHaveBeenCalledTimes(2);
  });

  it('el reintento con la misma llave devuelve el mismo POI sin duplicar ni republicar', async () => {
    const { repo, publish, create } = setup();
    const first = await create.execute(input, key);
    const retry = await create.execute(input, key);
    expect(retry.poi.id).toBe(first.poi.id);
    expect(repo.save).toHaveBeenCalledTimes(1);
    expect(publish).toHaveBeenCalledTimes(1);
  });

  it('la misma llave de otro usuario crea otro POI', async () => {
    const { create } = setup();
    const a = await create.execute(input, key);
    const b = await create.execute(input, { ...key, actorId: 'u-admin' });
    expect(b.poi.id).not.toBe(a.poi.id);
  });

  it('la misma llave con un cuerpo distinto responde 409 y no guarda', async () => {
    const { repo, create } = setup();
    await create.execute(input, key);
    await expect(
      create.execute({ ...input, nombre: 'Otra aula' }, key),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(repo.save).toHaveBeenCalledTimes(1);
  });

  it('el id derivado de la llave es un UUID estable', async () => {
    const { create } = setup();
    const { poi } = await create.execute(input, key);
    expect(poi.id).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    );
  });
});
