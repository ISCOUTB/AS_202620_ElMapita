import { UseCase } from '../../../shared/kernel';
import { Building, BuildingId, Floor, FloorId, ModelVersion, BuildingRepository, FloorRepository, Model3DStorage } from '../domain';

export interface GetBuildingInput {
  buildingId: BuildingId;
}

export interface GetBuildingOutput {
  building: Building;
  floors: Floor[];
  model3DUrl: string;
}

export class GetBuildingUseCase implements UseCase<GetBuildingInput, GetBuildingOutput> {
  constructor(
    private readonly buildingRepository: BuildingRepository,
    private readonly floorRepository: FloorRepository,
    private readonly modelStorage: Model3DStorage
  ) {}

  async execute(input: GetBuildingInput): Promise<GetBuildingOutput> {
    const building = await this.buildingRepository.findById(input.buildingId);
    if (!building) {
      throw new Error('Building not found');
    }

    const floors = await this.floorRepository.findByBuildingId(input.buildingId);
    const model3DUrl = await this.modelStorage.getSignedUrl(input.buildingId, building.versionModelo3D);

    return { building, floors, model3DUrl };
  }
}

export interface ListBuildingsOutput {
  buildings: Building[];
}

export class ListBuildingsUseCase implements UseCase<void, ListBuildingsOutput> {
  constructor(private readonly buildingRepository: BuildingRepository) {}

  async execute(): Promise<ListBuildingsOutput> {
    const buildings = await this.buildingRepository.findAll();
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

export class GetFloorModelUseCase implements UseCase<GetFloorModelInput, GetFloorModelOutput> {
  constructor(
    private readonly floorRepository: FloorRepository,
    private readonly modelStorage: Model3DStorage
  ) {}

  async execute(input: GetFloorModelInput): Promise<GetFloorModelOutput> {
    const floor = await this.floorRepository.findById(input.floorId);
    if (!floor) {
      throw new Error('Floor not found');
    }

    const model3DUrl = await this.modelStorage.getSignedUrl(floor.edificioId, floor.modelo3DVersion);

    return { floor, model3DUrl };
  }
}