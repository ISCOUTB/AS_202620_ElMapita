import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { UseCase } from '../../../shared/kernel';
import { CACHE_PORT, type CachePort } from '../../../shared/cache/cache.port';
import { getOrLoad } from '../../../shared/cache/get-or-load';
import type {
  Poi,
  PoiId,
  FloorId,
  PoiType,
  PoiRepository,
  PoiMetadatos,
  GeoPoint,
} from '../domain';

// Más corto que el de mapas: los POIs sí se escriben vía API, y las demás
// instancias/ediciones externas se ven tras a lo sumo este TTL.
const POI_TTL_MS = 5 * 60 * 1000;

export interface GetPoiInput {
  poiId: PoiId;
}
export interface GetPoiOutput {
  poi: Poi;
}

@Injectable()
export class GetPoiUseCase implements UseCase<GetPoiInput, GetPoiOutput> {
  constructor(
    @Inject('PoiRepository') private readonly poiRepository: PoiRepository,
    @Inject(CACHE_PORT) private readonly cache: CachePort,
  ) {}
  async execute(input: GetPoiInput): Promise<GetPoiOutput> {
    const poi = await getOrLoad(
      this.cache,
      `pois:id:${input.poiId}`,
      POI_TTL_MS,
      () => this.poiRepository.findById(input.poiId),
    );
    if (!poi) throw new NotFoundException('POI not found');
    return { poi };
  }
}

export interface ListPoisByFloorInput {
  floorId: FloorId;
}
export interface ListPoisByFloorOutput {
  pois: Poi[];
}

@Injectable()
export class ListPoisByFloorUseCase implements UseCase<
  ListPoisByFloorInput,
  ListPoisByFloorOutput
> {
  constructor(
    @Inject('PoiRepository') private readonly poiRepository: PoiRepository,
    @Inject(CACHE_PORT) private readonly cache: CachePort,
  ) {}
  async execute(input: ListPoisByFloorInput): Promise<ListPoisByFloorOutput> {
    const pois = await getOrLoad(
      this.cache,
      `pois:floor:${input.floorId}`,
      POI_TTL_MS,
      () => this.poiRepository.findByFloorId(input.floorId),
    );
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
export interface CreatePoiOutput {
  poi: Poi;
}

@Injectable()
export class CreatePoiUseCase implements UseCase<
  CreatePoiInput,
  CreatePoiOutput
> {
  constructor(
    @Inject('PoiRepository') private readonly poiRepository: PoiRepository,
    @Inject(CACHE_PORT) private readonly cache: CachePort,
  ) {}
  async execute(input: CreatePoiInput): Promise<CreatePoiOutput> {
    const poi: Poi = {
      id: crypto.randomUUID() as PoiId,
      ...input,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    const saved = await this.poiRepository.save(poi);
    // Invalidación explícita tras escribir (read-your-writes): se borra, no se actualiza.
    await this.cache.del(`pois:floor:${saved.pisoId}`);
    await this.cache.del(`pois:id:${saved.id}`);
    return { poi: saved };
  }
}
