import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { getSupabaseClient } from './shared/supabase/client';
import { ConfigService } from '@nestjs/config';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(private readonly configService: ConfigService) {}

  @Get()
  @ApiOperation({ summary: 'Health check endpoint' })
  @ApiResponse({ status: 200, description: 'Service is healthy' })
  @ApiResponse({ status: 503, description: 'Service is unhealthy' })
  async check() {
    const checks = {
      status: 'ok',
      timestamp: new Date().toISOString(),
      checks: {
        supabase: 'unknown',
      },
    };

    try {
      const client = getSupabaseClient(this.configService);
      const { error } = await client.from('edificios').select('id').limit(1);
      checks.checks.supabase = error ? 'degraded' : 'ok';
    } catch {
      checks.checks.supabase = 'down';
    }

    const isHealthy = checks.checks.supabase === 'ok';
    checks.status = isHealthy ? 'ok' : 'degraded';

    // El orquestador (Render) decide si manda tráfico según el código HTTP,
    // no según el cuerpo — un 200 con "degraded" adentro es un health check
    // que miente (ver S08: "apaguen la base de datos y miren qué devuelve").
    if (!isHealthy) {
      throw new ServiceUnavailableException(checks);
    }

    return checks;
  }
}
