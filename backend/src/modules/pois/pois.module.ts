import { Module } from '@nestjs/common';
import { ConfigModule } from '../../shared/config/config.module';
import { PoisController } from './interfaces/pois.controller';
import { GetPoiUseCase, ListPoisByFloorUseCase, CreatePoiUseCase } from './application/use-cases';
import { SupabasePoiRepository } from './infrastructure/supabase-poi-repository';

@Module({
  imports: [ConfigModule],
  controllers: [PoisController],
  providers: [
    GetPoiUseCase,
    ListPoisByFloorUseCase,
    CreatePoiUseCase,
    {
      provide: 'PoiRepository',
      useClass: SupabasePoiRepository,
    },
  ],
  exports: [
    GetPoiUseCase,
    ListPoisByFloorUseCase,
    CreatePoiUseCase,
  ],
})
export class PoisModule {}