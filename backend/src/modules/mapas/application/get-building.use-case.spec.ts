import { GetBuildingUseCase } from './use-cases';
import { InMemoryTtlCache } from '../../../shared/cache/in-memory-ttl-cache';
import type {
  Building,
  BuildingId,
  BuildingRepository,
  Floor,
  FloorRepository,
  Model3DStorage,
  ModelVersion,
} from '../domain';

const id = 'b1' as BuildingId;

/**
 * Pinea la garantía documentada en docs/datos/consistencia-operaciones.md
 * (fila 2): el detalle de edificio son lecturas independientes, sin
 * transacción ni snapshot entre ellas.
 */
describe('GetBuildingUseCase: sin snapshot entre lecturas', () => {
  it('una escritura entre las dos lecturas produce una lectura rasgada, pero la URL firmada sigue la versión leída del edificio', async () => {
    // Estado del almacén. El edificio se lee en v1; antes de leer los pisos
    // alguien publica v2 (edificio y pisos pasan a v2).
    let stored = { version: 'v1', floorsLabel: 'pisos-v1' };

    const buildings = {
      findById: jest.fn(() => {
        const snapshot = {
          id,
          versionModelo3D: stored.version as ModelVersion,
        } as Building;
        stored = { version: 'v2', floorsLabel: 'pisos-v2' };
        return Promise.resolve(snapshot);
      }),
    } as unknown as BuildingRepository;
    const floorsRepo = {
      findByBuildingId: jest.fn(() =>
        Promise.resolve([{ nombre: stored.floorsLabel }] as unknown as Floor[]),
      ),
    } as unknown as FloorRepository;
    const getSignedUrl = jest.fn((_b: BuildingId, v: ModelVersion) =>
      Promise.resolve(`https://signed/${v}.glb`),
    );

    const uc = new GetBuildingUseCase(
      buildings,
      floorsRepo,
      { getSignedUrl } as unknown as Model3DStorage,
      new InMemoryTtlCache(),
    );
    const out = await uc.execute({ buildingId: id });

    // Edificio en v1, pisos ya en v2: no hay snapshot entre lecturas.
    expect(out.building.versionModelo3D).toBe('v1');
    expect(out.floors[0]).toMatchObject({ nombre: 'pisos-v2' });
    // La mitigación documentada: la URL corresponde a la versión del edificio
    // leído, así que apunta a un archivo coherente con él.
    expect(out.model3DUrl).toBe('https://signed/v1.glb');
    expect(getSignedUrl).toHaveBeenCalledWith(id, 'v1');
  });

  it('cada pieza se pide una sola vez y, en la segunda lectura, sale de la caché', async () => {
    const findById = jest.fn().mockResolvedValue({
      id,
      versionModelo3D: 'v1',
    });
    const findByBuildingId = jest.fn().mockResolvedValue([] as Floor[]);
    const getSignedUrl = jest.fn().mockResolvedValue('https://signed/v1.glb');

    const uc = new GetBuildingUseCase(
      { findById } as unknown as BuildingRepository,
      { findByBuildingId } as unknown as FloorRepository,
      { getSignedUrl } as unknown as Model3DStorage,
      new InMemoryTtlCache(),
    );
    await uc.execute({ buildingId: id });
    await uc.execute({ buildingId: id });

    expect(findById).toHaveBeenCalledTimes(1);
    expect(findByBuildingId).toHaveBeenCalledTimes(1);
    expect(getSignedUrl).toHaveBeenCalledTimes(1);
  });
});
