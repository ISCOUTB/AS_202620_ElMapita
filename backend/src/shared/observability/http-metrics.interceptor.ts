import {
  CallHandler,
  ExecutionContext,
  HttpException,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { InjectMetric } from '@willsoto/nestjs-prometheus';
import type { Request, Response } from 'express';
import type { Histogram } from 'prom-client';
import { Observable, catchError, tap, throwError } from 'rxjs';

/**
 * Observa la duración de cada petición HTTP en un histograma Prometheus,
 * etiquetado por método/ruta/status. Cubre las 17 operaciones del contrato,
 * pero las que importan para EC-01 son GET /api/v1/map/buildings/{buildingId}
 * y GET /api/v1/map/floors/{floorId}/model (ver ADR-0003 y ADR-0004).
 *
 * El status de error se toma de la excepción (HttpException.getStatus()),
 * no de `response.statusCode`: en el camino de error, el filtro de
 * excepciones de Nest todavía no ha escrito el código real cuando este
 * interceptor corre, así que leer response.statusCode ahí siempre da 200.
 */
@Injectable()
export class HttpMetricsInterceptor implements NestInterceptor {
  constructor(
    @InjectMetric('http_request_duration_seconds')
    private readonly histogram: Histogram<'method' | 'route' | 'status_code'>,
  ) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') {
      return next.handle();
    }

    const request = context.switchToHttp().getRequest<Request>();
    const response = context.switchToHttp().getResponse<Response>();
    const start = process.hrtime.bigint();
    const route = this.resolveRoute(request);

    return next.handle().pipe(
      tap(() =>
        this.observe(start, route, request.method, response.statusCode),
      ),
      catchError((err: unknown) => {
        const statusCode = err instanceof HttpException ? err.getStatus() : 500;
        this.observe(start, route, request.method, statusCode);
        return throwError(() => err);
      }),
    );
  }

  private resolveRoute(request: Request): string {
    const routePath = (request as unknown as { route?: { path: string } }).route
      ?.path;
    return routePath ? `${request.baseUrl}${routePath}` : request.path;
  }

  private observe(
    start: bigint,
    route: string,
    method: string,
    statusCode: number,
  ): void {
    const durationSeconds = Number(process.hrtime.bigint() - start) / 1e9;
    this.histogram
      .labels(method, route, String(statusCode))
      .observe(durationSeconds);
  }
}
