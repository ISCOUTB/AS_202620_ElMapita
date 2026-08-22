import { Controller, Get, Post, Param, Body, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { GetPoiUseCase, ListPoisByFloorUseCase, CreatePoiUseCase } from '../application/use-cases';
import type { CreatePoiInput } from '../domain';

@ApiTags('POIs')
@Controller('api/v1/pois')
export class PoisController {
  constructor(
    private readonly getPoiUseCase: GetPoiUseCase,
    private readonly listPoisByFloorUseCase: ListPoisByFloorUseCase,
    private readonly createPoiUseCase: CreatePoiUseCase,
  ) {}

  @Get(':poiId')
  @ApiOperation({ summary: 'Obtener POI por ID' })
  @ApiParam({ name: 'poiId', description: 'UUID del POI' })
  @ApiResponse({ status: 200, description: 'POI encontrado' })
  @ApiResponse({ status: 404, description: 'POI no encontrado' })
  async getPoi(@Param('poiId', ParseUUIDPipe) poiId: string) {
    return this.getPoiUseCase.execute({ poiId: poiId as any });
  }

  @Get('floor/:floorId')
  @ApiOperation({ summary: 'Listar POIs de un piso' })
  @ApiParam({ name: 'floorId', description: 'UUID del piso' })
  @ApiResponse({ status: 200, description: 'Lista de POIs' })
  async listByFloor(@Param('floorId', ParseUUIDPipe) floorId: string) {
    return this.listPoisByFloorUseCase.execute({ floorId: floorId as any });
  }

  @Post()
  @ApiOperation({ summary: 'Crear nuevo POI (admin)' })
  @ApiResponse({ status: 201, description: 'POI creado' })
  @ApiResponse({ status: 400, description: 'Datos inválidos' })
  async create(@Body() input: CreatePoiInput) {
    return this.createPoiUseCase.execute(input);
  }
}