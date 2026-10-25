import { NotFoundException } from '@nestjs/common';
import { GetFloorModelUseCase } from './use-cases';
import { InMemoryTtlCache } from '../../../shared/cache/in-memory-ttl-cache';
import type {
  BuildingId,
  Floor,
  FloorId,
  FloorRepository,
  Model3DStorage,
  ModelVersion,
} from '../domain';

const floor = {
  id: 'f1' as FloorId,
  edificioId: 'b1' as BuildingId,
  modelo3DVersion: 'v1' as ModelVersion,
} as Floor;

describe('GetFloorModelUseCase', () => {
  it('responde 404 (no 500) cuando el piso no existe', async () => {
    const floors = {
      findById: () => Promise.resolve(null),
    } as unknown as FloorRepository;
    const storage = {} as Model3DStorage;
    const uc = new GetFloorModelUseCase(
      floors,
      storage,
      new InMemoryTtlCache(),
    );
    await expect(
      uc.execute({ floorId: 'x' as FloorId }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('la segunda lectura sale de la caché: ni piso ni URL firmada se piden de nuevo', async () => {
    const findById = jest.fn().mockResolvedValue(floor);
    const getSignedUrl = jest.fn().mockResolvedValue('https://signed/url');
    const uc = new GetFloorModelUseCase(
      { findById } as unknown as FloorRepository,
      { getSignedUrl } as unknown as Model3DStorage,
      new InMemoryTtlCache(),
    );
    await uc.execute({ floorId: floor.id });
    const second = await uc.execute({ floorId: floor.id });
    expect(second.model3DUrl).toBe('https://signed/url');
    expect(findById).toHaveBeenCalledTimes(1);
    expect(getSignedUrl).toHaveBeenCalledTimes(1);
  });

  it('un piso inexistente no se cachea: si aparece después, se ve', async () => {
    const findById = jest
      .fn()
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(floor);
    const uc = new GetFloorModelUseCase(
      { findById } as unknown as FloorRepository,
      {
        getSignedUrl: () => Promise.resolve('u'),
      } as unknown as Model3DStorage,
      new InMemoryTtlCache(),
    );
    await expect(uc.execute({ floorId: floor.id })).rejects.toBeInstanceOf(
      NotFoundException,
    );
    await expect(uc.execute({ floorId: floor.id })).resolves.toBeDefined();
  });
});
