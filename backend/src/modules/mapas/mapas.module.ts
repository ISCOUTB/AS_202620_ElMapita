import { Module } from '@nestjs/common';
import { ConfigModule } from '../../shared/config/config.module';
import { MapasController } from './interfaces/mapas.controller';
import { GetBuildingUseCase, ListBuildingsUseCase, GetFloorModelUseCase } from './application/use-cases';
import { SupabaseBuildingRepository, SupabaseFloorRepository } from './infrastructure/persistence/supabase-repositories';
import { SupabaseModel3DStorage } from './infrastructure/storage/supabase-storage';

@Module({
  imports: [ConfigModule],
  controllers: [MapasController],
  providers: [
    GetBuildingUseCase,
    ListBuildingsUseCase,
    GetFloorModelUseCase,
    {
      provide: 'BuildingRepository',
      useClass: SupabaseBuildingRepository,
    },
    {
      provide: 'FloorRepository',
      useClass: SupabaseFloorRepository,
    },
    {
      provide: 'Model3DStorage',
      useClass: SupabaseModel3DStorage,
    },
  ],
  exports: [
    GetBuildingUseCase,
    ListBuildingsUseCase,
    GetFloorModelUseCase,
  ],
})
export class MapasModule {}