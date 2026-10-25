import {
  Inject,
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnModuleDestroy,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import {
  MESSAGE_BUS,
  type MessageBus,
} from '../../../shared/messaging/message-bus.port';
import { newMessage } from '../../../shared/messaging/message';
import type { PoiRepository } from '../domain';
import { PoiAuditConsumer } from './poi-audit.consumer';
import { POI_CREATED_V1, type PoiCreatedV1 } from './poi-events';

export interface ReconcileResult {
  checked: number;
  missing: number;
  published: number;
}

const RECONCILE_INTERVAL_MS = 10 * 60 * 1000;

/**
 * Cierra la brecha de "guardar y publicar no son atómicos" sin outbox
 * (ADR-0009): compara la fuente de verdad (`pois`) con lo que la auditoría ya
 * tiene y publica `poi.created.v1` solo para lo que falta.
 *
 * Cubre tres pérdidas con el mismo mecanismo:
 * - el proceso murió entre guardar y publicar;
 * - un reinicio vació la auditoría (que es en memoria) o la cola pendiente;
 * - el evento quedó en la cola de fallidos (se vuelve a publicar uno nuevo).
 *
 * Es seguro repetirla: el consumidor es idempotente por `poiId`, así que
 * publicar de más no duplica nada.
 */
@Injectable()
export class PoiAuditReconciler
  implements OnApplicationBootstrap, OnModuleDestroy
{
  private readonly logger = new Logger(PoiAuditReconciler.name);
  private timer?: NodeJS.Timeout;

  constructor(
    @Inject('PoiRepository') private readonly poiRepository: PoiRepository,
    @Inject(MESSAGE_BUS) private readonly bus: MessageBus,
    private readonly audit: PoiAuditConsumer,
  ) {}

  onApplicationBootstrap(): void {
    // En pruebas no se lanza solo (evita temporizadores y consultas a la BD).
    if (process.env.NODE_ENV === 'test') return;
    void this.runSafely();
    this.timer = setInterval(
      () => void this.runSafely(),
      RECONCILE_INTERVAL_MS,
    );
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }

  async reconcile(): Promise<ReconcileResult> {
    const pois = await this.poiRepository.findAll();
    const audited = new Set(this.audit.entries().map((e) => e.poiId));
    const missing = pois.filter((p) => !audited.has(p.id));

    // Un correlationId por corrida permite seguir en los logs todo lo que
    // esta reconciliación republicó.
    const correlationId = `reconcile-${randomUUID()}`;
    for (const poi of missing) {
      const payload: PoiCreatedV1 = {
        poiId: poi.id,
        pisoId: poi.pisoId,
        tipo: poi.tipo,
        nombre: poi.nombre,
      };
      await this.bus.publish(
        newMessage(POI_CREATED_V1, payload, correlationId),
      );
    }

    const result = {
      checked: pois.length,
      missing: missing.length,
      published: missing.length,
    };
    this.logger.log({ event: 'reconcile.done', correlationId, ...result });
    return result;
  }

  /** Una falla de la reconciliación se registra; nunca tumba la aplicación. */
  private async runSafely(): Promise<void> {
    try {
      await this.reconcile();
    } catch (e) {
      this.logger.error({ event: 'reconcile.failed', error: String(e) });
    }
  }
}
