import { Entity, ValueObject } from '../../../shared/kernel';

export type BuildingId = string & { readonly __brand: unique symbol };
export type FloorId = string & { readonly __brand: unique symbol };
export type ModelVersion = string & { readonly __brand: unique symbol };

export interface Building extends Entity<BuildingId> {
  nombre: string;
  codigo: string;
  geometria: GeoPolygon;
  pisos: FloorId[];
  versionModelo3D: ModelVersion;
}

export interface Floor extends Entity<FloorId> {
  edificioId: BuildingId;
  numero: number;
  nombre: string;
  modelo3DUrl: string;
  modelo3DVersion: ModelVersion;
  alturaMetros: number;
  pois: PoiId[];
}

export interface PoiId extends ValueObject {
  value: string;
}

export interface GeoPolygon {
  type: 'Polygon';
  coordinates: number[][][];
}

export interface BuildingRepository {
  findById(id: BuildingId): Promise<Building | null>;
  findAll(): Promise<Building[]>;
  findByCodigo(codigo: string): Promise<Building | null>;
}

export interface FloorRepository {
  findById(id: FloorId): Promise<Floor | null>;
  findByBuildingId(edificioId: BuildingId): Promise<Floor[]>;
}

export interface Model3DStorage {
  getSignedUrl(buildingId: BuildingId, version: ModelVersion): Promise<string>;
  uploadModel(buildingId: BuildingId, file: Buffer, version: ModelVersion): Promise<string>;
}