import { Module } from '@nestjs/common';
import { UbicacionController } from './interfaces/ubicacion.controller';
import { GetCurrentLocationUseCase, SetManualLocationUseCase, RequestLocationPermissionUseCase } from './application/use-cases';
import { PlatformLocationAdapter, FakeLocationProvider } from './infrastructure/platform/location-adapter';

@Module({
  controllers: [UbicacionController],
  providers: [
    GetCurrentLocationUseCase,
    SetManualLocationUseCase,
    RequestLocationPermissionUseCase,
    {
      provide: 'LocationProvider',
      useClass: process.env.NODE_ENV === 'test' ? FakeLocationProvider : PlatformLocationAdapter,
    },
  ],
  exports: [
    GetCurrentLocationUseCase,
    SetManualLocationUseCase,
    RequestLocationPermissionUseCase,
  ],
})
export class UbicacionModule {}