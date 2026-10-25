import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { UseCase } from '../../../shared/kernel';
import { CACHE_PORT, type CachePort } from '../../../shared/cache/cache.port';
import { getOrLoad } from '../../../shared/cache/get-or-load';
import type {
  Building,
  BuildingId,
  Floor,
  FloorId,
  BuildingRepository,
  FloorRepository,
  Model3DStorage,
  ModelVersion,
} from '../domain';

// TTL: los datos de mapas solo cambian por edición manual en Supabase, por eso
// la obsolescencia acotada por TTL es la única invalidación (docs/datos/diseno-cache.md).
const MAP_TTL_MS = 10 * 60 * 1000;
// Menor que la expiración de 1 h de la URL firmada, para no servir URLs a punto de caducar.
const SIGNED_URL_TTL_MS = 50 * 60 * 1000;

function signedModelUrl(
  cache: CachePort,
  storage: Model3DStorage,
  buildingId: BuildingId,
  version: ModelVersion,
): Promise<string> {
  // La versión va en la clave: un modelo nuevo nunca reutiliza una URL vieja.
  return getOrLoad(
    cache,
    `storage:signed:${buildingId}/${version}`,
    SIGNED_URL_TTL_MS,
    () => storage.getSignedUrl(buildingId, version),
  );
}

export interface GetBuildingInput {
  buildingId: BuildingId;
}

export interface GetBuildingOutput {
  building: Building;
  floors: Floor[];
  model3DUrl: string;
}

@Injectable()
export class GetBuildingUseCase implements UseCase<
  GetBuildingInput,
  GetBuildingOutput
> {
  constructor(
    @Inject('BuildingRepository')
    private readonly buildingRepository: BuildingRepository,
    @Inject('FloorRepository')
    private readonly floorRepository: FloorRepository,
    @Inject('Model3DStorage')
    private readonly modelStorage: Model3DStorage,
    @Inject(CACHE_PORT) private readonly cache: CachePort,
  ) {}

  async execute(input: GetBuildingInput): Promise<GetBuildingOutput> {
    const building = await getOrLoad(
      this.cache,
      `mapas:building:${input.buildingId}`,
      MAP_TTL_MS,
      () => this.buildingRepository.findById(input.buildingId),
    );
    if (!building) {
      throw new NotFoundException('Building not found');
    }

    const floors = await getOrLoad(
      this.cache,
      `mapas:floors:${input.buildingId}`,
      MAP_TTL_MS,
      () => this.floorRepository.findByBuildingId(input.buildingId),
    );
    const model3DUrl = await signedModelUrl(
      this.cache,
      this.modelStorage,
      input.buildingId,
      building.versionModelo3D,
    );

    return { building, floors, model3DUrl };
  }
}

export interface ListBuildingsOutput {
  buildings: Building[];
}

@Injectable()
export class ListBuildingsUseCase implements UseCase<
  void,
  ListBuildingsOutput
> {
  constructor(
    @Inject('BuildingRepository')
    private readonly buildingRepository: BuildingRepository,
    @Inject(CACHE_PORT) private readonly cache: CachePort,
  ) {}

  async execute(): Promise<ListBuildingsOutput> {
    const buildings = await getOrLoad(
      this.cache,
      'mapas:buildings:all',
      MAP_TTL_MS,
      () => this.buildingRepository.findAll(),
    );
    return { buildings };
  }
}

export interface GetFloorModelInput {
  floorId: FloorId;
}

export interface GetFloorModelOutput {
  floor: Floor;
  model3DUrl: string;
}

@Injectable()
export class GetFloorModelUseCase implements UseCase<
  GetFloorModelInput,
  GetFloorModelOutput
> {
  constructor(
    @Inject('FloorRepository')
    private readonly floorRepository: FloorRepository,
    @Inject('Model3DStorage')
    private readonly modelStorage: Model3DStorage,
    @Inject(CACHE_PORT) private readonly cache: CachePort,
  ) {}

  async execute(input: GetFloorModelInput): Promise<GetFloorModelOutput> {
    const floor = await getOrLoad(
      this.cache,
      `mapas:floor:${input.floorId}`,
      MAP_TTL_MS,
      () => this.floorRepository.findById(input.floorId),
    );
    if (!floor) {
      throw new NotFoundException('Floor not found');
    }

    const model3DUrl = await signedModelUrl(
      this.cache,
      this.modelStorage,
      floor.edificioId,
      floor.modelo3DVersion,
    );

    return { floor, model3DUrl };
  }
}
