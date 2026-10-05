import { NotFoundException } from '@nestjs/common';
import { GetFloorModelUseCase } from './use-cases';
import type { FloorId, FloorRepository, Model3DStorage } from '../domain';

describe('GetFloorModelUseCase', () => {
  it('responde 404 (no 500) cuando el piso no existe', async () => {
    const floors = {
      findById: () => Promise.resolve(null),
    } as unknown as FloorRepository;
    const storage = {} as Model3DStorage;
    const uc = new GetFloorModelUseCase(floors, storage);
    await expect(
      uc.execute({ floorId: 'x' as FloorId }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
