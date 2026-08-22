import { Injectable } from '@nestjs/common';
import { getSupabaseClient } from '../../../shared/supabase/client';
import { ConfigService } from '@nestjs/config';
import { Poi, PoiId, FloorId, PoiType, PoiRepository, GeoPoint, PoiMetadatos } from '../domain';

@Injectable()
export class SupabasePoiRepository implements PoiRepository {
  constructor(private readonly configService: ConfigService) {}

  private get client() {
    return getSupabaseClient(this.configService);
  }

  async findById(id: PoiId): Promise<Poi | null> {
    const { data, error } = await this.client
      .from('pois')
      .select('*')
      .eq('id', id)
      .single();
    if (error || !data) return null;
    return this.mapToPoi(data);
  }

  async findByFloorId(pisoId: FloorId): Promise<Poi[]> {
    const { data, error } = await this.client
      .from('pois')
      .select('*')
      .eq('piso_id', pisoId);
    if (error || !data) return [];
    return data.map(this.mapToPoi);
  }

  async findByTipo(tipo: PoiType): Promise<Poi[]> {
    const { data, error } = await this.client
      .from('pois')
      .select('*')
      .eq('tipo', tipo);
    if (error || !data) return [];
    return data.map(this.mapToPoi);
  }

  async save(poi: Poi): Promise<Poi> {
    const { data, error } = await this.client
      .from('pois')
      .upsert({
        id: poi.id,
        piso_id: poi.pisoId,
        tipo: poi.tipo,
        nombre: poi.nombre,
        geometria: poi.geometria,
        metadatos: poi.metadatos,
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();
    if (error || !data) throw new Error(`Failed to save POI: ${error?.message}`);
    return this.mapToPoi(data);
  }

  private mapToPoi(row: any): Poi {
    return {
      id: row.id as PoiId,
      pisoId: row.piso_id as FloorId,
      tipo: row.tipo as PoiType,
      nombre: row.nombre,
      geometria: row.geometria as GeoPoint,
      metadatos: row.metadatos as PoiMetadatos,
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at),
    };
  }
}