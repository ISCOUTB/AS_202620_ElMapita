import {
  Controller,
  Get,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { getSupabaseClient } from './shared/supabase/client';
import { ConfigService } from '@nestjs/config';

const SUPABASE_CHECK_TIMEOUT_MS = 4000;

@ApiTags('Health')
@Controller('health')
export class HealthController {
  private readonly logger = new Logger(HealthController.name);

  constructor(private readonly configService: ConfigService) {}

  @Get()
  @ApiOperation({ summary: 'Health check endpoint' })
  @ApiResponse({ status: 200, description: 'Service is healthy' })
  @ApiResponse({ status: 503, description: 'Service is unhealthy' })
  async check() {
    const receivedAt = Date.now();
    this.logger.log('health check: recibida petición');

    const checks = {
      status: 'ok',
      timestamp: new Date().toISOString(),
      checks: {
        supabase: 'unknown',
      },
    };

    const start = Date.now();
    try {
      const client = getSupabaseClient(this.configService);
      const query = client.from('edificios').select('id').limit(1);
      let timeoutId: NodeJS.Timeout;
      const timeout = new Promise<never>((_, reject) => {
        timeoutId = setTimeout(
          () => reject(new Error('supabase query timeout')),
          SUPABASE_CHECK_TIMEOUT_MS,
        );
      });

      const { error } = await Promise.race([query, timeout]).finally(() =>
        clearTimeout(timeoutId),
      );
      const elapsedMs = Date.now() - start;
      this.logger.log(
        `health check: consulta a Supabase resuelta en ${elapsedMs}ms (error=${!!error})`,
      );
      checks.checks.supabase = error ? 'degraded' : 'ok';
    } catch (err) {
      const elapsedMs = Date.now() - start;
      const reason = err instanceof Error ? err.message : 'unknown error';
      this.logger.warn(
        `health check: consulta a Supabase falló/expiró tras ${elapsedMs}ms (${reason})`,
      );
      checks.checks.supabase = 'down';
    }

    const isHealthy = checks.checks.supabase === 'ok';
    checks.status = isHealthy ? 'ok' : 'degraded';

    const totalMs = Date.now() - receivedAt;
    this.logger.log(
      `health check: respondiendo ${isHealthy ? 200 : 503} en ${totalMs}ms total`,
    );

    // El orquestador (Render) decide si manda tráfico según el código HTTP,
    // no según el cuerpo — un 200 con "degraded" adentro es un health check
    // que miente (ver S08: "apaguen la base de datos y miren qué devuelve").
    // El timeout explícito (SUPABASE_CHECK_TIMEOUT_MS) evita que este endpoint
    // se cuelgue indefinidamente sin importar la causa: siempre responde
    // rápido, aunque sea con 503 — eso es lo que un orquestador necesita.
    if (!isHealthy) {
      throw new ServiceUnavailableException(checks);
    }

    return checks;
  }
}
