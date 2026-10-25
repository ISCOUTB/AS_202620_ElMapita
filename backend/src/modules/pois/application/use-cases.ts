import { Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { UseCase } from '../../../shared/kernel';
import { CACHE_PORT, type CachePort } from '../../../shared/cache/cache.port';
import { getOrLoad } from '../../../shared/cache/get-or-load';
import {
  MESSAGE_BUS,
  type MessageBus,
} from '../../../shared/messaging/message-bus.port';
import { newMessage } from '../../../shared/messaging/message';
import { POI_CREATED_V1, type PoiCreatedV1 } from './poi-events';
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
    @Inject(MESSAGE_BUS) private readonly bus: MessageBus,
  ) {}

  private readonly logger = new Logger(CreatePoiUseCase.name);

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
    await this.publishCreated(saved);
    return { poi: saved };
  }

  /**
   * Publicar es posterior al guardado y no forma parte de la transacción:
   * si el proceso muere entre ambos, el evento se pierde (ADR-0009, se
   * mitigaría con un outbox). Un fallo al publicar no debe fallar la petición.
   */
  private async publishCreated(poi: Poi): Promise<void> {
    const payload: PoiCreatedV1 = {
      poiId: poi.id,
      pisoId: poi.pisoId,
      tipo: poi.tipo,
      nombre: poi.nombre,
    };
    try {
      await this.bus.publish(newMessage(POI_CREATED_V1, payload));
    } catch (e) {
      this.logger.error(
        `No se pudo publicar ${POI_CREATED_V1} (poiId=${poi.id}): ${String(e)}`,
      );
    }
  }
}
