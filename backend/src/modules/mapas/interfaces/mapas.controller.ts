import { Controller, Get, Param, Query, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { GetBuildingUseCase, GetBuildingInput, ListBuildingsUseCase, GetFloorModelUseCase, GetFloorModelInput } from '../application/use-cases';

@ApiTags('Mapas')
@Controller('api/v1/map')
export class MapasController {
  constructor(
    private readonly getBuildingUseCase: GetBuildingUseCase,
    private readonly listBuildingsUseCase: ListBuildingsUseCase,
    private readonly getFloorModelUseCase: GetFloorModelUseCase,
  ) {}

  @Get('buildings')
  @ApiOperation({ summary: 'Listar todos los edificios del campus' })
  @ApiResponse({ status: 200, description: 'Lista de edificios' })
  async listBuildings() {
    return this.listBuildingsUseCase.execute();
  }

  @Get('buildings/:buildingId')
  @ApiOperation({ summary: 'Obtener detalle de un edificio con sus pisos y modelo 3D' })
  @ApiParam({ name: 'buildingId', description: 'UUID del edificio' })
  @ApiResponse({ status: 200, description: 'Edificio con pisos y URL de modelo 3D' })
  @ApiResponse({ status: 404, description: 'Edificio no encontrado' })
  async getBuilding(@Param('buildingId', ParseUUIDPipe) buildingId: string) {
    return this.getBuildingUseCase.execute({ buildingId: buildingId as any });
  }

  @Get('floors/:floorId/model')
  @ApiOperation({ summary: 'Obtener URL firmada del modelo 3D de un piso' })
  @ApiParam({ name: 'floorId', description: 'UUID del piso' })
  @ApiResponse({ status: 200, description: 'Piso con URL de modelo 3D' })
  @ApiResponse({ status: 404, description: 'Piso no encontrado' })
  async getFloorModel(@Param('floorId', ParseUUIDPipe) floorId: string) {
    return this.getFloorModelUseCase.execute({ floorId: floorId as any });
  }
}