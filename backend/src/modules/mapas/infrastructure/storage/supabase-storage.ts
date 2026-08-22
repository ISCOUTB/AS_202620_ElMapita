import { Injectable } from '@nestjs/common';
import { getSupabaseClient } from '../../../../shared/supabase/client';
import { ConfigService } from '@nestjs/config';
import { BuildingId, ModelVersion, Model3DStorage } from '../../domain';

@Injectable()
export class SupabaseModel3DStorage implements Model3DStorage {
  private readonly BUCKET = 'modelos-3d';

  constructor(private readonly configService: ConfigService) {}

  private get client() {
    return getSupabaseClient(this.configService);
  }

  async getSignedUrl(buildingId: BuildingId, version: ModelVersion): Promise<string> {
    const path = `${buildingId}/${version}.glb`;
    
    const { data, error } = await this.client.storage
      .from(this.BUCKET)
      .createSignedUrl(path, 3600); // 1 hora

    if (error || !data) {
      throw new Error(`Failed to get signed URL for model: ${error?.message}`);
    }

    return data.signedUrl;
  }

  async uploadModel(buildingId: BuildingId, file: Buffer, version: ModelVersion): Promise<string> {
    const path = `${buildingId}/${version}.glb`;
    
    const { data, error } = await this.client.storage
      .from(this.BUCKET)
      .upload(path, file, {
        contentType: 'model/gltf-binary',
        upsert: true,
      });

    if (error || !data) {
      throw new Error(`Failed to upload model: ${error?.message}`);
    }

    return data.path;
  }
}