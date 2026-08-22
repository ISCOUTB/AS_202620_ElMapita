import { Entity, ValueObject } from '../../../shared/kernel';

export type PoiId = string & { readonly __brand: unique symbol };
export type FloorId = string & { readonly __brand: unique symbol };

export type PoiType = 'salon' | 'laboratorio' | 'bano' | 'cafeteria' | 'biblioteca' | 'escalera' | 'ascensor' | 'otro';

export interface Poi extends Entity<PoiId> {
  pisoId: FloorId;
  tipo: PoiType;
  nombre: string;
  geometria: GeoPoint;
  metadatos: PoiMetadatos;
}

export interface GeoPoint {
  type: 'Point';
  coordinates: [number, number];
}

export interface PoiMetadatos {
  capacidad?: number;
  horario?: string;
  accesibilidad?: boolean;
  descripcion?: string;
  [key: string]: unknown;
}

export interface PoiRepository {
  findById(id: PoiId): Promise<Poi | null>;
  findByFloorId(pisoId: FloorId): Promise<Poi[]>;
  findByTipo(tipo: PoiType): Promise<Poi[]>;
  save(poi: Poi): Promise<Poi>;
}

// Use Case DTOs
export interface GetPoiInput {
  poiId: PoiId;
}

export interface GetPoiOutput {
  poi: Poi;
}

export interface ListPoisByFloorInput {
  floorId: FloorId;
}

export interface ListPoisByFloorOutput {
  pois: Poi[];
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