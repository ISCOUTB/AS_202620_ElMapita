import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  ParseUUIDPipe,
  UseGuards,
  Headers,
  Req,
  BadRequestException,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiBearerAuth,
  ApiHeader,
} from '@nestjs/swagger';
import { AuthGuard, Roles } from '../../auth/interfaces/auth.guard';
import {
  GetPoiUseCase,
  ListPoisByFloorUseCase,
  CreatePoiUseCase,
} from '../application/use-cases';
import type { Request } from 'express';
import type { User } from '../../auth/domain';
import { IDEMPOTENCY_KEY_MAX_LENGTH } from '../application/idempotency';
import type { CreatePoiInput, FloorId, PoiId } from '../domain';

@ApiTags('POIs')
@Controller('v1/pois')
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
    return this.getPoiUseCase.execute({ poiId: poiId as PoiId });
  }

  @Get('floor/:floorId')
  @ApiOperation({ summary: 'Listar POIs de un piso' })
  @ApiParam({ name: 'floorId', description: 'UUID del piso' })
  @ApiResponse({ status: 200, description: 'Lista de POIs' })
  async listByFloor(@Param('floorId', ParseUUIDPipe) floorId: string) {
    return this.listPoisByFloorUseCase.execute({ floorId: floorId as FloorId });
  }

  @Post()
  @UseGuards(AuthGuard)
  @Roles('admin_staff', 'admin_utb')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Crear nuevo POI (admin)' })
  @ApiResponse({ status: 201, description: 'POI creado' })
  @ApiResponse({ status: 400, description: 'Datos inválidos' })
  @ApiResponse({ status: 401, description: 'Token ausente o inválido' })
  @ApiResponse({ status: 403, description: 'No autorizado' })
  @ApiHeader({
    name: 'Idempotency-Key',
    required: false,
    description:
      'Opcional (máx. 128 caracteres). Reintentar con la misma llave no duplica el POI.',
  })
  @ApiResponse({
    status: 409,
    description: 'Idempotency-Key reutilizada con un cuerpo distinto',
  })
  async create(
    @Body() input: CreatePoiInput,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Req() req: Request & { user?: User },
  ) {
    if (idempotencyKey === undefined) {
      return this.createPoiUseCase.execute(input);
    }
    if (
      idempotencyKey.length === 0 ||
      idempotencyKey.length > IDEMPOTENCY_KEY_MAX_LENGTH
    ) {
      throw new BadRequestException(
        `Idempotency-Key debe tener entre 1 y ${IDEMPOTENCY_KEY_MAX_LENGTH} caracteres`,
      );
    }
    return this.createPoiUseCase.execute(input, {
      idempotencyKey,
      actorId: req.user?.id ?? '',
    });
  }
}
