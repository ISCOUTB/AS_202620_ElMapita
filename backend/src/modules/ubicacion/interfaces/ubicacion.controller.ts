import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { GetCurrentLocationUseCase, SetManualLocationUseCase, RequestLocationPermissionUseCase } from '../application/use-cases';
import type { SetManualLocationInput } from '../domain';

@ApiTags('Ubicación')
@Controller('api/v1/location')
export class UbicacionController {
  constructor(
    private readonly getCurrentLocationUseCase: GetCurrentLocationUseCase,
    private readonly setManualLocationUseCase: SetManualLocationUseCase,
    private readonly requestLocationPermissionUseCase: RequestLocationPermissionUseCase,
  ) {}

  @Get('current')
  @ApiOperation({ summary: 'Obtener ubicación actual del usuario' })
  @ApiResponse({ status: 200, description: 'Ubicación con precisión y fuente' })
  async getCurrentLocation() {
    return this.getCurrentLocationUseCase.execute();
  }

  @Post('manual')
  @ApiOperation({ summary: 'Establecer ubicación manualmente' })
  @ApiResponse({ status: 200, description: 'Ubicación manual establecida' })
  async setManualLocation(@Body() input: SetManualLocationInput) {
    return this.setManualLocationUseCase.execute(input);
  }

  @Post('permission/request')
  @ApiOperation({ summary: 'Solicitar permiso de ubicación' })
  @ApiResponse({ status: 200, description: 'Resultado de la solicitud de permiso' })
  async requestPermission() {
    return this.requestLocationPermissionUseCase.execute();
  }
}