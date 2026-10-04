import { Module } from '@nestjs/common';
import { UbicacionController } from './interfaces/ubicacion.controller';
import { GetValidatedLocationUseCase } from './application/get-validated-location.use-case';
import {
  GetCurrentLocationUseCase,
  SetManualLocationUseCase,
  RequestLocationPermissionUseCase,
} from './application/use-cases';
import {
  PlatformLocationAdapter,
  FakeLocationProvider,
} from './infrastructure/platform/location-adapter';

@Module({
  controllers: [UbicacionController],
  providers: [
    GetCurrentLocationUseCase,
    SetManualLocationUseCase,
    RequestLocationPermissionUseCase,
    GetValidatedLocationUseCase,
    {
      provide: 'LocationProvider',
      useClass:
        process.env.NODE_ENV === 'test'
          ? FakeLocationProvider
          : PlatformLocationAdapter,
    },
  ],
  exports: [
    GetCurrentLocationUseCase,
    SetManualLocationUseCase,
    RequestLocationPermissionUseCase,
    GetValidatedLocationUseCase,
  ],
})
export class UbicacionModule {}
