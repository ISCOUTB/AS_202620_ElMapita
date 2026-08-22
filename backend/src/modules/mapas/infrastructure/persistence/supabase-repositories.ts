import { Injectable } from '@nestjs/common';
import { getSupabaseClient } from '../../../../shared/supabase/client';
import { ConfigService } from '@nestjs/config';
import { Building, BuildingId, Floor, FloorId, ModelVersion, BuildingRepository, FloorRepository, GeoPolygon } from '../../domain';

@Injectable()
export class SupabaseBuildingRepository implements BuildingRepository {
  constructor(private readonly configService: ConfigService) {}

  private get client() {
    return getSupabaseClient(this.configService);
  }

  async findById(id: BuildingId): Promise<Building | null> {
    const { data, error } = await this.client
      .from('edificios')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !data) return null;
    return this.mapToBuilding(data);
  }

  async findAll(): Promise<Building[]> {
    const { data, error } = await this.client
      .from('edificios')
      .select('*')
      .order('nombre');

    if (error || !data) return [];
    return data.map(this.mapToBuilding);
  }

  async findByCodigo(codigo: string): Promise<Building | null> {
    const { data, error } = await this.client
      .from('edificios')
      .select('*')
      .eq('codigo', codigo)
      .single();

    if (error || !data) return null;
    return this.mapToBuilding(data);
  }

  private mapToBuilding(row: any): Building {
    return {
      id: row.id as BuildingId,
      nombre: row.nombre,
      codigo: row.codigo,
      geometria: row.geometria as GeoPolygon,
      pisos: row.pisos as FloorId[],
      versionModelo3D: row.version_modelo_3d as ModelVersion,
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at),
    };
  }
}

@Injectable()
export class SupabaseFloorRepository implements FloorRepository {
  constructor(private readonly configService: ConfigService) {}

  private get client() {
    return getSupabaseClient(this.configService);
  }

  async findById(id: FloorId): Promise<Floor | null> {
    const { data, error } = await this.client
      .from('pisos')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !data) return null;
    return this.mapToFloor(data);
  }

  async findByBuildingId(edificioId: BuildingId): Promise<Floor[]> {
    const { data, error } = await this.client
      .from('pisos')
      .select('*')
      .eq('edificio_id', edificioId)
      .order('numero');

    if (error || !data) return [];
    return data.map(this.mapToFloor);
  }

  private mapToFloor(row: any): Floor {
    return {
      id: row.id as FloorId,
      edificioId: row.edificio_id as BuildingId,
      numero: row.numero,
      nombre: row.nombre,
      modelo3DUrl: row.modelo_3d_url,
      modelo3DVersion: row.modelo_3d_version as ModelVersion,
      alturaMetros: row.altura_metros,
      pois: row.pois as any[],
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at),
    };
  }
}