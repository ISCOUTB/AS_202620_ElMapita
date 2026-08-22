import { UseCase } from '../../../shared/kernel';
import { Poi, PoiId, FloorId, PoiType, PoiRepository, PoiMetadatos, GeoPoint } from '../domain';

export interface GetPoiInput { poiId: PoiId; }
export interface GetPoiOutput { poi: Poi; }

export class GetPoiUseCase implements UseCase<GetPoiInput, GetPoiOutput> {
  constructor(private readonly poiRepository: PoiRepository) {}
  async execute(input: GetPoiInput): Promise<GetPoiOutput> {
    const poi = await this.poiRepository.findById(input.poiId);
    if (!poi) throw new Error('POI not found');
    return { poi };
  }
}

export interface ListPoisByFloorInput { floorId: FloorId; }
export interface ListPoisByFloorOutput { pois: Poi[]; }

export class ListPoisByFloorUseCase implements UseCase<ListPoisByFloorInput, ListPoisByFloorOutput> {
  constructor(private readonly poiRepository: PoiRepository) {}
  async execute(input: ListPoisByFloorInput): Promise<ListPoisByFloorOutput> {
    const pois = await this.poiRepository.findByFloorId(input.floorId);
    return { pois };
  }
}

export interface CreatePoiInput {
  pisoId: FloorId;
  tipo: PoiType;
  nombre: string;
  geometria: GeoPoint;
  metadatos: PoiMetadatos;
}
export interface CreatePoiOutput { poi: Poi; }

export class CreatePoiUseCase implements UseCase<CreatePoiInput, CreatePoiOutput> {
  constructor(private readonly poiRepository: PoiRepository) {}
  async execute(input: CreatePoiInput): Promise<CreatePoiOutput> {
    const poi: Poi = {
      id: crypto.randomUUID() as PoiId,
      ...input,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    const saved = await this.poiRepository.save(poi);
    return { poi: saved };
  }
}