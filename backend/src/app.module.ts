import { Module } from '@nestjs/common';
import { ConfigModule } from './shared/config/config.module';
import { LoggerModule } from './shared/observability/logger.module';
import { MetricsModule } from './shared/observability/metrics.module';
import { MapasModule } from './modules/mapas/mapas.module';
import { UbicacionModule } from './modules/ubicacion/ubicacion.module';
import { AuthModule } from './modules/auth/auth.module';
import { PoisModule } from './modules/pois/pois.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule,
    LoggerModule,
    MetricsModule,
    MapasModule,
    UbicacionModule,
    AuthModule,
    PoisModule,
  ],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}
