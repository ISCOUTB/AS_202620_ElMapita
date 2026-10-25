import { NotFoundException } from '@nestjs/common';
import {
  CreatePoiUseCase,
  GetPoiUseCase,
  ListPoisByFloorUseCase,
} from './use-cases';
import { InMemoryTtlCache } from '../../../shared/cache/in-memory-ttl-cache';
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
    const create = new CreatePoiUseCase(asRepo, cache);

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
