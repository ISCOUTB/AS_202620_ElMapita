import { Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import {
  PrometheusModule,
  makeHistogramProvider,
} from '@willsoto/nestjs-prometheus';
import { HttpMetricsInterceptor } from './http-metrics.interceptor';

@Module({
  imports: [
    PrometheusModule.register({
      path: 'metrics',
      defaultMetrics: { enabled: true },
    }),
  ],
  providers: [
    makeHistogramProvider({
      name: 'http_request_duration_seconds',
      help: 'Duración de peticiones HTTP en segundos, por método/ruta/status. GET /api/v1/map/buildings/{buildingId} y /api/v1/map/floors/{floorId}/model son las que EC-01 mide (ver ADR-0003/0004).',
      labelNames: ['method', 'route', 'status_code'],
      buckets: [0.05, 0.1, 0.3, 0.5, 1, 2, 5],
    }),
    {
      provide: APP_INTERCEPTOR,
      useClass: HttpMetricsInterceptor,
    },
  ],
})
export class MetricsModule {}
